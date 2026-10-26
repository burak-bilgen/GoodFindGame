import Foundation

enum CareerTier: Int, Codable, CaseIterable, Sendable {
    case newcomer, known, specialist, trusted
    var key: String { "career.tier.\(rawValue)" }
    var requiredSales: Int { [0, 3, 8, 16][rawValue] }
    var requiredKnowledge: Int { [0, 0, 2, 3][rawValue] }
}

struct CareerRecord: Codable, Equatable {
    var creditedItems: Set<ItemID> = []
    var tradedModels: Set<String> = []
    var clientJobs = 0
    var accessVersion: Int? = 2
    var legacyAccessTier: CareerTier?
    var legacyAgreements: Set<ListingID>?
    func tier(knowledge: InspectionKnowledge) -> CareerTier {
        let rank = ItemCategory.allCases.map { knowledge.level(in: $0) }.max() ?? 0
        if creditedItems.count >= CareerTier.trusted.requiredSales && rank >= CareerTier.trusted.requiredKnowledge && (clientJobs >= 3 || creditedItems.count >= 24) { return .trusted }
        if creditedItems.count >= CareerTier.specialist.requiredSales && rank >= CareerTier.specialist.requiredKnowledge { return .specialist }
        if creditedItems.count >= CareerTier.known.requiredSales || clientJobs >= 1 { return .known }
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
    }
    static func requiredTier(for definition: ItemDefinition) -> CareerTier {
        switch definition.valueTier {
        case .premium: definition.baseValue >= Money(minorUnits: 120_000) ? .trusted : .specialist
        case .enthusiast: .specialist
        case .mainstream: ["gaming-1", "cameras-0", "cameras-1"].contains(definition.id) ? .newcomer : .known
        case .collector:
            if definition.baseValue >= Money(minorUnits: 60_000) { .trusted }
            else if definition.baseValue >= Money(minorUnits: 35_000) { .specialist }
            else if definition.baseValue > Money(minorUnits: 12_000) { .known }
            else { .newcomer }
        case .rare, .legendary: .trusted
        default: .newcomer
        }
    }
    static func canAccess(_ definition: ItemDefinition, state: GameSnapshot) -> Bool {
        let tier = state.career.tier(knowledge: state.inspectionKnowledge)
        if tier.rawValue >= requiredTier(for: definition).rawValue { return true }
        guard let previous = state.career.legacyAccessTier else { return false }
        return previous.rawValue >= legacyRequiredTier(for: definition).rawValue
    }
    private static func legacyRequiredTier(for definition: ItemDefinition) -> CareerTier {
        switch definition.valueTier {
        case .premium: .specialist
        case .enthusiast: .known
        case .collector: definition.baseValue > Money(minorUnits: 35_000) ? .known : .newcomer
        case .rare, .legendary: .trusted
        default: .newcomer
        }
    }
}
