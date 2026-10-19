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

struct MarketScopeEpoch: Codable, Equatable {
    let firstCycle: Int
    let categories: [ItemCategory]
    let models: [String]
}

/// Version-one market calendar. Saved scope epochs let content expand without rerolling
/// historical movements or the already-booked next cycle. Dates use simulation seconds, independent of time zone.
struct MarketCalendar: Codable, Equatable {
    let version: Int
    let anchor: Date
    let seed: UInt64
    let categories: [ItemCategory]
    let models: [String]
    var scopeEpochs: [MarketScopeEpoch] = []
    static let cadence: TimeInterval = 86_400
    static let firstDelay: TimeInterval = 43_200

    init(anchor: Date, seed: UInt64, definitions: [ItemDefinition]) {
        version = 1
        self.anchor = anchor; self.seed = seed
        categories = ItemCategory.allCases.filter { category in definitions.contains { $0.category == category } }
        models = definitions.map(\.id).sorted()
    }

    enum CodingKeys: String, CodingKey { case version, anchor, seed, categories, models, scopeEpochs }
    init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        version = try values.decode(Int.self, forKey: .version)
        anchor = try values.decode(Date.self, forKey: .anchor)
        seed = try values.decode(UInt64.self, forKey: .seed)
        categories = try values.decode([ItemCategory].self, forKey: .categories)
        models = try values.decode([String].self, forKey: .models)
        scopeEpochs = try values.decodeIfPresent([MarketScopeEpoch].self, forKey: .scopeEpochs) ?? []
    }

    mutating func includeNewContent(_ definitions: [ItemDefinition], after cycle: Int) throws {
        let currentCategories = scopeEpochs.last?.categories ?? categories
        let currentModels = scopeEpochs.last?.models ?? models
        let expandedCategories = ItemCategory.allCases.filter { category in
            currentCategories.contains(category) || definitions.contains { $0.category == category }
        }
        let expandedModels = Set(currentModels).union(definitions.map(\.id)).sorted()
        guard Set(expandedCategories) != Set(currentCategories) || Set(expandedModels) != Set(currentModels) else { return }
        guard cycle < Int.max - 2 else { throw EventQueueError.invalidTimestamp }
        // Keep both the current cycle and the next known cycle unchanged.
        let first = max(cycle + 2, (scopeEpochs.last?.firstCycle ?? -1) + 1)
        guard first < Int.max - 1 else { throw EventQueueError.invalidTimestamp }
        scopeEpochs.append(MarketScopeEpoch(firstCycle: first, categories: expandedCategories, models: expandedModels))
    }

    func validate() throws {
        guard version == 1, anchor.timeIntervalSinceReferenceDate.isFinite,
              !categories.isEmpty, !models.isEmpty,
              Set(categories).count == categories.count, Set(models).count == models.count else { throw SaveError.invalidSave }
        var previous = -1
        for epoch in scopeEpochs {
            guard epoch.firstCycle > previous, epoch.firstCycle < Int.max - 1,
                  !epoch.categories.isEmpty, !epoch.models.isEmpty,
                  Set(epoch.categories).count == epoch.categories.count, Set(epoch.models).count == epoch.models.count else { throw SaveError.invalidSave }
            previous = epoch.firstCycle
        }
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
        let epoch = scopeEpochs.last { $0.firstCycle <= index }
        let categories = epoch?.categories ?? self.categories
        let models = epoch?.models ?? self.models
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
