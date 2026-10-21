import Foundation
import Testing
@testable import ProjectFlip

struct MarketplaceLifeTests {
    let now = Date(timeIntervalSince1970: 80_000)

    @Test func normalPlayUsesProductionPacingEvenInDebugBuilds() {
        #expect(SimulationTiming.current.shipping == SimulationTiming.production.shipping)
        #expect(SimulationTiming.current.sellerReply == SimulationTiming.production.sellerReply)
    }

    @Test func aNewListingStartsWithoutInventedTraffic() throws {
        let definitions = try SeedContent.load().items
        let original = try ResaleTests.inspectedState()
        let state = try ResaleEngine().create(itemID: original.player.inventory[0].id, askingPrice: Money(minorUnits: 180_000), state: original, definitions: definitions, now: now)
        #expect(state.playerListings[0].views == 0)
        #expect(state.playerListings[0].favorites == 0)
        #expect(state.playerListings[0].offers.isEmpty)
    }
}

extension MarketplaceLifeTests {
    @Test func trafficArrivesBeforeTheFirstBuyerAndSurvivesSaveReplay() throws {
        let definitions = try SeedContent.load().items
        let original = try ResaleTests.inspectedState()
        let actions = SimulationActions(timing: .production)
        let state = try actions.publish(itemID: original.player.inventory[0].id, askingPrice: Money(minorUnits: 180_000), state: original, definitions: definitions, now: now)
        #expect(state.playerListings[0].views == 0 && state.playerListings[0].offers.isEmpty)
        let resolver = EventResolver(timing: .production)
        let before = try resolver.resolve(state, now: now.addingTimeInterval(0.5), definitions: definitions).state
        #expect(before.playerListings[0].views == 0)
        let attention = try resolver.resolve(before, now: now.addingTimeInterval(2.1), definitions: definitions).state
        #expect(attention.playerListings[0].views > 0)
        #expect(attention.playerListings[0].offers.isEmpty)
        let saved = try JSONDecoder().decode(GameSnapshot.self, from: JSONEncoder().encode(attention))
        let arrived = try resolver.resolve(saved, now: now.addingTimeInterval(4), definitions: definitions).state
        #expect(arrived.playerListings[0].offers.count == 1)
        #expect(arrived.player.cash == original.player.cash)
        #expect(try resolver.resolve(arrived, now: now.addingTimeInterval(4), definitions: definitions).state == arrived)
    }

    private func repeatListing(_ seed: Int, price: Int64) throws -> (GameSnapshot, [ItemDefinition]) {
        let definitions = try SeedContent.load().items
        var state = try BuyerTests.offeredState()
        state = try BuyerEngine().accept(listingID: state.playerListings[0].id, state: state, now: now)
        var item = state.market[1].item
        item.inspected = true
        state.player.inventory.append(item)
        state.simulationID = "liquidity-\(seed)"
        let definition = try #require(definitions.first { $0.id == item.definitionID })
        let fair = try PricingEngine.fairValue(of: item, definition: definition)
        state = try ResaleEngine().create(itemID: item.id, askingPrice: fair.scaled(byBasisPoints: price), state: state, definitions: definitions, now: now)
        return (state, definitions)
    }

