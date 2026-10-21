import Foundation

struct EventResolution {
    let state: GameSnapshot
    let clock: ClockReading
    let outcomes: [ResolvedEvent]
}

struct EventResolver {
    let timing: SimulationTiming
    init(timing: SimulationTiming = .current) { self.timing = timing }

    func resolve(_ state: GameSnapshot, now: Date, definitions: [ItemDefinition]) throws -> EventResolution {
        let clock = try GameClock.read(now: now, lastKnownWallClock: state.lastKnownWallClock, lastSimulationAt: state.lastSimulationAt)
        var next = state
        // Phase A saves could contain a firm quote without a timer. Give it one full,
        // persisted window on first catch-up, before allowing any market retirement.
        for index in next.conversations.indices where !next.conversations[index].closed && next.conversations[index].pendingReplyEventID == nil && next.conversations[index].counterExpiresAt == nil {
            if next.conversations[index].agreedPrice != nil || next.conversations[index].counterPrice != nil {
                let expiry = clock.effectiveNow.addingTimeInterval(timing.offerLifetime)
                next.conversations[index].counterExpiresAt = expiry
                try next.enqueue(.sellerOfferExpired(listingID: next.conversations[index].listingID, expiresAt: expiry), createdAt: clock.effectiveNow, resolveAt: expiry)
            }
        }
        try MarketTrendEngine().prepare(&next, now: clock.effectiveNow, definitions: definitions)
        if let feed = timing.marketFeed { try MarketFeedEngine(timing: feed).prepare(&next, now: clock.effectiveNow, definitions: definitions) }
        for index in next.playerListings.indices where next.playerListings[index].status == .active {
            if next.playerListings[index].expiresAt == nil {
                // Untimed legacy listings get a full new window, never a retroactive expiration.
                let heldUntil = next.events.filter { $0.status == .pending && $0.payload.targetID == next.playerListings[index].id.rawValue }.map(\.resolveAt).max() ?? clock.effectiveNow
                next.playerListings[index].expiresAt = max(clock.effectiveNow.addingTimeInterval(45 * 60), heldUntil)
            }
            let listing = next.playerListings[index]
            try ensureListingExpiry(listing, state: &next, now: clock.effectiveNow)
            if (listing.expiresAt ?? .distantPast) > clock.effectiveNow,
               !listing.offers.contains(where: { [.pending, .countered].contains($0.status) }) {
                try scheduleBuyer(listingID: listing.id, state: &next, definitions: definitions, now: clock.effectiveNow)
            }
        }
        var needsFeedRefresh = false
        var outcomes: [ResolvedEvent] = []
        var buyerArrivals = 0
        while let index = next.events.indices.filter({ next.events[$0].status == .pending && next.events[$0].resolveAt <= clock.effectiveNow }).min(by: {
            let left = next.events[$0], right = next.events[$1]
            return left.resolveAt == right.resolveAt ? left.sequence < right.sequence : left.resolveAt < right.resolveAt
        }) {
            let event = next.events[index]
            next.events[index].status = .completed
            if case .marketRefresh = event.payload { needsFeedRefresh = timing.marketFeed != nil; continue }
            if event.payload.generatesBuyerInterest {
                if buyerArrivals >= timing.buyerArrivalsPerCatchUp {
                    next.events[index].status = .cancelled
                    try scheduleBuyer(listingID: ListingID(event.payload.targetID), state: &next, definitions: definitions, now: clock.effectiveNow, minimumDelay: 1)
                    continue
                }
                buyerArrivals += 1
            }
            if let kind = try apply(event, to: &next, definitions: definitions) {
                let tracked = next.watchedListingIDs.contains(ListingID(event.payload.targetID)) || next.conversations.contains { $0.listingID.rawValue == event.payload.targetID }
                if ![.priceDrop, .listingClosed].contains(kind) || tracked {
                    outcomes.append(ResolvedEvent(id: event.id, kind: kind, targetID: outcomeTarget(event, state: next), occurredAt: event.resolveAt))
                }
            } else {
                if case .listingAttention(let id, _, _) = event.payload,
                   next.playerListings.contains(where: { $0.id == id && $0.status == .active }) {
                    // Successful silent attention updates are completed, not cancelled reports.
                } else { next.events[index].status = .cancelled }
            }
        }
        if needsFeedRefresh, let feed = timing.marketFeed {
            try MarketFeedEngine(timing: feed).replenish(&next, now: clock.effectiveNow, definitions: definitions)
        }
        reconcile(&next)
        MarketFeedEngine.pruneArchive(&next)
        next.lastKnownWallClock = clock.observedNow
        next.lastSimulationAt = clock.effectiveNow
        // Pending work is never pruned. Settled history is bounded; sequence IDs never reset in a save.
        let retained = Set(next.events.filter { $0.status != .pending }.suffix(200).map(\.id))
        next.events.removeAll { $0.status != .pending && !retained.contains($0.id) }
        return EventResolution(state: next, clock: clock, outcomes: outcomes)
    }

