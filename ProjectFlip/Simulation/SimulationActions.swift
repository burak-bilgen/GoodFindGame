import Foundation

struct SimulationActions {
    let timing: SimulationTiming

    func offer(listingID: ListingID, amount: Money, modifier: OfferModifier, state: GameSnapshot, now: Date) throws -> GameSnapshot {
        let listing = try listing(listingID, in: state)
        let current = conversation(listing, in: state)
        guard current.pendingReplyEventID == nil else { throw TradingError.alreadyDone }
        let reply = try NegotiationEngine().offer(amount, modifier: modifier, listing: listing, current: current, reputation: state.player.reputation)
        return try bookReply(reply, current: current, state: state, now: now, seller: listing.seller)
    }

    func question(listingID: ListingID, state: GameSnapshot, now: Date) throws -> GameSnapshot {
        let listing = try listing(listingID, in: state)
        let current = conversation(listing, in: state)
        guard current.pendingReplyEventID == nil else { throw TradingError.alreadyDone }
        return try bookReply(NegotiationEngine().askAboutIssues(listing: listing, current: current), current: current, state: state, now: now, seller: listing.seller)
    }

    private func stateDefinition(_ id: String) -> ItemDefinition? { try? SeedContent.load().items.first { $0.id == id } }

    func purchase(listingID: ListingID, state: GameSnapshot, now: Date) throws -> GameSnapshot {
        guard state.player.inventory.count + state.shipments.filter({ $0.status == .pending }).count < state.player.inventoryCapacity else { throw TradingError.inventoryFull }
        let listing = try listing(listingID, in: state)
        guard let definition = stateDefinition(listing.item.definitionID), (CareerEngine.canAccess(definition, state: state) || state.career.legacyAgreements?.contains(listingID) == true) else { throw TradingError.marketLocked }
        var next = try PurchaseEngine().buy(listingID: listingID, state: state, now: now)
        guard let item = next.player.inventory.first(where: { $0.id == listing.item.id }) else { throw TradingError.unavailable }
        next.player.inventory.removeAll { $0.id == item.id }
        let delivery = timing(for: state).shipping
        let spread = state.playerListings.contains { $0.status == .sold } ? 0.6 + Double(SeededRandom.seed(for: "delivery-" + item.id.rawValue) % 81) / 100 : 1
        let due = now.addingTimeInterval(delivery * spread)
        let shipment = Shipment(id: "shipment-\(item.id.rawValue)", item: item, arrivesAt: due)
        next.shipments.append(shipment)
        try next.enqueue(.shipmentArrived(shipmentID: shipment.id), createdAt: now, resolveAt: due)
        return next
    }

    func inspect(itemID: ItemID, professionally: Bool, state: GameSnapshot, now: Date, definitions: [ItemDefinition]) throws -> GameSnapshot {
        guard let item = state.player.inventory.first(where: { $0.id == itemID }),
              let category = definitions.first(where: { $0.id == item.definitionID })?.category else { throw TradingError.unavailable }
        if !professionally { return try InspectionEngine().inspect(itemID: itemID, professionally: false, state: state, category: category) }
        var next = try InspectionEngine().chargeProfessional(itemID: itemID, state: state)
        let due = now.addingTimeInterval(timing(for: state).inspection)
        let job = InspectionJob(id: "inspection-\(itemID.rawValue)", itemID: itemID, completesAt: due, cost: InspectionEngine().professionalCost)
        next.inspectionJobs.append(job)
        try next.enqueue(.inspectionCompleted(jobID: job.id), createdAt: now, resolveAt: due)
        return next
    }

    func publish(itemID: ItemID, askingPrice: Money, state: GameSnapshot, definitions: [ItemDefinition], now: Date) throws -> GameSnapshot {
        var next = try ResaleEngine().create(itemID: itemID, askingPrice: askingPrice, state: state, definitions: definitions, now: now)
        guard let listing = next.playerListings.last else { throw TradingError.unavailable }
        try EventResolver(timing: timing(for: state)).scheduleBuyer(listingID: listing.id, state: &next, definitions: definitions, now: now)
        return next
    }

