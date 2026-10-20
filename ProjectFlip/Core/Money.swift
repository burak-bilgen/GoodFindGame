import Foundation

/// One economy unit has 100 minor units. Currency display does not convert value.
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

    func formatted(locale: Locale, signed: Bool = false) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .currency
        // Stable neutral credits globally until regional economy tables exist.
        formatter.currencyCode = locale.language.languageCode?.identifier == "tr" ? "TRY" : "XXX"
        formatter.currencySymbol = locale.language.languageCode?.identifier == "tr" ? "₺" : "¤"
        if signed && minorUnits > 0 { formatter.positivePrefix = "+" + formatter.positivePrefix }
        return formatter.string(from: NSDecimalNumber(decimal: Decimal(minorUnits) / 100)) ?? NSDecimalNumber(value: minorUnits).stringValue
    }
}

enum MoneyError: Error { case overflow }

extension Money {
    static func parse(_ text: String, locale: Locale) throws -> Self {
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
        return Self(minorUnits: value)
    }

    func inputText(locale: Locale) -> String {
        let fraction = minorUnits % 100
        return "\(minorUnits / 100)\(locale.decimalSeparator ?? ".")\(fraction < 10 ? "0" : "")\(fraction)"
    }
}
