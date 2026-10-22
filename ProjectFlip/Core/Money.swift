import Foundation

/// One economy unit has 100 minor units. Canonical USD cents; regional pricing and display conversion are independent.
struct Money: Codable, Hashable, Comparable, Sendable {
    let minorUnits: Int64
    static let zero = Money(minorUnits: 0)

    init(minorUnits: Int64) { self.minorUnits = minorUnits }

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.minorUnits < rhs.minorUnits }

    func adding(_ other: Self) throws -> Self {
        let (value, overflow) = minorUnits.addingReportingOverflow(other.minorUnits)
        guard !overflow else { throw MoneyError.overflow }
        return Money(minorUnits: value)
    }

    func subtracting(_ other: Self) throws -> Self {
        let (value, overflow) = minorUnits.subtractingReportingOverflow(other.minorUnits)
        guard !overflow else { throw MoneyError.overflow }
        return Money(minorUnits: value)
    }

    /// Integer basis points, rounded toward zero. No floating-point currency arithmetic.
    func scaled(byBasisPoints factor: Int64) throws -> Self {
        let (product, overflow) = minorUnits.multipliedReportingOverflow(by: factor)
        guard !overflow else { throw MoneyError.overflow }
        return Money(minorUnits: product / 10_000)
    }

    func formatted(locale: Locale, market: MarketConfiguration = .us, signed: Bool = false, precise: Bool = false) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .currency
        formatter.currencyCode = market.currency.rawValue
        formatter.roundingMode = .halfUp
        formatter.minimumFractionDigits = precise ? 2 : 0
        formatter.maximumFractionDigits = precise ? 2 : 0
        if signed && minorUnits > 0 { formatter.positivePrefix = "+" + formatter.positivePrefix }
        guard let display = try? market.display(self) else { return "—" }
        return formatter.string(from: NSDecimalNumber(decimal: Decimal(display.minorUnits) / 100)) ?? "—"
    }
}

enum MoneyError: Error { case overflow }

extension Money {
    static func parse(_ text: String, locale: Locale, market: MarketConfiguration = .us) throws -> Self {
        let separator = locale.decimalSeparator ?? "."
        let pieces = text.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: separator)
        guard pieces.count <= 2, let wholeText = pieces.first, !wholeText.isEmpty,
              pieces.allSatisfy({ $0.allSatisfy({ $0.isASCII && $0.isNumber }) }),
              let whole = Int64(wholeText), whole >= 0 else { throw TradingError.invalidAmount }
        let fraction = pieces.count == 2 ? pieces[1] : ""
        guard fraction.count <= 2, pieces.count == 1 || !fraction.isEmpty else { throw TradingError.invalidAmount }
        let minor = fraction.isEmpty ? 0 : (Int64(fraction) ?? 0) * (fraction.count == 1 ? 10 : 1)
        let (units, overflow) = whole.multipliedReportingOverflow(by: 100)
        let (value, extraOverflow) = units.addingReportingOverflow(minor)
        guard !overflow, !extraOverflow, value > 0, value <= GameBalanceConfig.current.maximumTransactionAmount.minorUnits else { throw TradingError.invalidAmount }
        let canonical = try market.canonical(Self(minorUnits: value))
        guard canonical > .zero else { throw TradingError.invalidAmount }
        return canonical
    }

    func inputText(locale: Locale, market: MarketConfiguration = .us) -> String {
        guard let display = try? market.display(self) else { return "" }
        let fraction = display.minorUnits % 100
        return "\(display.minorUnits / 100)\(locale.decimalSeparator ?? ".")\(fraction < 10 ? "0" : "")\(fraction)"
    }
}
