/// Phase A uses immediate interactions. Phase B will add debug/production event timings here.
struct GameBalanceConfig: Sendable {
    let startingCash: Money
    let inventorySlots: Int
    let professionalInspectionCost: Money
    let marketSeed: UInt64
    let maximumTransactionAmount: Money

    static let production = Self(startingCash: Money(minorUnits: 2_000_000), inventorySlots: 8, professionalInspectionCost: Money(minorUnits: 15_000), marketSeed: 42, maximumTransactionAmount: Money(minorUnits: 1_000_000_000_000))
    static let debug = production
    #if DEBUG
    static let debugCashGrant = Money(minorUnits: 5_000_000)
    #endif
    static var current: Self {
        #if DEBUG
        debug
        #else
        production
        #endif
    }
}
