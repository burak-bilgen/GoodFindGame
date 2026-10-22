import Foundation
import Testing
@testable import ProjectFlip

struct RecoveryTests {
    @Test func recoveryCannotFarmWealthExpertiseTrustOrStock() throws {
        let definitions = try SeedContent.load().items
        var state = try GameSnapshot.fresh(definitions: definitions)
        #expect(!RecoveryEngine.canBegin(state))
        state.player.cash = .zero
        var jobs = 0
        while RecoveryEngine.canBegin(state) {
            state = try RecoveryEngine.begin(state: state, definitions: definitions, now: .distantPast)
            let id = try #require(state.recovery.itemID)
            #expect(throws: TradingError.self) { try ResaleEngine().create(itemID: id, askingPrice: Money(minorUnits: 4_000), state: state, definitions: definitions, now: .distantPast) }
            #expect(throws: TradingError.self) { try RecoveryEngine.complete(state: state, now: .distantPast) }
            state = try InspectionEngine().inspect(itemID: id, professionally: false, state: state)
            state = try RecoveryEngine.complete(state: state, now: .distantPast)
            CareerEngine.refresh(&state)
            #expect(state.career.creditedItems.isEmpty && state.inspectionKnowledge.points(in: .gaming) == 0)
            #expect(state.player.inventory.isEmpty)
            #expect(throws: TradingError.self) { try RecoveryEngine.complete(state: state, now: .distantPast) }
            jobs += 1
            #expect(jobs <= 5)
        }
        #expect(jobs == 5 && state.player.cash == RecoveryEngine.capitalFloor)
        #expect(state.recovery.recovered == true)
        // Eligibility must survive later spending, even if the companion journal was unavailable.
        state.player.cash = .zero
        #expect(try AchievementEngine.progress(state)[.comeback] == 100)
        #expect(try TradeLedger.totalProfit(TradeLedger.records(from: state)) == RecoveryEngine.capitalFloor)
        try RecoveryEngine.validate(state)
    }
    @Test func liquidationIsALossAndRetainsHistoryAndCapabilities() throws {
        let definitions = try SeedContent.load().items
        var state = try ResaleTests.inspectedState()
        state.inspectionKnowledge.learn(8, in: .gaming)
        let item = state.player.inventory[0]
        let cash = state.player.cash
        let next = try RecoveryEngine.liquidate(item.id, state: state, definitions: definitions, now: .distantPast)
        let record = try TradeRecord(listing: next.playerListings[0])
        #expect(record.netProfit < .zero && record.kind == .liquidation)
        #expect(try next.player.cash == cash.adding(record.soldFor))
        #expect(next.inspectionKnowledge == state.inspectionKnowledge)
        #expect(throws: TradingError.self) { try RecoveryEngine.liquidate(item.id, state: next, definitions: definitions, now: .distantPast) }
    }
}
