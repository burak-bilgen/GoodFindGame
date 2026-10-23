import Foundation
import Testing
@testable import ProjectFlip

struct TradingChallengeTests {
    @Test func professionalsDoNotUniversallyAcceptTwentyPercentBelowCleanValue() throws {
        let definitions = try SeedContent.load().items
        var samples = 0, accepted = 0
        for seed in 100..<120 {
            let listings = try ListingGenerator().generate(definitions: definitions, seed: UInt64(seed), now: .distantPast, starterFriendly: false)
            for listing in listings where listing.seller.archetype == .professional && listing.item.activeDefects.isEmpty {
                let definition = try #require(definitions.first { $0.id == listing.item.definitionID })
                let fair = try PricingEngine.fairValue(of: listing.item, definition: definition)
                let reply = try NegotiationEngine().offer(fair.scaled(byBasisPoints: 8_000), modifier: .none, listing: listing, current: NegotiationState(listingID: listing.id, patience: listing.seller.patience), reputation: 50)
                samples += 1
                if reply.agreedPrice != nil { accepted += 1 }
            }
        }
        print("CHALLENGE professional 80%-value bids accepted: \(accepted)/\(samples)")
        #expect(samples >= 20)
        #expect(accepted < samples / 2, "Professional stock currently supplies a near-universal 20% resale margin")
    }

    private func repeatBuyer(seed: Int, archetype: BuyerArchetype) throws -> GameSnapshot {
        var state = try BuyerTests.offeredState()
        let previous = PlayerListing(id: ListingID("completed"), itemID: state.playerListings[0].itemID, askingPrice: Money(minorUnits: 10_000), createdAt: .distantPast, status: .sold, views: 0, favorites: 0)
        state.playerListings.insert(previous, at: 0)
        state.playerListings[1].askingPrice = Money(minorUnits: 10_000)
        state.simulationID = "challenge-\(seed)"
        state.playerListings[1].offers = [BuyerOffer(id: OfferID("sample"), archetype: archetype, identityIndex: seed % 10, willingness: Money(minorUnits: 10_000), amount: Money(minorUnits: 9_000))]
        return state
    }

    @Test func raisingEveryFirstBuyerOfferIsNotAFreeDominantStrategy() throws {
        var walked = 0, improved = 0, firm = 0
        for seed in 0..<96 {
            let state = try repeatBuyer(seed: seed, archetype: BuyerArchetype.allCases[seed % BuyerArchetype.allCases.count])
            let id = state.playerListings[1].id
            let result = try BuyerEngine().counter(listingID: id, amount: Money(minorUnits: 9_900), state: state, now: .distantPast)
            #expect(try result == BuyerEngine().counter(listingID: id, amount: Money(minorUnits: 9_900), state: state, now: .distantPast))
            if result.playerListings[1].offers.last?.status == .withdrawn { walked += 1; #expect(result.player.cash == state.player.cash) }
            if result.playerListings[1].status == .sold { improved += 1 }
            if result.playerListings[1].offers.last?.status == .countered { firm += 1 }
        }
        print("CHALLENGE first buyer raises: \(improved) sold, \(walked) walked / 96")
        #expect(walked == 0 && improved > 0 && firm > 0, "Different buyers should accept or defend their price without a first-counter coin flip")
    }

    @Test func firstBuyerConcessionDoesNotRevealTheEntirePrivateBudget() throws {
        var counters = 0
        for seed in 0..<32 {
            let state = try repeatBuyer(seed: seed, archetype: .cautious)
            let result = try BuyerEngine().counter(listingID: state.playerListings[1].id, amount: Money(minorUnits: 11_000), state: state, now: .distantPast)
            let offer = try #require(result.playerListings[1].offers.last)
            if offer.status == .countered {
                counters += 1
                #expect(offer.amount > Money(minorUnits: 9_000))
                #expect(offer.amount < offer.willingness, "A single probe currently exposes the exact maximum")
            }
        }
        #expect(counters > 0)
    }
}

extension TradingChallengeTests {
    @Test func aReasonableFirstBuyerCounterDoesNotRandomlyEndTheConversation() throws {
        var walked = 0
        for seed in 0..<96 {
            let state = try repeatBuyer(seed: seed, archetype: BuyerArchetype.allCases[seed % BuyerArchetype.allCases.count])
            let reply = try BuyerEngine().counterDecision(listingID: state.playerListings[1].id, amount: Money(minorUnits: 9_090), state: state)
            if reply == .withdraw { walked += 1 }
        }
        print("FAIRNESS modest first counter walks: \(walked)/96")
        #expect(walked == 0, "A one-percent first counter should receive acceptance, a concession or a firm offer, not an unexplained walk")
    }

