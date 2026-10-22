import Foundation

struct TradeRecord: Identifiable, Equatable {
    let id: ListingID
    let definitionID: String
    let acquiredFor: Money
    let inspectionCost: Money
    let repairCost: Money
    let soldFor: Money
    let soldAt: Date
    let totalCost: Money
    let netProfit: Money
    let kind: SaleKind

    init(listing: PlayerListing) throws {
        guard listing.status == .sold, let item = listing.itemSnapshot, let sale = listing.soldPrice, let date = listing.soldAt else { throw LedgerError.incompleteTrade }
        kind = listing.saleKind ?? .market
        id = listing.id; definitionID = item.definitionID
        acquiredFor = item.purchasePrice; inspectionCost = item.inspectionCost; repairCost = item.repairCost
        soldFor = sale; soldAt = date
        totalCost = try acquiredFor.adding(inspectionCost).adding(repairCost)
        netProfit = try sale.subtracting(totalCost)
    }
}

enum TradeLedger {
    /// Completed listings store immutable settlement facts. Totals are derived, avoiding two financial sources of truth.
    static func records(from state: GameSnapshot) throws -> [TradeRecord] {
        try state.playerListings.filter { $0.status == .sold }.map(TradeRecord.init).sorted { $0.soldAt > $1.soldAt }
    }
    static func totalProfit(_ records: [TradeRecord]) throws -> Money {
        try records.reduce(.zero) { try $0.adding($1.netProfit) }
    }
}
enum LedgerError: Error { case incompleteTrade }
