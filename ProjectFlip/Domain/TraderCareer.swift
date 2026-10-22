import Foundation

enum CareerTier: Int, Codable, CaseIterable, Sendable {
    case newcomer, known, specialist, trusted
    var key: String { "career.tier.\(rawValue)" }
}

struct CareerRecord: Codable, Equatable {
    var creditedItems: Set<ItemID> = []
    var tradedModels: Set<String> = []
    var clientJobs = 0
    var legacyAgreements: Set<ListingID>?
    func tier(knowledge: InspectionKnowledge) -> CareerTier {
        let rank = ItemCategory.allCases.map { knowledge.level(in: $0) }.max() ?? 0
        if creditedItems.count >= 16 && rank >= 3 && (clientJobs >= 3 || creditedItems.count >= 24) { return .trusted }
        if creditedItems.count >= 8 && rank >= 2 { return .specialist }
        if creditedItems.count >= 3 || clientJobs >= 1 { return .known }
        return .newcomer
    }
}

/// Trust records completed inspected transactions, regardless of profit.
/// Access is the reward. Prices, fees and arrival odds never read trust.
enum CareerEngine {
    static func refresh(_ state: inout GameSnapshot) {
        for sale in state.playerListings where sale.status == .sold && (sale.saleKind == nil || sale.saleKind == .market || sale.saleKind == .client) {
            guard let item = sale.itemSnapshot, item.inspected else { continue }
            state.career.creditedItems.insert(item.id)
            state.career.tradedModels.insert(item.definitionID)
        }
        state.career.clientJobs = state.playerListings.filter { $0.status == .sold && $0.saleKind == .client }.count
        state.player.reputation = min(100, state.career.creditedItems.count * 3)
    }
    static func requiredTier(for definition: ItemDefinition) -> CareerTier {
        switch definition.valueTier {
        case .premium: .specialist
        case .enthusiast: .known
        case .collector: definition.baseValue > Money(minorUnits: 35_000) ? .known : .newcomer
        case .rare, .legendary: .trusted
        default: .newcomer
        }
    }
    static func canAccess(_ definition: ItemDefinition, state: GameSnapshot) -> Bool {
        state.career.tier(knowledge: state.inspectionKnowledge).rawValue >= requiredTier(for: definition).rawValue
    }
}
