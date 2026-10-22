import Foundation
import Testing
@testable import ProjectFlip

struct CompetitionScoreTests {
    @Test func scoreUsesFixedBankrollAndAggregateROI() throws {
        let trade = TraderScore.Input(cost: 10_000, proceeds: 20_000, model: "camera", inspected: true)
        #expect(try TraderScore.calculate([trade]) == 4_500)
        #expect(try TraderScore.calculate([]) == 0)
        #expect(try TraderScore.calculate([.init(cost: 10_000, proceeds: 5_000, model: "loss", inspected: true)]) == 0)
        let tiny = TraderScore.Input(cost: 1, proceeds: 2, model: "tiny", inspected: false)
        #expect(try TraderScore.calculate([tiny]) == 0)
        // Quality bonus is for distinct models, not repeated volume.
        let repeated = try TraderScore.calculate([trade, trade])
        #expect(repeated == 6_500)
    }
    @Test func capsAndMalformedInputsAreSafe() throws {
        #expect(try TraderScore.calculate((0..<20).map { .init(cost: 1_000, proceeds: 1_000_000_000, model: "m\($0)", inspected: true) }) == TraderScore.cap)
        for value in [Int64.min, -1, 0, TraderScore.transactionLimit + 1, Int64.max] {
            #expect(throws: SaveError.self) { try TraderScore.calculate([.init(cost: value, proceeds: 1, model: "m", inspected: true)]) }
        }
        #expect(throws: SaveError.self) { try TraderScore.calculate([.init(cost: 1, proceeds: Int64.max, model: "m", inspected: true)]) }
        #expect(throws: SaveError.self) { try TraderScore.calculate(Array(repeating: .init(cost: 1, proceeds: 1, model: "m", inspected: false), count: 10_001)) }
        #expect(try TraderScore.calculate(Array(repeating: .init(cost: 1_000_000_000, proceeds: 1_000_000_000, model: "m", inspected: false), count: 10_000)) == 0)
    }
    @Test func periodsHaveUTCAnchorAndNoTimezoneDependency() throws {
        let period = WeeklyPeriod(index: 146)
        #expect(WeeklyPeriod.containing(period.start) == period)
        #expect(WeeklyPeriod.containing(period.end.addingTimeInterval(-0.001)) == period)
        #expect(WeeklyPeriod.containing(period.end).index == period.index + 1)
        #expect(period.matches(start: period.start, duration: 604_800))
        #expect(!period.matches(start: period.start.addingTimeInterval(3_600), duration: 604_800))
        #expect(!period.matches(start: period.start, duration: 86_400))
        #expect(throws: SaveError.self) { try WeeklyPeriod(index: Int.max).validate() }
    }
}
