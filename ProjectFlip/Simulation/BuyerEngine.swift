import Foundation

enum BuyerCounterDecision: Equatable {
    case accept, counter(Money), withdraw
}

struct BuyerEngine {
    func generateOffer(listingID: ListingID, state: GameSnapshot, definitions: [ItemDefinition], now: Date? = nil) throws -> GameSnapshot {
        let index = try activeIndex(listingID, in: state)
        let listing = state.playerListings[index]
        guard !listing.offers.contains(where: { $0.status == .pending || $0.status == .countered }) else { throw TradingError.alreadyDone }
        guard let item = state.player.inventory.first(where: { $0.id == listing.itemID }), let definition = definitions.first(where: { $0.id == item.definitionID }) else { throw TradingError.unavailable }
        let fair = try PricingEngine.fairValue(of: item, definition: definition, marketBasisPoints: state.marketMultiplier(for: definition, at: now))
        // Implausible prices attract no buyer. Price revision can restore interest.
        guard listing.askingPrice <= (try fair.scaled(byBasisPoints: 25_000)) else { return state }
        let introduction = state.playerListings.first?.id == listing.id && listing.offers.isEmpty
        var random = SeededRandom(seed: SeededRandom.seed(for: "buyer-\(state.simulationID)-\(listing.id.rawValue)-\(listing.offers.count)-\(state.nextEventSequence)"))
        let archetype = introduction ? BuyerArchetype.cautious : BuyerArchetype.allCases[random.integer(in: 0...(BuyerArchetype.allCases.count - 1))]
        let reputationFactor = Int64(10_000)
        let premium: Int64 = archetype == .collector && item.condition >= 90 ? 1_100 : 0
        let variation = introduction ? 0 : Int64(random.integer(in: -500...900))
        let budget = try fair.scaled(byBasisPoints: archetype.valueBasisPoints + variation + premium).scaled(byBasisPoints: reputationFactor)
        let opening: ClosedRange<Int> = switch archetype {
        case .lowballer: 5_000...7_000
        case .bargainHunter: 7_000...8_500
        case .reseller: 7_800...9_200
        case .cautious: 9_000...9_700
        case .impatient: 9_700...10_300
        case .collector: 9_300...10_300
        }
        let proposed = min(try listing.askingPrice.scaled(byBasisPoints: introduction ? 9_500 : Int64(random.integer(in: opening))), budget)
        var next = state
        next.playerListings[index].offers.append(BuyerOffer(id: OfferID("\(listing.id.rawValue)-buyer-\(listing.offers.count)"), archetype: archetype, identityIndex: (listing.offers.count + 3) % 10, willingness: budget, amount: proposed))
        next.playerListings[index].itemSnapshot = item
        next.playerListings[index].messages.append(DialogueMessage(id: "\(listing.id.rawValue)-\(listing.messages.count)", intent: "buyer.offer.\(archetype.rawValue)", fromPlayer: false, amount: proposed))
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
        let decision = try counterDecision(listingID: listingID, amount: amount, state: state)
        if decision == .accept { return try settle(index: index, amount: amount, state: state, now: now) }
        var next = state
        let revised: Money? = if case .counter(let value) = decision { value } else { nil }
        next.playerListings[index].offers[offerIndex].status = revised == nil ? .withdrawn : .countered
        next.playerListings[index].offers[offerIndex].counterAttempts += 1
        // A withdrawn buyer never exposes their unused private budget.
        if let revised { next.playerListings[index].offers[offerIndex].amount = revised }
        let intent = revised == nil ? "buyer.withdraw" : revised == state.playerListings[index].offers[offerIndex].amount ? "buyer.hold" : "buyer.counter"
        next.playerListings[index].messages.append(DialogueMessage(id: "\(listingID.rawValue)-\(next.playerListings[index].messages.count)", intent: intent, fromPlayer: false, amount: revised))
        return next
    }

    /// The persisted identity/attempt fixes the response. Reloading or offline
    /// catch-up cannot reroll it; notifications use this same decision.
    func counterDecision(listingID: ListingID, amount: Money, state: GameSnapshot) throws -> BuyerCounterDecision {
        guard amount > .zero, amount.minorUnits <= GameBalanceConfig.current.maximumTransactionAmount.minorUnits else { throw TradingError.invalidAmount }
        let index = try activeIndex(listingID, in: state)
        let listing = state.playerListings[index]
        guard let offer = listing.offers.last, [.pending, .countered].contains(offer.status) else { throw TradingError.closed }
        // Taking an already-held price is always safe. First-trade teaching keeps
        // its original approachable buyer; subsequent buyers defend their offer.
        if amount <= offer.amount { return .accept }
        let introduction = state.playerListings.first?.id == listingID && listing.offers.count == 1 && offer.counterAttempts == 0
        if introduction && amount <= offer.willingness { return .accept }
        // The first response can be firm without arbitrarily ending the deal.
        // After that response the UI calls it final; pushing again can end talks.
        let overreach = max(try listing.askingPrice.scaled(byBasisPoints: 12_500), try offer.amount.scaled(byBasisPoints: 15_000))
        if amount > overreach || offer.counterAttempts >= 1 { return .withdraw }
        var random = SeededRandom(seed: SeededRandom.seed(for: "buyer-reply-\(state.simulationID)-\(listingID.rawValue)-\(offer.id.rawValue)-\(offer.counterAttempts)"))
        let concession: ClosedRange<Int> = switch offer.archetype {
        case .lowballer: 0...0
        case .reseller: 100...300
        case .bargainHunter: 200...500
        case .cautious: 400...700
        case .impatient: 200...500
        case .collector: 800...1_200
        }
        let ceiling = introduction ? offer.willingness : min(offer.willingness, try offer.amount.scaled(byBasisPoints: Int64(10_000 + random.integer(in: concession))))
        if amount <= ceiling { return .accept }
        let gap = try ceiling.subtracting(offer.amount)
        guard gap > .zero else { return .counter(offer.amount) }
        let step = max(Money(minorUnits: 1), try gap.scaled(byBasisPoints: Int64(random.integer(in: 3_000...7_000))))
        return .counter(min(offer.willingness, try offer.amount.adding(step)))
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