    func scheduleBuyer(listingID: ListingID, state: inout GameSnapshot, definitions: [ItemDefinition], now: Date, minimumDelay: TimeInterval = 0) throws {
        guard let listing = state.playerListings.first(where: { $0.id == listingID && $0.status == .active }),
              !listing.offers.contains(where: { [.pending, .countered].contains($0.status) }),
              !state.events.contains(where: { $0.status == .pending && $0.payload.generatesBuyerInterest && $0.payload.targetID == listingID.rawValue }) else { return }
        guard !state.hasBuyerReply(for: listingID), let item = state.player.inventory.first(where: { $0.id == listing.itemID }), let definition = definitions.first(where: { $0.id == item.definitionID }) else { return }
        try ensureListingExpiry(listing, state: &state, now: now)
        let end = listing.expiresAt ?? now.addingTimeInterval(45 * 60)
        guard now < end else { return }
        let seed = SeededRandom.seed(for: "\(state.simulationID)-\(state.nextEventSequence)-\(listingID.rawValue)")
        let attention = try ListingAttention(listing: listing, item: item, definition: definition, state: state, at: now, seed: seed)
        let introductory = state.playerListings.first?.id == listingID && listing.offers.isEmpty
        let delay = timing.delay(in: timing.buyerInterest, seed: seed) * (introductory ? 1 : attention.delayFactor)
        let due = now.addingTimeInterval(max(minimumDelay, delay))
        guard due < end else { return }
        // Two real persisted observations precede each possible offer. They also resolve offline.
        for stage in 1...2 {
            let views = stage == 1 ? attention.views / 2 : attention.views - attention.views / 2
            let favorites = stage == 1 ? 0 : min(views, attention.favorites)
            try state.enqueue(.listingAttention(listingID: listingID, views: views, favorites: favorites), createdAt: now, resolveAt: now.addingTimeInterval(max(0, due.timeIntervalSince(now)) * Double(stage) / 3))
        }
        var random = SeededRandom(seed: seed)
        let qualifies = introductory || random.integer(in: 0...99) < attention.offerChance
        let generated = qualifies ? try BuyerEngine().generateOffer(listingID: listingID, state: state, definitions: definitions, now: due) : state
        if let candidate = generated.playerListings.first(where: { $0.id == listingID }), candidate.offers.count > listing.offers.count,
           let offer = candidate.offers.last, let message = candidate.messages.last {
            try state.enqueue(.buyerOffer(listingID: listingID, expectedOfferCount: listing.offers.count, offer: offer, intent: message.intent, expiresAt: min(end, due.addingTimeInterval(timing.offerLifetime))), createdAt: now, resolveAt: due)
        } else {
            try state.enqueue(.buyerInterest(listingID: listingID), createdAt: now, resolveAt: due)
        }
    }

    private func ensureListingExpiry(_ listing: PlayerListing, state: inout GameSnapshot, now: Date) throws {
        guard let end = listing.expiresAt,
              !state.events.contains(where: { $0.status == .pending && $0.payload == .playerListingExpired(listingID: listing.id) }) else { return }
        try state.enqueue(.playerListingExpired(listingID: listing.id), createdAt: min(now, end), resolveAt: end)
    }