    @Test func aTinyPriceChangeDoesNotCreateAnAttentionCliff() throws {
        let definitions = try SeedContent.load().items
        let state = try BuyerTests.offeredState()
        let item = try #require(state.player.inventory.first)
        let definition = try #require(definitions.first { $0.id == item.definitionID })
        let fair = try PricingEngine.fairValue(of: item, definition: definition)
        var listing = state.playerListings[0]
        listing.askingPrice = try fair.scaled(byBasisPoints: 11_000)
        let before = try ListingAttention(listing: listing, item: item, definition: definition, state: state, at: .distantPast, seed: 12)
        listing.askingPrice = try fair.scaled(byBasisPoints: 11_010)
        let after = try ListingAttention(listing: listing, item: item, definition: definition, state: state, at: .distantPast, seed: 12)
        print("FAIRNESS tiny price change: delay \(before.delayFactor)→\(after.delayFactor), chance \(before.offerChance)→\(after.offerChance)")
        #expect(after.delayFactor - before.delayFactor < 0.02)
        #expect(before.offerChance - after.offerChance <= 1)
    }

    @Test func normalConversationRepliesHaveAnInteractiveTimeBudget() {
        #expect(SimulationTiming.production.sellerReply.upperBound <= 35)
        #expect(SimulationTiming.production.sellerReply.lowerBound >= 15)
        #expect(SimulationTiming.production.buyerInterest.upperBound <= 45)
        #expect((30...90).contains(SimulationTiming.production.shipping))
        #expect((30...120).contains(SimulationTiming.production.inspection))
        #expect(MarketFeedTiming.production.refresh <= 120)
    }

    @Test func sellerFatigueDoesNotMoveTheMinimumAboveAPreviouslyAcceptableBid() throws {
        let listings = try ListingGenerator().generate(definitions: SeedContent.load().items, seed: 108, now: .distantPast, starterFriendly: false)
        var samples = 0
        for listing in listings where listing.seller.patience > 35 {
            let minimum = min(listing.askingPrice, try listing.reservationPrice.scaled(byBasisPoints: Int64(10_000 + listing.seller.bargainingSkill * 2)))
            guard minimum < listing.askingPrice else { continue }
            var current = NegotiationState(listingID: listing.id, patience: listing.seller.patience - 10)
            current.offers = [Offer(id: OfferID("previous"), listingID: listing.id, amount: try minimum.scaled(byBasisPoints: 8_000), status: .countered)]
            let result = try NegotiationEngine().offer(minimum, modifier: .none, listing: listing, current: current, reputation: 50)
            samples += 1
            #expect(result.agreedPrice == minimum)
        }
        #expect(samples > 10)
    }

    @Test func aStandingOfferRemainsSafeEvenAfterRepeatedNegotiation() throws {
        for seed in 0..<24 {
            var state = try repeatBuyer(seed: seed, archetype: BuyerArchetype.allCases[seed % BuyerArchetype.allCases.count])
            state.playerListings[1].offers[0].counterAttempts = 2
            let cash = state.player.cash
            let sold = try BuyerEngine().counter(listingID: state.playerListings[1].id, amount: Money(minorUnits: 9_000), state: state, now: .distantPast)
            #expect(sold.playerListings[1].status == .sold)
            #expect(try sold.player.cash == cash.adding(Money(minorUnits: 9_000)))
            #expect(throws: TradingError.self) { try BuyerEngine().accept(listingID: sold.playerListings[1].id, state: sold, now: .distantPast) }
        }
    }

