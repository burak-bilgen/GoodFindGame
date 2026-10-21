import Foundation
import Testing
@testable import ProjectFlip

struct MarketFeedTests {
    let now = Date(timeIntervalSince1970: 100_000)
    var definitions: [ItemDefinition] { get throws { try SeedContent.load().items } }

    func scheduled(competitor: TimeInterval = 30, expiry: TimeInterval = 100, drop: TimeInterval = 20) throws -> GameSnapshot {
        var state = try GameSnapshot.fresh(definitions: definitions, now: now)
        state.market = [state.market[1]]
        state.marketFeedStartedAt = now
        state.lastKnownWallClock = now; state.lastSimulationAt = now
        let listing = state.market[0]
        state.watchedListingIDs = [listing.id]
        state.marketListingStates = [MarketListingState(id: listing.id, expiresAt: now.addingTimeInterval(expiry), competitorIdentityIndex: 3,
            competitorPurchaseAt: now.addingTimeInterval(competitor), initialAskingPrice: listing.askingPrice,
            priceDropAt: now.addingTimeInterval(drop), reducedPrice: try listing.askingPrice.scaled(byBasisPoints: 9_000))]
        try state.enqueue(.competitorPurchase(listingID: listing.id), createdAt: now, resolveAt: now.addingTimeInterval(competitor))
        try state.enqueue(.listingExpired(listingID: listing.id), createdAt: now, resolveAt: now.addingTimeInterval(expiry))
        try state.enqueue(.sellerPriceDrop(listingID: listing.id), createdAt: now, resolveAt: now.addingTimeInterval(drop))
        return state
    }

    @Test func actualCompetitionCancelsRepliesAndNeverCreatesPlayerCurrencyOrGoods() throws {
        let actions = SimulationActions(timing: SimulationTiming(sellerReply: 60...60, shipping: 4, inspection: 6, buyerInterest: 3...5, offerLifetime: 120, buyerArrivalsPerCatchUp: 12))
        var initial = try scheduled()
        // A completed historical sale selects normal seller timings, without enabling a feed in this isolated test.
        let offered = try BuyerTests.offeredState()
        initial.playerListings = try BuyerEngine().accept(listingID: offered.playerListings[0].id, state: offered, now: now).playerListings
        let listing = initial.market[0]
        let state = try actions.offer(listingID: listing.id, amount: listing.askingPrice, modifier: .none, state: initial, now: now)
        let plan = try NotificationPlanner().makePlan(state: state, definitions: definitions, locale: Locale(identifier: "en_US"), now: now)
        #expect(plan.count == 2)
        #expect(plan.allSatisfy { $0.route == .listing(listing.id) })
        #expect(plan[0].fireAt < plan[1].fireAt) // Price drop, then the genuine competing purchase.
        #expect(!plan.contains { $0.route == .conversation(listing.id) })
        let result = try EventResolver(timing: .instant).resolve(state, now: now.addingTimeInterval(101), definitions: definitions)
        #expect(!result.state.market[0].available)
        #expect(result.state.marketListingStates[0].closureReason == .competitor)
        #expect(result.state.player.cash == state.player.cash)
        #expect(result.state.player.inventory == state.player.inventory)
        #expect(result.state.conversations[0].closed && result.state.conversations[0].pendingReplyEventID == nil)
        #expect(result.state.conversations[0].messages.last?.intent == "seller.listingTaken")
        #expect(result.outcomes.map(\.kind) == [.priceDrop, .listingClosed])
        #expect(try EventResolver(timing: .instant).resolve(result.state, now: now.addingTimeInterval(101), definitions: definitions).outcomes.isEmpty)
        let response = try #require(state.events.first { if case .sellerReply = $0.payload { return true }; return false })
        let responseDelay = response.resolveAt.timeIntervalSince(now)
        initial = try scheduled(competitor: responseDelay)
        initial.playerListings = state.playerListings
        let sameTime = try actions.offer(listingID: initial.market[0].id, amount: initial.market[0].askingPrice, modifier: .none, state: initial, now: now)
        #expect(try !NotificationPlanner().makePlan(state: sameTime, definitions: definitions, locale: Locale(identifier: "en_US"), now: now).contains { $0.route == .conversation(listing.id) })
        let tie = try EventResolver(timing: .instant).resolve(sameTime, now: now.addingTimeInterval(responseDelay), definitions: definitions)
        #expect(tie.state.marketListingStates[0].closureReason == .competitor)
        #expect(tie.state.conversations[0].agreedPrice == nil)
    }

