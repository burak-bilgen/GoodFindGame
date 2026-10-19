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

    func formatted(locale: Locale) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .currency
        // Stable neutral credits globally until regional economy tables exist.
        formatter.currencyCode = locale.language.languageCode?.identifier == "tr" ? "TRY" : "XXX"
        formatter.currencySymbol = locale.language.languageCode?.identifier == "tr" ? "₺" : "¤"
        return formatter.string(from: NSDecimalNumber(decimal: Decimal(minorUnits) / 100)) ?? NSDecimalNumber(value: minorUnits).stringValue
    }
}

enum MoneyError: Error { case overflow }
