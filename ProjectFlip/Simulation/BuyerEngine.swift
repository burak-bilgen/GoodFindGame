import Foundation

struct BuyerEngine {
    func generateOffer(listingID: ListingID, state: GameSnapshot, definitions: [ItemDefinition], now: Date? = nil) throws -> GameSnapshot {
        let index = try activeIndex(listingID, in: state)
        let listing = state.playerListings[index]
        guard !listing.offers.contains(where: { $0.status == .pending || $0.status == .countered }) else { throw TradingError.alreadyDone }
        guard let item = state.player.inventory.first(where: { $0.id == listing.itemID }), let definition = definitions.first(where: { $0.id == item.definitionID }) else { throw TradingError.unavailable }
        let fair = try PricingEngine.fairValue(of: item, definition: definition, marketBasisPoints: state.marketMultiplier(for: definition, at: now))
        // Implausible prices attract no buyer. Price revision can restore interest.
        guard listing.askingPrice <= (try fair.scaled(byBasisPoints: 25_000)) else { return state }
        let offset = state.playerListings.first?.id == listing.id ? 0 : Int(SeededRandom.seed(for: item.id.rawValue) % UInt64(BuyerArchetype.allCases.count))
        let archetype = BuyerArchetype.allCases[(listing.offers.count + offset) % BuyerArchetype.allCases.count]
        let variant = (Int(SeededRandom.seed(for: item.id.rawValue) % 2) + listing.offers.count) % 2
        let reputationFactor = Int64(10_000 + (state.player.reputation - 50) * 10)
        let budget = try fair.scaled(byBasisPoints: archetype.valueBasisPoints).scaled(byBasisPoints: reputationFactor)
        let proposed = min(try listing.askingPrice.scaled(byBasisPoints: 9_500), budget)
        var next = state
        next.playerListings[index].offers.append(BuyerOffer(id: OfferID("\(listing.id.rawValue)-buyer-\(listing.offers.count)"), archetype: archetype, identityIndex: (listing.offers.count + 3) % 10, willingness: budget, amount: proposed))
        next.playerListings[index].itemSnapshot = item
        next.playerListings[index].messages.append(DialogueMessage(id: "\(listing.id.rawValue)-\(listing.messages.count)", intent: "buyer.offer.\(variant)", fromPlayer: false, amount: proposed))
        next.playerListings[index].views += 3
        return next
    }

    func accept(listingID: ListingID, state: GameSnapshot, now: Date) throws -> GameSnapshot {
        let index = try activeIndex(listingID, in: state)
        guard let offer = state.playerListings[index].offers.last, offer.status == .pending || offer.status == .countered else { throw TradingError.closed }
        return try settle(index: index, amount: offer.amount, state: state, now: now)
    }

    func reject(listingID: ListingID, state: GameSnapshot) throws -> GameSnapshot {
        let index = try activeIndex(listingID, in: state)
        guard let last = state.playerListings[index].offers.indices.last,
              [.pending, .countered].contains(state.playerListings[index].offers[last].status) else { throw TradingError.closed }
        var next = state
        next.playerListings[index].offers[last].status = .rejected
        next.playerListings[index].messages.append(DialogueMessage(id: "\(listingID.rawValue)-\(next.playerListings[index].messages.count)", intent: "player.rejectBuyer", fromPlayer: true))
        return next
    }

    func counter(listingID: ListingID, amount: Money, state: GameSnapshot, now: Date) throws -> GameSnapshot {
        guard amount > .zero, amount.minorUnits <= GameBalanceConfig.current.maximumTransactionAmount.minorUnits else { throw TradingError.invalidAmount }
        let index = try activeIndex(listingID, in: state)
        guard let offerIndex = state.playerListings[index].offers.indices.last,
              [.pending, .countered].contains(state.playerListings[index].offers[offerIndex].status) else { throw TradingError.closed }
        let offer = state.playerListings[index].offers[offerIndex]
        if amount <= offer.willingness { return try settle(index: index, amount: amount, state: state, now: now) }
        var next = state
        let maximumCounter = try offer.willingness.scaled(byBasisPoints: 12_000)
        let withdraw = offer.counterAttempts >= 1 || amount > maximumCounter
        next.playerListings[index].offers[offerIndex].status = withdraw ? .withdrawn : .countered
        next.playerListings[index].offers[offerIndex].counterAttempts += 1
        next.playerListings[index].offers[offerIndex].amount = offer.willingness
        next.playerListings[index].messages.append(DialogueMessage(id: "\(listingID.rawValue)-\(next.playerListings[index].messages.count)", intent: withdraw ? "buyer.withdraw" : "buyer.counter", fromPlayer: false, amount: withdraw ? nil : offer.willingness))
        return next
    }

    func changePrice(listingID: ListingID, amount: Money, state: GameSnapshot) throws -> GameSnapshot {
        guard amount > .zero, amount.minorUnits <= GameBalanceConfig.current.maximumTransactionAmount.minorUnits else { throw TradingError.invalidAmount }
        let index = try activeIndex(listingID, in: state)
        var next = state
        next.playerListings[index].askingPrice = amount
        for offerIndex in next.playerListings[index].offers.indices where [.pending, .countered].contains(next.playerListings[index].offers[offerIndex].status) {
            next.playerListings[index].offers[offerIndex].status = .withdrawn
        }
        return next
    }

    private func activeIndex(_ id: ListingID, in state: GameSnapshot) throws -> Int {
        guard let index = state.playerListings.firstIndex(where: { $0.id == id }), state.playerListings[index].status == .active else { throw TradingError.closed }
        return index
    }

    private func settle(index: Int, amount: Money, state: GameSnapshot, now: Date) throws -> GameSnapshot {
        let listing = state.playerListings[index]
        guard let itemIndex = state.player.inventory.firstIndex(where: { $0.id == listing.itemID }), let offerIndex = listing.offers.indices.last else { throw TradingError.unavailable }
        var next = state
        next.player.cash = try state.player.cash.adding(amount)
        next.playerListings[index].itemSnapshot = state.player.inventory[itemIndex]
        next.playerListings[index].soldPrice = amount
        next.playerListings[index].soldAt = now
        next.playerListings[index].status = .sold
        next.playerListings[index].offers[offerIndex].status = .accepted
        next.playerListings[index].offers[offerIndex].amount = amount
        next.playerListings[index].messages.append(DialogueMessage(id: "\(listing.id.rawValue)-\(listing.messages.count)", intent: "buyer.accepted", fromPlayer: false, amount: amount))
        next.player.inventory.remove(at: itemIndex)
        return next
    }
}
