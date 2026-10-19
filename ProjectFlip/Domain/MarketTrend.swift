import Foundation

enum MarketTrendScope: Codable, Equatable, Sendable {
    case category(ItemCategory)
    case model(String)

    func includes(_ definition: ItemDefinition) -> Bool {
        switch self {
        case .category(let category): definition.category == category
        case .model(let id): definition.id == id
        }
    }
}

enum MarketTrendReason: String, Codable, Sendable {
    case creatorSpotlight, newModelLaunch, seasonalDemand, coolingDemand
    var key: String { "trend.reason.\(rawValue)" }
}

struct MarketTrend: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let scope: MarketTrendScope
    let startsAt: Date
    let endsAt: Date
    let changeBasisPoints: Int64
    let reason: MarketTrendReason
    func isActive(at date: Date) -> Bool { startsAt <= date && date < endsAt }
    var multiplier: Int64 { 10_000 + changeBasisPoints }
}

/// Version-one market calendar. Its scope pool and seed are saved, so adding content cannot
/// reroll an existing world's schedule. Dates use simulation seconds, independent of time zone.
struct MarketCalendar: Codable, Equatable {
    let version: Int
    let anchor: Date
    let seed: UInt64
    let categories: [ItemCategory]
    let models: [String]
    static let cadence: TimeInterval = 86_400
    static let firstDelay: TimeInterval = 43_200

    init(anchor: Date, seed: UInt64, definitions: [ItemDefinition]) {
        version = 1
        self.anchor = anchor; self.seed = seed
        categories = ItemCategory.allCases.filter { category in definitions.contains { $0.category == category } }
        models = definitions.map(\.id).sorted()
    }

    func latestStartedIndex(at date: Date) throws -> Int? {
        let elapsed = date.timeIntervalSince(anchor) - Self.firstDelay
        guard elapsed.isFinite else { throw EventQueueError.invalidTimestamp }
        if elapsed < 0 { return nil }
        let index = floor(elapsed / Self.cadence)
        guard index < Double(Int.max - 1) else { throw EventQueueError.invalidTimestamp }
        return Int(index)
    }

    func trend(at index: Int) throws -> MarketTrend {
        guard version == 1, index >= 0, index < Int.max, !categories.isEmpty, !models.isEmpty else { throw SaveError.invalidSave }
        var random = SeededRandom(seed: SeededRandom.seed(for: "market-v1-\(seed)-\(index)"))
        let categoryWide = random.integer(in: 0...1) == 0
        let scope: MarketTrendScope = categoryWide
            ? .category(categories[random.integer(in: 0...(categories.count - 1))])
            : .model(models[random.integer(in: 0...(models.count - 1))])
        let rising = random.integer(in: 0...1) == 0
        let change = Int64(random.integer(in: 500...1_200)) * (rising ? 1 : -1)
        let start = anchor.addingTimeInterval(Self.firstDelay + Double(index) * Self.cadence)
        let end = start.addingTimeInterval(TimeInterval(random.integer(in: 14...18)) * 3_600)
        guard start.timeIntervalSinceReferenceDate.isFinite, end.timeIntervalSinceReferenceDate.isFinite else { throw EventQueueError.invalidTimestamp }
        return MarketTrend(id: "trend-\(seed)-\(index)", scope: scope, startsAt: start, endsAt: end,
                           changeBasisPoints: change,
                           reason: categoryWide ? (rising ? .seasonalDemand : .coolingDemand) : (rising ? .creatorSpotlight : .newModelLaunch))
    }

    func multiplier(for definition: ItemDefinition, at date: Date) throws -> Int64 {
        guard let index = try latestStartedIndex(at: date) else { return 10_000 }
        let trend = try trend(at: index)
        return trend.isActive(at: date) && trend.scope.includes(definition) ? trend.multiplier : 10_000
    }
}

extension GameSnapshot {
    func marketMultiplier(for definition: ItemDefinition, at date: Date? = nil) throws -> Int64 {
        guard let marketCalendar else { return 10_000 }
        return try marketCalendar.multiplier(for: definition, at: date ?? lastSimulationAt ?? marketCalendar.anchor)
    }
}
