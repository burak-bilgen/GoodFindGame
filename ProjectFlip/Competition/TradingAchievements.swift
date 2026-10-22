import Foundation

/// All eligibility comes from persisted gameplay facts; no ad, payment or permission goals.
enum TradingAchievement: String, Codable, CaseIterable {
    case firstFlip, naturalTrader, thatHurt, detective, negotiator, collector
    case trustedTrader, specialist, bigLeague, comeback, versatile, weeklyFinisher
    var titleKey: String { "achievement.\(rawValue).title" }
    var detailKey: String { "achievement.\(rawValue).detail" }
}

enum AchievementEngine {
    static func progress(_ state: GameSnapshot) throws -> [TradingAchievement: Double] {
        let trades = try TradeLedger.records(from: state).filter { $0.kind == .market || $0.kind == .client }
        var result: [TradingAchievement: Double] = [:]
        func add(_ achievement: TradingAchievement, _ count: Int, _ target: Int = 1) {
            result[achievement] = min(100, Double(count) * 100 / Double(target))
        }
        add(.firstFlip, trades.contains { $0.netProfit > .zero } ? 1 : 0)
        add(.naturalTrader, trades.contains { $0.totalCost.minorUnits >= 1_000 && $0.netProfit >= $0.totalCost } ? 1 : 0)
        add(.thatHurt, trades.contains { $0.netProfit.minorUnits <= -1_000 && $0.totalCost.minorUnits >= 5_000 } ? 1 : 0)
        // Seller disclosures persist before purchase. Count distinct listings, never repeated questions.
        add(.detective, state.conversations.filter { !$0.knownDefects.isEmpty }.count, 5)
        let acquired = state.player.inventory + state.shipments.map(\.item) + state.playerListings.compactMap(\.itemSnapshot)
        add(.negotiator, acquired.contains { item in
            guard item.purchasePrice > .zero, let listing = state.market.first(where: { $0.item.id == item.id }),
                  let threshold = try? listing.askingPrice.scaled(byBasisPoints: 8_000) else { return false }
            return item.purchasePrice <= threshold
        } ? 1 : 0)
        add(.collector, state.collections.completedBefore.count)
        add(.trustedTrader, state.career.creditedItems.count, 10)
        add(.specialist, ItemCategory.allCases.map { state.inspectionKnowledge.level(in: $0) }.max() ?? 0, 3)
        add(.bigLeague, state.career.tier(knowledge: state.inspectionKnowledge) == .trusted ? 1 : 0)
        add(.comeback, state.recovery.commissionsEarned > .zero && state.player.cash >= RecoveryEngine.capitalFloor ? 1 : 0)
        let models = Set(trades.filter { $0.netProfit > .zero }.map(\.definitionID))
        add(.versatile, models.count, 5)
        return result
    }
}

struct AchievementJournal: Codable, Equatable {
    var progress: [String: Double] = [:]
    /// Acknowledgements belong to an account. Switching accounts never drops the local earned record.
    var acknowledged: [String: [String: Double]] = [:]

    mutating func merge(_ values: [TradingAchievement: Double]) {
        for (achievement, percent) in values {
            let id = CompetitionIDs.achievement(achievement)
            let previous = progress[id, default: 0]
            progress[id] = max(previous, min(100, max(0, percent)))
            if previous < 100 && progress[id] == 100 { CompetitionAnalytics.record(.achievementEarned) }
        }
    }
    func pending(for player: String) -> [String: Double] {
        progress.filter { $0.value > (acknowledged[player]?[$0.key] ?? 0) }
    }
    mutating func acknowledge(_ values: [String: Double], player: String) {
        for (id, percent) in values {
            acknowledged[player, default: [:]][id] = max(acknowledged[player]?[id] ?? 0, percent)
        }
    }
    func validate() throws {
        let allowed = Set(TradingAchievement.allCases.map(CompetitionIDs.achievement))
        guard progress.allSatisfy({ allowed.contains($0.key) && $0.value.isFinite && (0...100).contains($0.value) }),
              acknowledged.values.allSatisfy({ $0.allSatisfy { allowed.contains($0.key) && $0.value.isFinite && (0...100).contains($0.value) } }) else { throw SaveError.invalidSave }
    }
}
