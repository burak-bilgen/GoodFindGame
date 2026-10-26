import Foundation

struct MarketFeedEngine {
    let timing: MarketFeedTiming
    static let targetCount = 10
    static let maximumBrowsingCount = 16

    func prepare(_ state: inout GameSnapshot, now: Date, definitions: [ItemDefinition]) throws {
        guard state.playerListings.contains(where: { $0.status == .sold }) else { return }
        if state.marketFeedStartedAt == nil { state.marketFeedStartedAt = now }
        try bookLifetimes(&state, now: now, definitions: definitions)
        if !state.events.contains(where: { $0.status == .pending && $0.payload == .marketRefresh }) {
            try state.enqueue(.marketRefresh, createdAt: now, resolveAt: now)
        }
    }

    private func bookLifetimes(_ state: inout GameSnapshot, now: Date, definitions: [ItemDefinition]) throws {
        for listing in state.market where listing.available && !state.marketListingStates.contains(where: { $0.id == listing.id }) {
            guard let definition = definitions.first(where: { $0.id == listing.item.definitionID }) else { throw TradingError.unavailable }
            let seed = SeededRandom.seed(for: "\(state.simulationID)-lifetime-\(listing.id.rawValue)")
            var random = SeededRandom(seed: seed)
            func delay(_ range: ClosedRange<TimeInterval>) -> TimeInterval {
                range.lowerBound + (range.upperBound - range.lowerBound) * Double(random.integer(in: 0...10_000)) / 10_000
            }
            let expires = now.addingTimeInterval(delay(timing.remainingLifetime))
            // Competitors react to public presentation, so they can also misjudge hidden faults.
            let publicItem = ItemInstance(id: listing.item.id, definitionID: definition.id, condition: listing.claimedCondition, hiddenDefects: [])
            let belief = try PricingEngine.fairValue(of: publicItem, definition: definition, marketBasisPoints: state.marketMultiplier(for: definition, at: now))
            let bargain = try belief.scaled(byBasisPoints: 8_500)
            let ordinary = try belief.scaled(byBasisPoints: 10_500)
            let chance = listing.askingPrice <= bargain ? 75 : (listing.askingPrice <= ordinary ? 45 : 15)
            let competitor = random.integer(in: 0...99) < chance ? random.integer(in: 0...9) : nil
            let purchaseAt = competitor == nil ? nil : now.addingTimeInterval(delay(timing.competitorDelay))
            let reducedPrice = try listing.askingPrice.scaled(byBasisPoints: Int64(random.integer(in: 8_800...9_500)))
            let dropAt = now.addingTimeInterval(delay(timing.priceDropDelay))
            state.marketListingStates.append(MarketListingState(id: listing.id, expiresAt: expires, competitorIdentityIndex: competitor,
                competitorPurchaseAt: purchaseAt, initialAskingPrice: listing.askingPrice, priceDropAt: dropAt, reducedPrice: reducedPrice))
            try state.enqueue(.listingExpired(listingID: listing.id), createdAt: now, resolveAt: expires)
            if let purchaseAt { try state.enqueue(.competitorPurchase(listingID: listing.id), createdAt: now, resolveAt: purchaseAt) }
            try state.enqueue(.sellerPriceDrop(listingID: listing.id), createdAt: now, resolveAt: dropAt)
        }
    }

    func replenish(_ state: inout GameSnapshot, now: Date, definitions: [ItemDefinition]) throws {
        let available = state.market.filter(\.available).count
        let refill = max(0, Self.targetCount - available)
        // Browsing must reveal new opportunities even if the player correctly
        // passes on bad stock. Admit one arrival per refresh with bounded shelf
        // space; never retire a watched listing or firm quote to manufacture room.
        // The initial prepare keeps its introductory stock, and offline catch-up
        // still replenishes only once rather than replaying hours of arrivals.
        let discovery = available < Self.maximumBrowsingCount && state.marketFeedStartedAt.map { now > $0 } == true ? 1 : 0
        let needed = max(refill, discovery)
        if needed > 0 {
            guard !definitions.isEmpty, state.generation < UInt64.max else { throw SaveError.invalidSave }
            state.generation += 1
            let accessible = definitions.filter { CareerEngine.canAccess($0, state: state) }
            let selected = MarketCatalog.liveFeed(from: accessible, count: needed, seed: state.generation,
                                                  requestedModels: ClientEngine.activeBrief(in: state)?.request.models ?? [])
            state.market += try ListingGenerator().generate(definitions: selected, seed: state.generation, now: now, market: state, starterFriendly: false, variedSellers: true)
            try bookLifetimes(&state, now: now, definitions: definitions)
        }
        try state.enqueue(.marketRefresh, createdAt: now, resolveAt: now.addingTimeInterval(timing.refresh))
    }