    @Test func priceAffectsLiquidityWithoutPromisingAnOfferAndFavoritesCanGoNowhere() throws {
        var cheapOffers = 0, expensiveOffers = 0
        var favoritesWithoutOffer = false
        for seed in 0..<80 {
            for factor: Int64 in [8_000, 18_000] {
                var (state, definitions) = try repeatListing(seed, price: factor)
                let listing = try #require(state.playerListings.last)
                try EventResolver(timing: .production).scheduleBuyer(listingID: listing.id, state: &state, definitions: definitions, now: now)
                let offer = state.events.contains { if case .buyerOffer = $0.payload { return true }; return false }
                if factor == 8_000 && offer { cheapOffers += 1 }
                if factor == 18_000 && offer { expensiveOffers += 1 }
                if !offer && state.events.contains(where: { if case .listingAttention(_, _, let favorites) = $0.payload { return favorites > 0 }; return false }) { favoritesWithoutOffer = true }
                let item = try #require(state.player.inventory.first)
                let definition = try #require(definitions.first { $0.id == item.definitionID })
                let sample = try ListingAttention(listing: listing, item: item, definition: definition, state: state, at: now, seed: 1)
                if factor == 8_000 { #expect(sample.delayFactor < 1) }
                else { #expect(sample.delayFactor > 2) }
            }
        }
        #expect(cheapOffers > expensiveOffers)
        #expect(cheapOffers > 0 && cheapOffers < 80)
        #expect(expensiveOffers > 0 && expensiveOffers < 80)
        #expect(favoritesWithoutOffer)
    }

    @Test func listingExpiryReturnsNoCashAndCancelsItsRemainingWork() throws {
        var (state, definitions) = try repeatListing(3, price: 30_000)
        let id = try #require(state.playerListings.last?.id)
        let cash = state.player.cash
        try EventResolver(timing: .production).scheduleBuyer(listingID: id, state: &state, definitions: definitions, now: now)
        let result = try EventResolver(timing: .production).resolve(state, now: now.addingTimeInterval(3_000), definitions: definitions)
        #expect(result.state.playerListings.last?.status == .expired)
        #expect(result.state.player.inventory.count == 1)
        #expect(result.state.player.cash == cash)
        #expect(result.outcomes.contains { $0.kind == .saleClosed && $0.targetID == id.rawValue })
        #expect(!result.state.events.contains { $0.status == .pending && $0.payload.targetID == id.rawValue })
        #expect(try EventResolver(timing: .production).resolve(result.state, now: now.addingTimeInterval(3_000), definitions: definitions).state == result.state)
    }

    @Test func untimedLegacyListingGetsOneFullWindowAndKeepsRecordedAttention() throws {
        var (state, definitions) = try repeatListing(3, price: 10_000)
        state.playerListings[1].expiresAt = nil
        state.playerListings[1].views = 42
        state.playerListings[1].favorites = 3
        let truth = state.player.inventory[0]
        let restored = try JSONDecoder().decode(GameSnapshot.self, from: JSONEncoder().encode(state))
        let result = try EventResolver(timing: .production).resolve(restored, now: now, definitions: definitions).state
        #expect(result.playerListings[1].expiresAt == now.addingTimeInterval(2_700))
        #expect(result.playerListings[1].views == 42 && result.playerListings[1].favorites == 3)
        #expect(result.player.inventory[0] == truth)
        #expect(try EventResolver(timing: .production).resolve(result, now: now, definitions: definitions).state == result)
    }

    @MainActor @Test func counterReplyDefersSettlementAndWithdrawalCancelsNotifications() throws {
        let definitions = try SeedContent.load().items
        let liveNow = Date.now
        var state = try BuyerTests.offeredState()
        state.playerListings[0].expiresAt = liveNow.addingTimeInterval(2_700)
        let id = state.playerListings[0].id
        let offer = try #require(state.playerListings[0].offers.last)
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let repository = SaveRepository(url: root.appendingPathComponent("save.json"))
        try repository.save(state)
        let store = try GameStore(repository: repository, definitions: definitions, timing: .production, now: liveNow)
        let cash = store.snapshot.player.cash
        try store.counterBuyer(listingID: id, amount: offer.willingness)
        #expect(store.snapshot.hasBuyerReply(for: id))
        #expect(store.snapshot.player.cash == cash)
        #expect(store.snapshot.playerListings[0].status == .active)
        #expect(throws: TradingError.self) { try store.acceptBuyer(listingID: id) }
        #expect(try NotificationPlanner().makePlan(state: store.snapshot, definitions: definitions, locale: Locale(identifier: "en_US"), now: liveNow).contains { $0.body.contains("replied") && $0.route == .sale(id) })
        let pending = store.snapshot
        let notifications = try NotificationPlanner().makePlan(state: pending, definitions: definitions, locale: Locale(identifier: "en_US"), now: liveNow)
        #expect(!notifications.contains { $0.body.contains("expired") })
        try store.catchUp(now: liveNow.addingTimeInterval(10), showSummary: true)
        #expect(store.snapshot.playerListings[0].status == .sold)
        #expect(try store.snapshot.player.cash == cash.adding(offer.willingness))
        try store.catchUp(now: liveNow.addingTimeInterval(10))
        #expect(try TradeLedger.records(from: store.snapshot).count == 1)
        try store.commit(pending)
        try store.withdrawListing(listingID: id)
        #expect(store.snapshot.playerListings[0].status == .cancelled)
        #expect(store.snapshot.player.inventory.count == 1)
        #expect(!store.snapshot.hasBuyerReply(for: id))
        #expect(try NotificationPlanner().makePlan(state: store.snapshot, definitions: definitions, locale: Locale(identifier: "en_US"), now: liveNow).isEmpty)
    }

    @Test func appraisalUsesOnlyKnownFaultsAndExpertiseNarrowsButNeverEliminatesUncertainty() throws {
        let definition = try SeedContent.load().items[0]
        var item = ItemInstance(id: ItemID("range"), definitionID: definition.id, condition: 80, hiddenDefects: [.drift], inspected: true)
        let novice = try ValueEstimate(item: item, definition: definition, knowledge: InspectionKnowledge())
        item = ItemInstance(id: item.id, definitionID: item.definitionID, condition: item.condition, hiddenDefects: [.batteryWear, .damagedPort], inspected: true)
        #expect(try ValueEstimate(item: item, definition: definition, knowledge: InspectionKnowledge()) == novice)
        item.professionallyInspected = true
        var knowledge = InspectionKnowledge(); knowledge.learn(16, in: .gaming)
        let expert = try ValueEstimate(item: item, definition: definition, knowledge: knowledge)
        #expect(expert.lower < expert.upper)
        #expect(expert.upper.minorUnits - expert.lower.minorUnits < novice.upper.minorUnits - novice.lower.minorUnits)
        #expect(expert.lower.minorUnits % 5_000 == 0 && expert.upper.minorUnits % 5_000 == 0)
    }
}

extension MarketplaceLifeTests {
    @Test func independentOpenLoopsSurviveOfflineReturnWhileMarketRemainsBrowsable() throws {
        var (state, definitions) = try repeatListing(11, price: 10_000)
        let shipped = state.market[2].item
        state.shipments.append(Shipment(id: "parallel-shipment", item: shipped, arrivesAt: now.addingTimeInterval(300)))
        try state.enqueue(.shipmentArrived(shipmentID: "parallel-shipment"), createdAt: now, resolveAt: now.addingTimeInterval(300))
        var inspected = state.market[5].item
        inspected.inspected = true
        state.player.inventory.append(inspected)
        state = try SimulationActions(timing: .production).inspect(itemID: inspected.id, professionally: true, state: state, now: now, definitions: definitions)
        let seller = state.market[3]
        state = try SimulationActions(timing: .production).offer(listingID: seller.id, amount: seller.askingPrice, modifier: .none, state: state, now: now)
        let resale = try #require(state.playerListings.last)
        try EventResolver(timing: .production).scheduleBuyer(listingID: resale.id, state: &state, definitions: definitions, now: now)
        #expect(state.shipments.contains { $0.status == .pending })
        #expect(state.inspectionJobs.contains { $0.status == .pending })
        #expect(state.conversations.contains { $0.pendingReplyEventID != nil })
        #expect(state.playerListings.contains { $0.status == .active })
        #expect(!MarketQuery().results(in: state, definitions: definitions, locale: Locale(identifier: "en_US")).isEmpty)
        let cash = state.player.cash
        let originalTruth = inspected.hiddenDefects
        let saved = try JSONDecoder().decode(GameSnapshot.self, from: JSONEncoder().encode(state))
        let result = try EventResolver(timing: .production).resolve(saved, now: now.addingTimeInterval(1_000), definitions: definitions)
        #expect(result.state.shipments.last?.status == .completed)
        #expect(result.state.inspectionJobs.last?.status == .completed)
        #expect(result.state.player.inventory.first(where: { $0.id == inspected.id })?.hiddenDefects == originalTruth)
        #expect(result.state.player.cash == cash)
        #expect(result.outcomes.contains { $0.kind == .shipment })
        #expect(result.outcomes.contains { $0.kind == .inspection })
        #expect(result.outcomes.contains { $0.kind == .sellerReply })
        #expect(try EventResolver(timing: .production).resolve(result.state, now: now.addingTimeInterval(1_000), definitions: definitions).state == result.state)
    }
}

extension MarketplaceLifeTests {
    @Test func introductionIsFastButRepeatAcquisitionWaitsMinutes() throws {
        let definitions = try SeedContent.load().items
        let first = try PurchaseTests.agreedState()
        let firstBought = try SimulationActions(timing: .production).purchase(listingID: first.market[0].id, state: first, now: now)
        #expect(firstBought.player.inventory.isEmpty)
        #expect(firstBought.shipments[0].arrivesAt.timeIntervalSince(now) <= 5)
        var (later, _) = try repeatListing(7, price: 10_000)
        let listing = later.market[2]
        later.conversations.append(NegotiationState(listingID: listing.id, patience: listing.seller.patience, agreedPrice: listing.askingPrice))
        let bought = try SimulationActions(timing: .production).purchase(listingID: listing.id, state: later, now: now)
        let shipment = try #require(bought.shipments.last)
        #expect(shipment.arrivesAt.timeIntervalSince(now) >= 179.99)
        #expect(shipment.arrivesAt.timeIntervalSince(now) <= 480)
        #expect(!bought.player.inventory.contains { $0.id == listing.item.id })
    }

    @Test func corruptedAttentionIsRejectedWithoutReplacingTheSave() throws {
        var (state, _) = try repeatListing(8, price: 10_000)
        try state.enqueue(.listingAttention(listingID: state.playerListings[1].id, views: -1, favorites: 0), createdAt: now, resolveAt: now.addingTimeInterval(2))
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let repository = SaveRepository(url: root.appendingPathComponent("save.json"))
        try repository.save(state)
        let bytes = try Data(contentsOf: repository.url)
        #expect(throws: SaveError.self) { try repository.load() }
        #expect(try Data(contentsOf: repository.url) == bytes)
    }
}

extension MarketplaceLifeTests {
    @MainActor @Test func aLateCounterCannotPromiseAReplyAfterTheListingEndsButAcceptStillWorks() throws {
        var (state, definitions) = try repeatListing(4, price: 10_000)
        let id = state.playerListings[1].id
        let liveNow = Date.now
        state.playerListings[1].expiresAt = liveNow.addingTimeInterval(30)
        state = try BuyerEngine().generateOffer(listingID: id, state: state, definitions: definitions, now: liveNow)
        let offer = try #require(state.playerListings[1].offers.last)
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let repository = SaveRepository(url: root.appendingPathComponent("save.json"))
        try repository.save(state)
        let store = try GameStore(repository: repository, definitions: definitions, timing: .production, now: liveNow)
        #expect(throws: TradingError.replyWindowTooShort) { try store.counterBuyer(listingID: id, amount: offer.willingness) }
        #expect(!store.snapshot.hasBuyerReply(for: id))
        try store.acceptBuyer(listingID: id)
        #expect(store.snapshot.playerListings[1].status == .sold)
    }
}

extension MarketplaceLifeTests {
    @Test func watchedClosureNotificationsFollowTheActualWinnerAndSuppressHeldOrInvalidClosures() throws {
        var (state, definitions) = try repeatListing(8, price: 10_000)
        try MarketFeedEngine(timing: .debug).prepare(&state, now: now, definitions: definitions)
        let listing = state.market[4]
        state.watchedListingIDs.insert(listing.id)
        state.events.removeAll { $0.payload.targetID == listing.id.rawValue }
        try state.enqueue(.competitorPurchase(listingID: listing.id), createdAt: now, resolveAt: now.addingTimeInterval(10))
        try state.enqueue(.listingExpired(listingID: listing.id), createdAt: now, resolveAt: now.addingTimeInterval(20))
        func plans(_ state: GameSnapshot) throws -> [LocalNotificationSpec] {
            try NotificationPlanner().makePlan(state: state, definitions: definitions, locale: Locale(identifier: "en_US"), now: now).filter { $0.route == .listing(listing.id) }
        }
        let plan = try plans(state)
        #expect(plan.count == 1)
        #expect(try #require(plan.first).body.contains("Another trader bought"))
        var held = state
        held.conversations.append(NegotiationState(listingID: listing.id, patience: 50, counterPrice: listing.askingPrice, counterExpiresAt: now.addingTimeInterval(50)))
        #expect(try plans(held).isEmpty)
        let resolved = try EventResolver(timing: .debug).resolve(state, now: now.addingTimeInterval(30), definitions: definitions)
        #expect(resolved.state.marketListingStates.first(where: { $0.id == listing.id })?.closureReason == .competitor)
        #expect(try plans(resolved.state).isEmpty)
    }
}