    @Test func firmQuoteDefersRetirementAndSkipsPriceDropsUntilItsOwnExpiry() throws {
        let initial = try scheduled(competitor: 4, expiry: 6, drop: 3)
        let listing = initial.market[0]
        let timing = SimulationTiming(sellerReply: 2...2, shipping: 4, inspection: 6, buyerInterest: 3...5, offerLifetime: 10, buyerArrivalsPerCatchUp: 12)
        let state = try SimulationActions(timing: timing).offer(listingID: listing.id, amount: listing.askingPrice, modifier: .none, state: initial, now: now)
        let plan = try NotificationPlanner().makePlan(state: state, definitions: definitions, locale: Locale(identifier: "tr_TR"), now: now)
        #expect(plan.count == 1 && plan[0].route == .conversation(listing.id))
        let resolver = EventResolver(timing: timing)
        let held = try resolver.resolve(state, now: now.addingTimeInterval(8), definitions: definitions)
        #expect(held.state.market[0].available)
        #expect(held.state.market[0].askingPrice == listing.askingPrice)
        #expect(held.state.marketListingStates[0].priceDroppedAt == nil)
        #expect(held.state.conversations[0].agreedPrice == listing.askingPrice)
        #expect(held.state.conversations[0].counterExpiresAt == now.addingTimeInterval(12))
        let expiry = try resolver.resolve(held.state, now: now.addingTimeInterval(12), definitions: definitions)
        #expect(expiry.state.market[0].available && expiry.state.conversations[0].closed)
        let closed = try resolver.resolve(expiry.state, now: now.addingTimeInterval(13), definitions: definitions)
        #expect(!closed.state.market[0].available)
        #expect(closed.outcomes.filter { $0.kind == .listingClosed }.count == 1)
        #expect(closed.state.marketListingStates[0].closureReason == .competitor)
    }

    @Test func priceDropAlertsRespectWatchPreferencesAndEarlierExpiry() throws {
        var state = try scheduled(competitor: 60, expiry: 50, drop: 20)
        let planner = NotificationPlanner()
        let en = try planner.makePlan(state: state, definitions: definitions, locale: Locale(identifier: "en_US"), now: now)
        let tr = try planner.makePlan(state: state, definitions: definitions, locale: Locale(identifier: "tr_TR"), now: now)
        #expect(en.count == 2 && tr.count == 2 && en[0].body != tr[0].body)
        #expect(en[1].body.contains("expired") && tr[1].body.contains("sona erdi"))
        #expect(tr[0].body.contains("₺"))
        state.watchedListingIDs = []
        #expect(try planner.makePlan(state: state, definitions: definitions, locale: Locale(identifier: "en_US"), now: now).isEmpty)
        state.watchedListingIDs = [state.market[0].id]
        state.notificationPreferences.enabledCategories.remove(.market)
        #expect(try planner.makePlan(state: state, definitions: definitions, locale: Locale(identifier: "en_US"), now: now).isEmpty)
        state = try scheduled(competitor: 60, expiry: 10, drop: 20)
        let earlyClosure = try planner.makePlan(state: state, definitions: definitions, locale: Locale(identifier: "en_US"), now: now)
        #expect(earlyClosure.count == 1)
        #expect(state.events.contains { $0.id == earlyClosure[0].id && $0.payload == .listingExpired(listingID: state.market[0].id) })
        let ended = try EventResolver(timing: .instant).resolve(state, now: now.addingTimeInterval(100), definitions: definitions)
        #expect(ended.state.marketListingStates[0].closureReason == .expired)
        #expect(ended.state.marketListingStates[0].priceDroppedAt == nil)
    }