    static func holdUntil(listingID: ListingID, at date: Date, beforeSequence: UInt64 = .max, state: GameSnapshot) -> Date? {
        if let conversation = state.conversations.first(where: { $0.listingID == listingID && !$0.closed }),
           conversation.agreedPrice != nil || conversation.counterPrice != nil,
           let expiry = conversation.counterExpiresAt, expiry > date { return expiry }
        // Forecast only already-booked replies, without guessing a future player action.
        for event in state.events where event.status == .pending && (event.resolveAt < date || (event.resolveAt == date && event.sequence < beforeSequence)) {
            if case .sellerReply(let id, let reply, let expiresAt) = event.payload,
               id == listingID, reply.agreedPrice != nil || reply.counterPrice != nil, expiresAt > date,
               state.conversations.contains(where: { $0.listingID == id && !$0.closed && $0.pendingReplyEventID == event.id }) { return expiresAt }
        }
        return nil
    }

    static func remainsAvailable(listingID: ListingID, at date: Date, sequence: UInt64, state: GameSnapshot) -> Bool {
        guard state.market.contains(where: { $0.id == listingID && $0.available }) else { return false }
        for event in state.events where event.status == .pending {
            let target: ListingID
            switch event.payload {
            case .listingExpired(let id), .competitorPurchase(let id): target = id
            default: continue
            }
            guard target == listingID else { continue }
            let hold = holdUntil(listingID: listingID, at: event.resolveAt, beforeSequence: event.sequence, state: state)
            let closingAt = hold?.addingTimeInterval(1) ?? event.resolveAt
            let closingSequence = hold == nil ? event.sequence : UInt64.max
            if closingAt < date || (closingAt == date && closingSequence < sequence) { return false }
        }
        return true
    }

    static func close(_ id: ListingID, reason: MarketClosureReason, at now: Date, state: inout GameSnapshot) -> Bool {
        guard let listing = state.market.firstIndex(where: { $0.id == id && $0.available }),
              let lifecycle = state.marketListingStates.firstIndex(where: { $0.id == id }) else { return false }
        state.market[listing].available = false
        state.marketListingStates[lifecycle].closureReason = reason
        state.marketListingStates[lifecycle].closedAt = now
        if let conversation = state.conversations.firstIndex(where: { $0.listingID == id && !$0.closed }) {
            state.conversations[conversation].closed = true
            state.conversations[conversation].agreedPrice = nil
            state.conversations[conversation].counterPrice = nil
            state.conversations[conversation].counterExpiresAt = nil
            state.conversations[conversation].pendingReplyEventID = nil
            state.conversations[conversation].append(reason == .competitor ? "seller.listingTaken" : "seller.listingExpired")
        }
        return true
    }

    static func pruneArchive(_ state: inout GameSnapshot) {
        let acquired = Set(state.player.inventory.map(\.id) + state.shipments.map { $0.item.id } + state.playerListings.map(\.itemID))
        let conversations = Set(state.conversations.map(\.listingID))
        let closedAt = Dictionary(uniqueKeysWithValues: state.marketListingStates.compactMap { lifecycle in
            lifecycle.closedAt.map { (lifecycle.id, $0) }
        })
        let recent = Set(state.market.filter { !$0.available }.sorted {
            let left = closedAt[$0.id] ?? $0.createdAt, right = closedAt[$1.id] ?? $1.createdAt
            return left == right ? $0.id.rawValue < $1.id.rawValue : left < right
        }.suffix(40).map(\.id))
        state.market.removeAll { !$0.available && !recent.contains($0.id) && !state.watchedListingIDs.contains($0.id) && !conversations.contains($0.id) && !acquired.contains($0.item.id) }
        let kept = Set(state.market.map(\.id))
        state.marketListingStates.removeAll { !kept.contains($0.id) }
    }
}
