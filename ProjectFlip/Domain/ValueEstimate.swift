import Foundation

/// A player's uncertain appraisal, never a hidden-fault-aware deal rating.
struct ValueEstimate: Equatable {
    let lower: Money
    let upper: Money
    var midpoint: Money { Money(minorUnits: lower.minorUnits + (upper.minorUnits - lower.minorUnits) / 2) }

    init(item: ItemInstance, definition: ItemDefinition, knowledge: InspectionKnowledge, marketBasisPoints: Int64 = 10_000) throws {
        let center = try InspectionEngine().estimatedValue(item: item, definition: definition, marketBasisPoints: marketBasisPoints)
        let spread = max(500, 2_500 - knowledge.level(in: definition.category) * 500 - (item.professionallyInspected ? 700 : 0))
        try self.init(center: center, spread: Int64(spread))
    }

    init(center: Money, spread: Int64) throws {
        let low = try center.scaled(byBasisPoints: max(0, 10_000 - spread))
        let high = try center.scaled(byBasisPoints: 10_000 + spread)
        // Round outward to 50 economy units, not misleading cent-level precision.
        let step: Int64 = 500
        lower = Money(minorUnits: max(100, low.minorUnits / step * step))
        upper = Money(minorUnits: max(lower.minorUnits + step, ((high.minorUnits + step - 1) / step) * step))
    }

    func formatted(locale: Locale, market: MarketConfiguration = .us) -> String { "\(lower.formatted(locale: locale, market: market)) – \(upper.formatted(locale: locale, market: market))" }
}
