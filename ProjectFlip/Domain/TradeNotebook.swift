import Foundation

/// Derived from immutable receipts, never hidden stock values or buyer budgets.
struct TradeNotebook {
    struct Page: Identifiable {
        let category: ItemCategory?
        let records: [TradeRecord]
        let invested: Money
        let proceeds: Money
        let net: Money
        var id: String { category?.rawValue ?? "other" }
        var profitable: Int { records.filter { $0.netProfit > .zero }.count }
        var losses: Int { records.filter { $0.netProfit < .zero }.count }
        var even: Int { records.count - profitable - losses }
    }
    let pages: [Page]

    init(records: [TradeRecord], definitions: [ItemDefinition]) throws {
        let categories = Dictionary(uniqueKeysWithValues: definitions.map { ($0.id, $0.category) })
        // Recovery commissions/liquidation use different economics. Never use them
        // as evidence of ordinary resale performance; retain them in full history.
        let eligible = records.filter { $0.kind == .market || $0.kind == .client }
        let groups = Dictionary(grouping: eligible) { categories[$0.definitionID]?.rawValue ?? "other" }
        pages = try (ItemCategory.allCases.map(\.rawValue) + ["other"]).compactMap { key in
            guard let group = groups[key], !group.isEmpty else { return nil }
            let ordered = group.sorted { $0.soldAt == $1.soldAt ? $0.id.rawValue < $1.id.rawValue : $0.soldAt > $1.soldAt }
            let invested = try ordered.reduce(Money.zero) { try $0.adding($1.totalCost) }
            let proceeds = try ordered.reduce(Money.zero) { try $0.adding($1.soldFor) }
            return Page(category: ItemCategory(rawValue: key), records: ordered, invested: invested,
                        proceeds: proceeds, net: try proceeds.subtracting(invested))
        }
    }
}
