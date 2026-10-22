import Foundation

enum GameCurrency: String, Codable, CaseIterable, Sendable {
    case usd = "USD", tryLira = "TRY"
    /// Fictional, pinned game FX v1. Never a live exchange-rate promise.
    var basisPointsPerUSD: Int64 { self == .usd ? 10_000 : 400_000 }
}

enum MarketRegion: String, Codable, CaseIterable, Sendable {
    case unitedStates, turkey
    var currency: GameCurrency { self == .turkey ? .tryLira : .usd }
    func categoryBasisPoints(_ category: ItemCategory) -> Int64 {
        guard self == .turkey else { return 10_000 }
        switch category { case .gaming: return 12_000; case .cameras: return 13_500; case .retro: return 11_000 }
    }
    func supplyBasisPoints(_ category: ItemCategory) -> Int64 {
        self == .turkey && category == .retro ? 10_500 : 10_000
    }
}

struct MarketConfiguration: Codable, Equatable, Sendable {
    var version = 1
    let region: MarketRegion
    var currency: GameCurrency
    static let us = Self(region: .unitedStates, currency: .usd)
    static let turkey = Self(region: .turkey, currency: .tryLira)
    static func initial(locale: Locale) -> Self { locale.region?.identifier == "TR" ? .turkey : .us }
    func multiplier(for category: ItemCategory) -> Int64 {
        region.categoryBasisPoints(category) * region.supplyBasisPoints(category) / 10_000
    }
    func display(_ value: Money) throws -> Money { try value.scaled(byBasisPoints: currency.basisPointsPerUSD) }
    func canonical(_ value: Money) throws -> Money {
        let (scaled, overflow) = value.minorUnits.multipliedReportingOverflow(by: 10_000)
        guard !overflow else { throw MoneyError.overflow }
        return Money(minorUnits: scaled / currency.basisPointsPerUSD)
    }
    func validate() throws { guard version == 1 else { throw SaveError.invalidSave } }
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