    @Test func counterForecastMatchesOfflineSettlementAndKeepsExpiryWhenBuyerWalks() throws {
        let definitions = try SeedContent.load().items
        let now = Date(timeIntervalSince1970: 100_000)
        var accepted = 0, walked = 0, countered = 0
        for seed in 0..<24 {
            var state = try repeatBuyer(seed: seed, archetype: seed % 3 == 1 ? .lowballer : .reseller)
            state.events = []
            let id = state.playerListings[1].id
            state.playerListings[1].expiresAt = now.addingTimeInterval(2_700)
            let offer = try #require(state.playerListings[1].offers.last)
            let amount = Money(minorUnits: seed % 3 == 0 ? 9_090 : seed % 3 == 1 ? 9_900 : 16_000)
            let decision = try BuyerEngine().counterDecision(listingID: id, amount: amount, state: state)
            try state.enqueue(.buyerReply(listingID: id, offerID: offer.id, amount: amount, expectedAttempts: 0), createdAt: now, resolveAt: now.addingTimeInterval(60))
            try state.enqueue(.playerListingExpired(listingID: id), createdAt: now, resolveAt: now.addingTimeInterval(2_700))
            let decoded = try JSONDecoder().decode(GameSnapshot.self, from: JSONEncoder().encode(state))
            #expect(try BuyerEngine().counterDecision(listingID: id, amount: amount, state: decoded) == decision)
            let plan = try NotificationPlanner().makePlan(state: decoded, definitions: definitions, locale: Locale(identifier: "en_US"), now: now)
            #expect(plan.contains { $0.body.contains("expired") } == (decision != .accept))
            let resolved = try EventResolver(timing: .production).resolve(decoded, now: now.addingTimeInterval(61), definitions: definitions).state
            #expect(try EventResolver(timing: .production).resolve(resolved, now: now.addingTimeInterval(61), definitions: definitions).state == resolved)
            if decision == .accept {
                accepted += 1
                #expect(resolved.playerListings[1].status == .sold)
                #expect(try resolved.player.cash == state.player.cash.adding(amount))
            } else if decision == .withdraw {
                walked += 1
                #expect(resolved.playerListings[1].status == .active)
                #expect(resolved.playerListings[1].offers[0].status == .withdrawn)
                #expect(resolved.player.cash == state.player.cash)
            } else {
                countered += 1
                #expect(resolved.playerListings[1].offers[0].status == .countered)
                #expect(resolved.playerListings[1].messages.last?.intent == "buyer.hold")
                #expect(resolved.player.cash == state.player.cash)
                let pushed = try BuyerEngine().counter(listingID: id, amount: amount, state: resolved, now: now.addingTimeInterval(62))
                #expect(pushed.playerListings[1].offers[0].status == .withdrawn)
                let taken = try BuyerEngine().accept(listingID: id, state: resolved, now: now.addingTimeInterval(62))
                #expect(taken.playerListings[1].status == .sold)
            }
        }
        #expect(accepted > 0 && walked > 0 && countered > 0)
    }

    @Test func newStockStillContainsBargainsAndLossRisksAcrossTheSameMarket() throws {
        let definitions = try SeedContent.load().items
        var bargains = 0, overpriced = 0
        for seed in 100..<110 {
            let listings = try ListingGenerator().generate(definitions: definitions, seed: UInt64(seed), now: .distantPast, starterFriendly: false)
            for listing in listings {
                let definition = try #require(definitions.first { $0.id == listing.item.definitionID })
                let fair = try PricingEngine.fairValue(of: listing.item, definition: definition)
                if listing.askingPrice < (try fair.scaled(byBasisPoints: 8_500)) { bargains += 1 }
                if listing.askingPrice > (try fair.scaled(byBasisPoints: 11_500)) { overpriced += 1 }
                #expect(listing.reservationPrice <= listing.askingPrice)
            }
        }
        print("CHALLENGE stock: \(bargains) below 85% value, \(overpriced) above 115% / 500")
        #expect(bargains > 0 && overpriced > 0)
    }
}

extension TradingChallengeTests {
    @Test func singleListingRefillsDoNotAlwaysReuseTheSameSellerTypeAndFace() throws {
        let definitions = try SeedContent.load().items
        let now = Date(timeIntervalSince1970: 100_000)
        let original = try GameSnapshot.fresh(definitions: definitions, now: now)
        var archetypes: Set<SellerArchetype> = [], identities: Set<Int> = []
        for seed in 0..<40 {
            var state = original
            state.generation = UInt64(seed)
            state.market = Array(state.market.prefix(9))
            try MarketFeedEngine(timing: .production).replenish(&state, now: now, definitions: definitions)
            let incoming = try #require(state.market.last)
            archetypes.insert(incoming.seller.archetype)
            identities.insert(incoming.seller.identityIndex)
            var replay = original
            replay.generation = UInt64(seed)
            replay.market = Array(replay.market.prefix(9))
            try MarketFeedEngine(timing: .production).replenish(&replay, now: now, definitions: definitions)
            #expect(state == replay)
            #expect(Array(state.market.prefix(9)) == Array(original.market.prefix(9)))
        }
        print("CHALLENGE singleton refills: \(archetypes.count) seller types, \(identities.count) identities / 40")
        #expect(archetypes.count > 1 && identities.count > 1, "Single-item refill batches currently always generate casual seller 0")
    }
}