    func reconcile(_ state: inout GameSnapshot) {
        for index in state.marketListingStates.indices where state.marketListingStates[index].closureReason == nil {
            if state.market.contains(where: { $0.id == state.marketListingStates[index].id && !$0.available }) {
                state.marketListingStates[index].closureReason = .withdrawn
            }
        }
        for index in state.inspectionJobs.indices where state.inspectionJobs[index].status == .pending {
            if !state.player.inventory.contains(where: { $0.id == state.inspectionJobs[index].itemID }) { state.inspectionJobs[index].status = .cancelled }
        }
        for index in state.events.indices where state.events[index].status == .pending {
            let valid: Bool
            switch state.events[index].payload {
            case .marketRefresh: valid = state.marketFeedStartedAt != nil
            case .listingExpired(let id), .competitorPurchase(let id), .sellerPriceDrop(let id):
                valid = state.market.contains { $0.id == id && $0.available } && state.marketListingStates.contains { $0.id == id && $0.closureReason == nil }
            case .marketCycle(let index): valid = state.marketCalendar != nil && index > (state.lastMarketCycle ?? -1)
            case .marketTrendEnded(let id): valid = state.marketTrends.contains { $0.id == id }
            case .sellerReply(let id, _, _):
                valid = state.market.contains { $0.id == id && $0.available } && state.conversations.contains { $0.listingID == id && !$0.closed && $0.pendingReplyEventID == state.events[index].id }
            case .sellerOfferExpired(let id, let expiresAt):
                valid = state.market.contains { $0.id == id && $0.available } && state.conversations.contains { $0.listingID == id && !$0.closed && $0.counterExpiresAt == expiresAt }
            case .shipmentArrived(let id): valid = state.shipments.contains { $0.id == id && $0.status == .pending }
            case .inspectionCompleted(let id): valid = state.inspectionJobs.contains { $0.id == id && $0.status == .pending }
            case .buyerOffer(let id, let expected, _, _, _):
                valid = state.playerListings.contains { $0.id == id && $0.status == .active && $0.offers.count == expected && !$0.offers.contains(where: { [.pending, .countered].contains($0.status) }) }
            case .listingAttention(let id, _, _), .playerListingExpired(let id):
                valid = state.playerListings.contains { $0.id == id && $0.status == .active }
            case .buyerReply(let id, let offerID, _, let attempts):
                valid = state.playerListings.contains { $0.id == id && $0.status == .active && $0.offers.last.map { $0.id == offerID && [.pending, .countered].contains($0.status) && $0.counterAttempts == attempts } == true }
            case .buyerInterest(let id): valid = state.playerListings.contains { $0.id == id && $0.status == .active }
            case .buyerOfferExpired(let id, let offerID):
                valid = state.playerListings.contains { $0.id == id && $0.status == .active && $0.offers.contains(where: { $0.id == offerID && [.pending, .countered].contains($0.status) }) }
            }
            if !valid { state.events[index].status = .cancelled }
        }
        for index in state.conversations.indices {
            if let pendingID = state.conversations[index].pendingReplyEventID,
               !state.events.contains(where: { $0.id == pendingID && $0.status == .pending }) {
                state.conversations[index].pendingReplyEventID = nil
                state.conversations[index].counterExpiresAt = nil
                state.conversations[index].closed = true
                state.conversations[index].append("seller.replyUnavailable")
            }
        }
    }

    private func outcomeTarget(_ event: GameEvent, state: GameSnapshot) -> String {
        if case .marketCycle(let index) = event.payload, let calendar = state.marketCalendar {
            return "trend-\(calendar.seed)-\(index)"
        }
        return event.payload.targetID
    }

