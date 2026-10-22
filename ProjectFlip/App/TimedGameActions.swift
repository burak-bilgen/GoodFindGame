import Foundation

extension GameStore {
    private var actions: SimulationActions { SimulationActions(timing: timing) }

    private func transact(now: Date = .now, _ action: (GameSnapshot, Date) throws -> GameSnapshot) throws {
        if let period = competitionPeriod, !period.contains(now) { throw TradingError.unavailable }
        let resolver = EventResolver(timing: timing)
        let caughtUp = try resolver.resolve(snapshot, now: now, definitions: definitions)
        var next: GameSnapshot
        do { next = try action(caughtUp.state, caughtUp.clock.effectiveNow) }
        catch {
            if caughtUp.state != snapshot { try commit(caughtUp.state) }
            throw error
        }
        resolver.reconcile(&next)
        next = try resolver.resolve(next, now: now, definitions: definitions).state
        try commit(next)
    }

    func catchUp(now: Date = .now, showSummary: Bool = false) throws {
        if let period = competitionPeriod, !period.contains(now) { return }
        let result = try EventResolver(timing: timing).resolve(snapshot, now: now, definitions: definitions)
        var next = result.state
        if showSummary && result.clock.elapsed >= 30 {
            let known = Set(next.awayReport.map(\.id))
            next.awayReport += result.outcomes.filter { !known.contains($0.id) }
        }
        if next != snapshot { try commit(next) }
    }

    func processDueEvents(now: Date = .now) throws {
        let reading = try GameClock.read(now: now, lastKnownWallClock: snapshot.lastKnownWallClock, lastSimulationAt: snapshot.lastSimulationAt)
        guard reading.movedBackwards || snapshot.events.contains(where: { $0.status == .pending && $0.resolveAt <= reading.effectiveNow }) else { return }
        try catchUp(now: now)
    }

    func acknowledgeAwayReport() throws {
        var next = snapshot
        next.awayReport = []
        try commit(next)
    }

    func projectedDeadline(_ target: Date, now: Date = .now) -> Date? {
        do {
            let reading = try GameClock.read(now: now, lastKnownWallClock: snapshot.lastKnownWallClock, lastSimulationAt: snapshot.lastSimulationAt)
            return now.addingTimeInterval(max(0, target.timeIntervalSince(reading.effectiveNow)))
        } catch {
            return nil // UI displays time.unavailable; no speculative countdown is shown.
        }
    }

    func askIssues(listingID: ListingID) throws {
        try transact { try actions.question(listingID: listingID, state: $0, now: $1) }
    }
    func sendOffer(listingID: ListingID, amount: Money, modifier: OfferModifier) throws {
        try transact { try actions.offer(listingID: listingID, amount: amount, modifier: modifier, state: $0, now: $1) }
    }
    func acceptSellerCounter(listingID: ListingID) throws {
        try transact { state, _ in try actions.acceptCounter(listingID: listingID, state: state) }
    }
    func walkAway(listingID: ListingID) throws {
        try transact { state, _ in try actions.walkAway(listingID: listingID, state: state) }
    }
    func purchase(listingID: ListingID) throws {
        try transact { try actions.purchase(listingID: listingID, state: $0, now: $1) }
    }
    func inspect(itemID: ItemID, professionally: Bool) throws {
        try transact { try actions.inspect(itemID: itemID, professionally: professionally, state: $0, now: $1, definitions: definitions) }
    }
    func buyInspectionTools(for category: ItemCategory) throws {
        try transact { state, _ in try InspectionEngine().buyTools(for: category, state: state) }
    }
    func repair(itemID: ItemID, defect: Defect) throws {
        try transact { state, _ in try RepairEngine().repair(itemID: itemID, defect: defect, state: state, definitions: definitions) }
    }
    func publish(itemID: ItemID, askingPrice: Money) throws {
        try transact { try actions.publish(itemID: itemID, askingPrice: askingPrice, state: $0, definitions: definitions, now: $1) }
    }
    func findBuyer(listingID: ListingID) throws {
        try transact { try actions.findBuyer(listingID: listingID, state: $0, definitions: definitions, now: $1) }
    }
    func changePrice(listingID: ListingID, amount: Money) throws {
        try transact { try actions.changePrice(listingID: listingID, amount: amount, state: $0, definitions: definitions, now: $1) }
    }
    func acceptBuyer(listingID: ListingID) throws {
        try transact { state, now in
            guard !state.hasBuyerReply(for: listingID) else { throw TradingError.alreadyDone }
            return try BuyerEngine().accept(listingID: listingID, state: state, now: now)
        }
    }
    func rejectBuyer(listingID: ListingID) throws {
        try transact { state, now in
            guard !state.hasBuyerReply(for: listingID) else { throw TradingError.alreadyDone }
            let next = try BuyerEngine().reject(listingID: listingID, state: state)
            return try actions.findBuyer(listingID: listingID, state: next, definitions: definitions, now: now)
        }
    }
    func counterBuyer(listingID: ListingID, amount: Money) throws {
        try transact { state, now in
            guard !state.hasBuyerReply(for: listingID),
                  let listing = state.playerListings.first(where: { $0.id == listingID && $0.status == .active }),
                  let offer = listing.offers.last, [.pending, .countered].contains(offer.status) else { throw TradingError.closed }
            guard amount > .zero, amount.minorUnits <= GameBalanceConfig.current.maximumTransactionAmount.minorUnits else { throw TradingError.invalidAmount }
            var next = state
            for index in next.events.indices where next.events[index].status == .pending {
                if case .buyerOfferExpired(let id, let offerID) = next.events[index].payload, id == listingID, offerID == offer.id { next.events[index].status = .cancelled }
            }
            let pace = actions.timing(for: state)
            let seed = SeededRandom.seed(for: "counter-\(state.simulationID)-\(state.nextEventSequence)")
            let due = now.addingTimeInterval(pace.delay(in: pace.sellerReply, seed: seed))
            guard due < (listing.expiresAt ?? .distantFuture) else { throw TradingError.replyWindowTooShort }
            try next.enqueue(.buyerReply(listingID: listingID, offerID: offer.id, amount: amount, expectedAttempts: offer.counterAttempts), createdAt: now, resolveAt: due)
            return next
        }
    }

    func withdrawListing(listingID: ListingID) throws {
        try transact { state, _ in
            guard let index = state.playerListings.firstIndex(where: { $0.id == listingID && $0.status == .active }) else { throw TradingError.closed }
            var next = state
            next.playerListings[index].status = .cancelled
            for offer in next.playerListings[index].offers.indices where [.pending, .countered].contains(next.playerListings[index].offers[offer].status) { next.playerListings[index].offers[offer].status = .withdrawn }
            return next
        }
    }
}