    @Test func repeatedLongAbsencesRefreshOnceAndBoundSystemArchivesWhileKeepingWatchedItems() throws {
        let offered = try BuyerTests.offeredState()
        let sold = try BuyerEngine().accept(listingID: offered.playerListings[0].id, state: offered, now: now)
        let resolver = EventResolver(timing: .production)
        var state = try resolver.resolve(sold, now: now, definitions: definitions).state
        #expect(state.market.filter(\.available).count == 10)
        #expect(state.generation == sold.generation + 1)
        let watched = state.market[1].id
        state.watchedListingIDs = [watched]
        for day in 1...30 {
            state = try resolver.resolve(state, now: now.addingTimeInterval(Double(day) * 86_400), definitions: definitions).state
            #expect(state.market.filter(\.available).count == 10)
            #expect(state.market.count <= 60)
            #expect(state.events.count <= 250)
            #expect(state.market.contains { $0.id == watched })
        }
        #expect(state.generation == sold.generation + 31)
        #expect(state.player.cash == sold.player.cash)
        #expect(state.playerListings == sold.playerListings)
        #expect(state.market.first { $0.id == watched }?.available == false)
        #expect(try JSONDecoder().decode(GameSnapshot.self, from: JSONEncoder().encode(state)) == state)
    }

    @Test func lifecycleSavesRoundTripAndOldSavesMigrateWithoutLosingTruth() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let repository = SaveRepository(url: root.appendingPathComponent("save.json"))
        var state = try scheduled()
        try repository.save(state)
        #expect(try repository.load() == state)
        var legacy = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(state)) as? [String: Any])
        legacy.removeValue(forKey: "marketListingStates")
        legacy.removeValue(forKey: "marketFeedStartedAt")
        let migrated = try JSONDecoder().decode(GameSnapshot.self, from: JSONSerialization.data(withJSONObject: legacy))
        #expect(migrated.marketListingStates.isEmpty && migrated.marketFeedStartedAt == nil)
        #expect(migrated.market == state.market)
        state.marketListingStates.append(state.marketListingStates[0])
        try repository.save(state)
        let bytes = try Data(contentsOf: repository.url)
        #expect(throws: SaveError.self) { try repository.load() }
        #expect(try Data(contentsOf: repository.url) == bytes)
    }


    @Test func legacyFirmQuotesReceiveOneFullWindowBeforeCompetitionCanRetireThem() throws {
        var state = try scheduled(competitor: 4, expiry: 6, drop: 3)
        var legacy = NegotiationState(listingID: state.market[0].id, patience: 63)
        legacy.agreedPrice = state.market[0].askingPrice
        state.conversations = [legacy]
        let resolver = EventResolver(timing: .instant)
        let migrated = try resolver.resolve(state, now: now, definitions: definitions).state
        #expect(migrated.conversations[0].counterExpiresAt == now.addingTimeInterval(1_080))
        let held = try resolver.resolve(migrated, now: now.addingTimeInterval(8), definitions: definitions).state
        #expect(held.market[0].available && held.conversations[0].agreedPrice == legacy.agreedPrice)
        #expect(held.marketListingStates[0].priceDroppedAt == nil)
        let repeated = try resolver.resolve(held, now: now.addingTimeInterval(8), definitions: definitions).state
        #expect(repeated.nextEventSequence == held.nextEventSequence)
        #expect(repeated.conversations[0].counterExpiresAt == migrated.conversations[0].counterExpiresAt)
    }

}
