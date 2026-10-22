import Foundation

extension MarketTrendScope {
    func displayName(definitions: [ItemDefinition], locale: Locale) -> String {
        switch self {
        case .category(let category): GameText.string("category.\(category.rawValue)", locale: locale)
        case .model(let id): definitions.first { $0.id == id }?.displayName(locale: locale) ?? GameText.string("trend.scopeUnavailable", locale: locale)
        }
    }
}

extension MarketTrend {
    func formattedChange(locale: Locale) -> String {
        (Decimal(changeBasisPoints) / 10_000).formatted(.percent.locale(locale).precision(.fractionLength(0...2)).sign(strategy: .always()))
    }
}