    func findBuyer(listingID: ListingID, state: GameSnapshot, definitions: [ItemDefinition], now: Date) throws -> GameSnapshot {
        var next = state
        try EventResolver(timing: timing(for: state)).scheduleBuyer(listingID: listingID, state: &next, definitions: definitions, now: now)
        return next
    }

    func changePrice(listingID: ListingID, amount: Money, state: GameSnapshot, definitions: [ItemDefinition], now: Date) throws -> GameSnapshot {
        var next = try BuyerEngine().changePrice(listingID: listingID, amount: amount, state: state)
        for index in next.events.indices where next.events[index].status == .pending && next.events[index].payload.targetID == listingID.rawValue {
            next.events[index].status = .cancelled
        }
        return try findBuyer(listingID: listingID, state: next, definitions: definitions, now: now)
    }

    func acceptCounter(listingID: ListingID, state: GameSnapshot) throws -> GameSnapshot {
        let listing = try listing(listingID, in: state)
        var current = conversation(listing, in: state)
        guard !current.closed, current.pendingReplyEventID == nil, let price = current.counterPrice else { throw TradingError.closed }
        current.agreedPrice = price
        current.counterPrice = nil
        current.append("player.accept", player: true, amount: price)
        return upserting(current, in: state)
    }

    func walkAway(listingID: ListingID, state: GameSnapshot) throws -> GameSnapshot {
        let listing = try listing(listingID, in: state)
        var current = conversation(listing, in: state)
        current.closed = true
        current.agreedPrice = nil
        current.counterPrice = nil
        current.counterExpiresAt = nil
        current.pendingReplyEventID = nil
        current.append("player.walkAway", player: true)
        return upserting(current, in: state)
    }

    func timing(for state: GameSnapshot) -> SimulationTiming {
        state.playerListings.contains { $0.status == .sold } ? timing : timing.firstTrade
    }

    private func bookReply(_ reply: NegotiationState, current: NegotiationState, state: GameSnapshot, now: Date, seller: SellerProfile) throws -> GameSnapshot {
        var next = state
        let timing = timing(for: state)
        let seed = SeededRandom.seed(for: "\(state.simulationID)-\(state.nextEventSequence)-seller")
        let urgency = state.playerListings.contains { $0.status == .sold } ? max(0.35, 1.25 - Double(seller.urgency) / 125) : 1
        let due = now.addingTimeInterval(timing.delay(in: timing.sellerReply, seed: seed) * urgency)
        let event = try next.enqueue(.sellerReply(listingID: reply.listingID, reply: reply, expiresAt: due.addingTimeInterval(timing.offerLifetime)), createdAt: now, resolveAt: due)
        var pending = current
        pending.pendingReplyEventID = event.id
        pending.counterExpiresAt = nil
        pending.counterPrice = nil
        pending.agreedPrice = nil
        pending.askedAboutIssues = reply.askedAboutIssues
        pending.messages += reply.messages.dropFirst(current.messages.count).prefix { $0.fromPlayer }
        if reply.offers.count > current.offers.count, var offer = reply.offers.last {
            offer.status = .pending
            pending.offers.append(offer)
        }
        return upserting(pending, in: next)
    }

    private func listing(_ id: ListingID, in state: GameSnapshot) throws -> MarketplaceListing {
        guard let listing = state.market.first(where: { $0.id == id && $0.available }) else { throw TradingError.unavailable }
        return listing
    }

    private func conversation(_ listing: MarketplaceListing, in state: GameSnapshot) -> NegotiationState {
        state.conversations.first { $0.listingID == listing.id } ?? NegotiationState(listingID: listing.id, patience: listing.seller.patience)
    }

    private func upserting(_ conversation: NegotiationState, in state: GameSnapshot) -> GameSnapshot {
        var next = state
        if let index = next.conversations.firstIndex(where: { $0.id == conversation.id }) { next.conversations[index] = conversation }
        else { next.conversations.append(conversation) }
        return next
    }
}
