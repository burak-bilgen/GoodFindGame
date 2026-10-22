import Foundation

enum GameCurrency: String, Codable, CaseIterable, Sendable {
    case usd = "USD", tryLira = "TRY"
    /// Fictional, pinned game FX v1. Never a live exchange-rate promise.
    var basisPointsPerUSD: Int64 { self == .usd ? 10_000 : 400_000 }
}

/// Legacy save tag only. All current games use one shared market.
enum MarketRegion: String, Codable, CaseIterable, Sendable { case unitedStates, turkey }

struct MarketConfiguration: Codable, Equatable, Sendable {
    var version = 2
    let region: MarketRegion
    var currency: GameCurrency
    static let us = Self(region: .unitedStates, currency: .usd)
    // Compatibility spelling for callers; this selects TRY presentation, not a second economy.
    static let turkey = Self(region: .unitedStates, currency: .tryLira)
    static func initial(locale: Locale) -> Self { locale.language.languageCode?.identifier == "tr" ? .turkey : .us }
    func multiplier(for category: ItemCategory) -> Int64 {
        10_000 // Locale, display currency and the legacy region tag never reprice goods.
    }
    func display(_ value: Money) throws -> Money { try value.scaled(byBasisPoints: currency.basisPointsPerUSD) }
    func canonical(_ value: Money) throws -> Money {
        let (scaled, overflow) = value.minorUnits.multipliedReportingOverflow(by: 10_000)
        guard !overflow else { throw MoneyError.overflow }
        return Money(minorUnits: scaled / currency.basisPointsPerUSD)
    }
    func validate() throws { guard version == 2, region == .unitedStates else { throw SaveError.invalidSave } }
}

enum ValueTier: String, Codable, CaseIterable, Sendable {
    case budget, mainstream, enthusiast, premium, collector, rare, legendary
    var dollars: ClosedRange<Int64> {
        switch self {
        case .budget: 15...150
        case .mainstream: 80...400
        case .enthusiast: 200...900
        case .premium: 600...2_200
        case .collector: 100...3_000
        case .rare: 1_000...15_000
        case .legendary: 5_000...100_000
        }
    }
    func contains(_ value: Money) -> Bool { dollars.contains(value.minorUnits / 100) }
}
