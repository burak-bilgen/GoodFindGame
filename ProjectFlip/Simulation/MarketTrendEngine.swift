import Foundation

struct MarketTrendEngine {
    /// At most the latest elapsed cycle is generated after a long absence. Fixed trade events
    /// still resolve normally; their prices can query the calendar at their own timestamps.
    func prepare(_ state: inout GameSnapshot, now: Date, definitions: [ItemDefinition]) throws {
        if state.marketCalendar == nil && state.playerListings.contains(where: { $0.status == .sold }) {
            state.marketCalendar = MarketCalendar(anchor: now, seed: SeededRandom.seed(for: state.simulationID), definitions: definitions)
        }
        guard var calendar = state.marketCalendar else { return }
        let currentCycle = max(state.lastMarketCycle ?? -1, try calendar.latestStartedIndex(at: now) ?? -1)
        try calendar.includeNewContent(definitions, after: currentCycle)
        state.marketCalendar = calendar
        guard (state.lastMarketCycle ?? -1) < Int.max - 1 else { throw SaveError.invalidSave }
        let target = max((state.lastMarketCycle ?? -1) + 1, try calendar.latestStartedIndex(at: now) ?? 0)
        var hasTarget = false
        for index in state.events.indices where state.events[index].status == .pending {
            if case .marketCycle(let cycle) = state.events[index].payload {
                if cycle == target && !hasTarget { hasTarget = true }
                else { state.events[index].status = .cancelled }
            }
        }
        if !hasTarget {
            let trend = try calendar.trend(at: target)
            try state.enqueue(.marketCycle(index: target), createdAt: min(now, trend.startsAt), resolveAt: trend.startsAt)
        }
    }

    func start(index: Int, state: inout GameSnapshot) throws -> Bool {
        guard let calendar = state.marketCalendar, index > (state.lastMarketCycle ?? -1) else { return false }
        let trend = try calendar.trend(at: index)
        state.lastMarketCycle = index
        state.marketTrends.append(trend)
        state.marketTrends = Array(state.marketTrends.suffix(14))
        try state.enqueue(.marketTrendEnded(trendID: trend.id), createdAt: trend.startsAt, resolveAt: trend.endsAt)
        let next = try calendar.trend(at: index + 1)
        try state.enqueue(.marketCycle(index: index + 1), createdAt: trend.startsAt, resolveAt: next.startsAt)
        return true
    }
}