    private func apply(_ event: GameEvent, to state: inout GameSnapshot, definitions: [ItemDefinition]) throws -> ResolvedEventKind? {
        switch event.payload {
        case .marketRefresh: return nil // The outer loop refreshes once, after all fixed due work.
        case .listingExpired(let id), .competitorPurchase(let id):
            guard state.market.contains(where: { $0.id == id && $0.available }),
                  let lifecycle = state.marketListingStates.firstIndex(where: { $0.id == id }) else { return nil }
            if let hold = MarketFeedEngine.holdUntil(listingID: id, at: event.resolveAt, beforeSequence: event.sequence, state: state) {
                let deferred = hold.addingTimeInterval(1)
                try state.enqueue(event.payload, createdAt: event.resolveAt, resolveAt: deferred)
                if case .competitorPurchase = event.payload { state.marketListingStates[lifecycle].competitorPurchaseAt = deferred }
                else { state.marketListingStates[lifecycle].expiresAt = deferred }
                return nil
            }
            let reason: MarketClosureReason
            if case .competitorPurchase = event.payload { reason = .competitor } else { reason = .expired }
            return MarketFeedEngine.close(id, reason: reason, at: event.resolveAt, state: &state) ? .listingClosed : nil
        case .sellerPriceDrop(let id):
            guard let listing = state.market.firstIndex(where: { $0.id == id && $0.available }),
                  let lifecycle = state.marketListingStates.firstIndex(where: { $0.id == id && $0.priceDroppedAt == nil }),
                  let price = state.marketListingStates[lifecycle].reducedPrice,
                  price < state.market[listing].askingPrice,
                  MarketFeedEngine.holdUntil(listingID: id, at: event.resolveAt, beforeSequence: event.sequence, state: state) == nil else { return nil }
            state.market[listing].askingPrice = price
            state.market[listing].reservationPrice = min(price, state.market[listing].reservationPrice)
            state.marketListingStates[lifecycle].priceDroppedAt = event.resolveAt
            return .priceDrop
        case .marketCycle(let index):
            return try MarketTrendEngine().start(index: index, state: &state) ? .marketTrend : nil
        case .marketTrendEnded(let id):
            return state.marketTrends.contains { $0.id == id } ? .marketTrend : nil
        case .sellerReply(let id, var reply, let expiresAt):
            guard state.market.contains(where: { $0.id == id && $0.available }),
                  let index = state.conversations.firstIndex(where: { $0.listingID == id && !$0.closed && $0.pendingReplyEventID == event.id }) else { return nil }
            reply.pendingReplyEventID = nil
            if reply.agreedPrice != nil || reply.counterPrice != nil {
                reply.counterExpiresAt = expiresAt
                try state.enqueue(.sellerOfferExpired(listingID: id, expiresAt: expiresAt), createdAt: event.resolveAt, resolveAt: expiresAt)
            }
            state.conversations[index] = reply
            return .sellerReply
        case .sellerOfferExpired(let id, let expiresAt):
            guard let index = state.conversations.firstIndex(where: { $0.listingID == id && !$0.closed && $0.counterExpiresAt == expiresAt }), state.market.contains(where: { $0.id == id && $0.available }) else { return nil }
            state.conversations[index].closed = true
            state.conversations[index].agreedPrice = nil
            state.conversations[index].counterPrice = nil
            state.conversations[index].counterExpiresAt = nil
            state.conversations[index].append("seller.offerExpired")
            return .offerExpired
        case .shipmentArrived(let id):
            guard let index = state.shipments.firstIndex(where: { $0.id == id && $0.status == .pending }) else { return nil }
            let item = state.shipments[index].item
            state.shipments[index].status = .completed
            guard !state.player.inventory.contains(where: { $0.id == item.id }) else { return nil }
            state.player.inventory.append(item)
            return .shipment
        case .inspectionCompleted(let id):
            guard let index = state.inspectionJobs.firstIndex(where: { $0.id == id && $0.status == .pending }),
                  let item = state.player.inventory.firstIndex(where: { $0.id == state.inspectionJobs[index].itemID }) else { return nil }
            let category = definitions.first { $0.id == state.player.inventory[item].definitionID }?.category
            InspectionEngine().completeProfessional(itemID: state.player.inventory[item].id, category: category, state: &state)
            state.inspectionJobs[index].status = .completed
            return .inspection
        case .buyerOffer(let id, let expected, let offer, let intent, let expiresAt):
            guard let index = state.playerListings.firstIndex(where: { $0.id == id && $0.status == .active && $0.offers.count == expected }),
                  !state.playerListings[index].offers.contains(where: { [.pending, .countered].contains($0.status) }),
                  let item = state.player.inventory.first(where: { $0.id == state.playerListings[index].itemID }) else { return nil }
            state.playerListings[index].offers.append(offer)
            state.playerListings[index].itemSnapshot = item
            state.playerListings[index].views += 3
            state.playerListings[index].messages.append(DialogueMessage(id: "\(id.rawValue)-\(state.playerListings[index].messages.count)", intent: intent, fromPlayer: false, amount: offer.amount))
            try state.enqueue(.buyerOfferExpired(listingID: id, offerID: offer.id), createdAt: event.resolveAt, resolveAt: expiresAt)
            return .buyerOffer
        case .buyerOfferExpired(let id, let offerID):
            guard let index = state.playerListings.firstIndex(where: { $0.id == id && $0.status == .active }),
                  let offer = state.playerListings[index].offers.firstIndex(where: { $0.id == offerID && [.pending, .countered].contains($0.status) }) else { return nil }
            state.playerListings[index].offers[offer].status = .withdrawn
            state.playerListings[index].messages.append(DialogueMessage(id: "\(id.rawValue)-\(state.playerListings[index].messages.count)", intent: "buyer.expired", fromPlayer: false))
            try scheduleBuyer(listingID: id, state: &state, definitions: definitions, now: event.resolveAt)
            return .offerExpired
        case .listingAttention(let id, let views, let favorites):
            guard let index = state.playerListings.firstIndex(where: { $0.id == id && $0.status == .active }) else { return nil }
            state.playerListings[index].views = min(1_000_000_000, state.playerListings[index].views + max(0, views))
            state.playerListings[index].favorites = min(state.playerListings[index].views, state.playerListings[index].favorites + max(0, favorites))
            return nil
        case .playerListingExpired(let id):
            guard let index = state.playerListings.firstIndex(where: { $0.id == id && $0.status == .active }) else { return nil }
            state.playerListings[index].status = .expired
            for offer in state.playerListings[index].offers.indices where [.pending, .countered].contains(state.playerListings[index].offers[offer].status) {
                state.playerListings[index].offers[offer].status = .withdrawn
            }
            state.playerListings[index].messages.append(DialogueMessage(id: "\(id.rawValue)-expired", intent: "selling.expired", fromPlayer: false))
            return .saleClosed
        case .buyerReply(let id, let offerID, let amount, let attempts):
            guard let listing = state.playerListings.first(where: { $0.id == id && $0.status == .active }), let offer = listing.offers.last,
                  offer.id == offerID, [.pending, .countered].contains(offer.status), offer.counterAttempts == attempts else { return nil }
            state = try BuyerEngine().counter(listingID: id, amount: amount, state: state, now: event.resolveAt)
            if let reply = state.playerListings.first(where: { $0.id == id && $0.status == .active })?.offers.last, [.pending, .countered].contains(reply.status) {
                let end = min(listing.expiresAt ?? .distantFuture, event.resolveAt.addingTimeInterval(timing.offerLifetime))
                try state.enqueue(.buyerOfferExpired(listingID: id, offerID: offerID), createdAt: event.resolveAt, resolveAt: end)
            } else { try scheduleBuyer(listingID: id, state: &state, definitions: definitions, now: event.resolveAt) }
            return .buyerOffer
        case .buyerInterest(let id):
            guard state.playerListings.contains(where: { $0.id == id && $0.status == .active }) else { return nil }
            try scheduleBuyer(listingID: id, state: &state, definitions: definitions, now: event.resolveAt, minimumDelay: 1)
            return nil
        }
    }
}
