import Foundation
import Testing
@testable import ProjectFlip

struct MarketTrendTests {
    let now = Date(timeIntervalSince1970: 100_000)

    @Test func boundedCalendarSurvivesReloadAndUsesExactStartEndBoundaries() throws {
        let definitions = try SeedContent.load().items
        let calendar = MarketCalendar(anchor: now, seed: 42, definitions: definitions)
        let restored = try JSONDecoder().decode(MarketCalendar.self, from: JSONEncoder().encode(calendar))
        for index in 0..<1_000 {
            let trend = try calendar.trend(at: index)
            #expect(try restored.trend(at: index) == trend)
            #expect((500...1_200).contains(trend.changeBasisPoints.magnitude))
            #expect(trend.endsAt.timeIntervalSince(trend.startsAt) >= 14 * 3_600)
            let affected = try #require(definitions.first { trend.scope.includes($0) })
            #expect(try calendar.multiplier(for: affected, at: trend.startsAt) == trend.multiplier)
            #expect(try calendar.multiplier(for: affected, at: trend.endsAt) == 10_000)
            for other in definitions where !trend.scope.includes(other) {
                #expect(try calendar.multiplier(for: other, at: trend.startsAt) == 10_000)
            }
        }
        #expect(try calendar.latestStartedIndex(at: now) == nil)
    }

    @Test func firstSaleUnlocksRealEventsAndYearAwayDoesNotCreateHundredsOfCycles() throws {
        let definitions = try SeedContent.load().items
        let resolver = EventResolver(timing: .production)
        let fresh = try GameSnapshot.fresh(definitions: definitions, now: now)
        #expect(try resolver.resolve(fresh, now: now, definitions: definitions).state.marketCalendar == nil)
        let offered = try BuyerTests.offeredState()
        let sold = try BuyerEngine().accept(listingID: offered.playerListings[0].id, state: offered, now: now)
        var state = try resolver.resolve(sold, now: now, definitions: definitions).state
        let calendar = try #require(state.marketCalendar)
        let trend = try calendar.trend(at: 0)
        let plan = try NotificationPlanner().makePlan(state: state, definitions: definitions, locale: Locale(identifier: "tr_TR"), now: now)
        #expect(plan.count == 1)
        #expect(plan[0].category == .market)
        #expect(plan[0].route == .trend(trend.id))
        #expect(plan[0].body.contains(trend.formattedChange(locale: Locale(identifier: "tr_TR"))))
        state.notificationPreferences.enabledCategories.remove(.market)
        #expect(try NotificationPlanner().makePlan(state: state, definitions: definitions, locale: Locale(identifier: "tr_TR"), now: now).isEmpty)
        let start = try resolver.resolve(state, now: trend.startsAt, definitions: definitions)
        #expect(start.outcomes.map(\.kind) == [.marketTrend])
        #expect(start.outcomes[0].targetID == trend.id)
        #expect(start.state.marketTrends == [trend])
        #expect(try resolver.resolve(start.state, now: trend.startsAt, definitions: definitions).outcomes.isEmpty)
        let end = try resolver.resolve(start.state, now: trend.endsAt, definitions: definitions)
        #expect(end.outcomes.map(\.kind) == [.marketTrend])
        let later = try resolver.resolve(end.state, now: now.addingTimeInterval(365 * 86_400), definitions: definitions)
        #expect(later.state.marketTrends.count == 2)
        #expect(later.state.events.count < 10)
        #expect(later.state.player.cash == sold.player.cash)
        #expect(later.state.playerListings == sold.playerListings)
        #expect(later.state.events.filter { $0.status == .pending }.allSatisfy { $0.resolveAt > later.clock.effectiveNow })
        #expect(try JSONDecoder().decode(GameSnapshot.self, from: JSONEncoder().encode(later.state)) == later.state)
        let rolledBack = try resolver.resolve(later.state, now: later.clock.observedNow.addingTimeInterval(-86_400), definitions: definitions)
        #expect(rolledBack.outcomes.isEmpty)
        #expect(rolledBack.state.marketTrends == later.state.marketTrends)
        #expect(rolledBack.state.nextEventSequence == later.state.nextEventSequence)
    }

    @Test func demandChangesValuationAndFutureBuyerBudgetWithoutRepricingHeldOffers() throws {
        let definitions = try SeedContent.load().items
        var state = try ResaleTests.inspectedState()
        let item = state.player.inventory[0]
        let definition = definitions[0]
        state.marketCalendar = MarketCalendar(anchor: now, seed: 42, definitions: [definition])
        let calendar = try #require(state.marketCalendar)
        let trend = try calendar.trend(at: 0)
        let listed = try ResaleEngine().create(itemID: item.id, askingPrice: Money(minorUnits: 280_000), state: state, definitions: definitions, now: now)
        let id = listed.playerListings[0].id
        let baseline = try BuyerEngine().generateOffer(listingID: id, state: listed, definitions: definitions, now: now)
        let shifted = try BuyerEngine().generateOffer(listingID: id, state: listed, definitions: definitions, now: trend.startsAt)
        #expect(baseline.playerListings[0].offers[0].willingness != shifted.playerListings[0].offers[0].willingness)
        var upcoming = listed
        try EventResolver(timing: .production).scheduleBuyer(listingID: id, state: &upcoming, definitions: definitions, now: trend.startsAt.addingTimeInterval(-1))
        let scheduled = try #require(upcoming.events.last)
        guard case .buyerOffer(_, _, let planned, _, _) = scheduled.payload else { Issue.record("Expected a real precomputed buyer offer"); return }
        #expect(scheduled.resolveAt > trend.startsAt)
        #expect(planned.willingness == shifted.playerListings[0].offers[0].willingness)
        let oldEstimate = try InspectionEngine().estimatedValue(item: item, definition: definition)
        let estimate = try InspectionEngine().estimatedValue(item: item, definition: definition, marketBasisPoints: state.marketMultiplier(for: definition, at: trend.startsAt))
        #expect(try estimate == oldEstimate.scaled(byBasisPoints: trend.multiplier))
        let generated = try ListingGenerator().generate(definitions: [definition], seed: 42, now: trend.startsAt, market: state)
        let original = try ListingGenerator().generate(definitions: [definition], seed: 42, now: trend.startsAt)
        #expect(generated[0].askingPrice != original[0].askingPrice)
        #expect(generated[0].item == original[0].item)
        var future = baseline
        future.lastKnownWallClock = now; future.lastSimulationAt = now
        let resolved = try EventResolver(timing: .production).resolve(future, now: trend.startsAt, definitions: definitions)
        #expect(resolved.state.playerListings[0].offers == baseline.playerListings[0].offers)
        #expect(try GameRoute.decode(GameRoute.trend(trend.id).encoded()) == .trend(trend.id))
    }

    @Test func calendarSaveMigrationAndCorruptionNeverOverwriteTheOriginal() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let repository = SaveRepository(url: root.appendingPathComponent("save.json"))
        let definitions = try SeedContent.load().items
        var state = try GameSnapshot.fresh(definitions: definitions)
        state.marketCalendar = MarketCalendar(anchor: now, seed: 42, definitions: definitions)
        try repository.save(state)
        #expect(try repository.load() == state)
        var legacy = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(state)) as? [String: Any])
        legacy.removeValue(forKey: "marketCalendar")
        legacy.removeValue(forKey: "marketTrends")
        legacy.removeValue(forKey: "lastMarketCycle")
        let migrated = try JSONDecoder().decode(GameSnapshot.self, from: JSONSerialization.data(withJSONObject: legacy))
        #expect(migrated.marketCalendar == nil && migrated.marketTrends.isEmpty && migrated.lastMarketCycle == nil)
        state.lastMarketCycle = Int.max
        try repository.save(state)
        let original = try Data(contentsOf: repository.url)
        #expect(throws: SaveError.self) { try repository.load() }
        #expect(try Data(contentsOf: repository.url) == original)
    }

}
