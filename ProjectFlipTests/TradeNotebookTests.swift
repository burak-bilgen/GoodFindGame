import Foundation
import Testing
@testable import ProjectFlip

struct TradeNotebookTests {
    private func receipt(_ id: String, definition: String = "gaming-0", kind: SaleKind = .market,
                         purchase: Int64 = 1000, inspection: Int64 = 200, repair: Int64 = 300, sale: Int64, date: TimeInterval = 100) throws -> TradeRecord {
        var item = ItemInstance(id: ItemID(id), definitionID: definition, condition: 80, hiddenDefects: [])
        item.purchasePrice = Money(minorUnits: purchase)
        item.inspectionCost = Money(minorUnits: inspection)
        item.repairCost = Money(minorUnits: repair)
        var listing = PlayerListing(id: ListingID(id), itemID: item.id, askingPrice: Money(minorUnits: sale), createdAt: .distantPast, views: 1, favorites: 0)
        listing.status = .sold; listing.itemSnapshot = item; listing.soldPrice = listing.askingPrice
        listing.soldAt = Date(timeIntervalSince1970: date); listing.saleKind = kind
        return try TradeRecord(listing: listing)
    }

    @Test func notebookIncludesAllCostsAndSeparatesRecoveryFromTrading() throws {
        let definitions = try SeedContent.load().items
        let model = definitions[0].id
        let records = try [receipt("win", definition: model, sale: 2000), receipt("loss", definition: model, sale: 1000),
                           receipt("even", definition: model, kind: .client, sale: 1500),
                           receipt("job", definition: model, kind: .consignment, purchase: 0, inspection: 0, repair: 0, sale: 1500),
                           receipt("clearance", definition: model, kind: .liquidation, sale: 500)]
        let notebook = try TradeNotebook(records: records, definitions: definitions)
        let page = try #require(notebook.pages.first)
        #expect(page.records.count == 3)
        #expect(page.profitable == 1 && page.losses == 1 && page.even == 1)
        #expect(page.invested.minorUnits == 4500 && page.proceeds.minorUnits == 4500 && page.net == .zero)
        #expect(page.records.map(\.id.rawValue) == ["even", "loss", "win"])
        #expect(records.count == 5) // The complete ledger is never edited.
    }

    @Test func missingOldCatalogModelsAreRetainedWithoutGuessingTheirCategory() throws {
        let unknown = try receipt("old-model", definition: "retired-unknown", sale: 1000)
        let page = try #require(TradeNotebook(records: [unknown], definitions: []).pages.first)
        #expect(page.category == nil && page.records == [unknown])
        #expect(page.net.minorUnits == -500)
        #expect(try TradeNotebook(records: [], definitions: []).pages.isEmpty)
    }

    @Test func overflowIsReportedRatherThanDisplayingAFalseProfit() throws {
        let first = try receipt("one", purchase: 0, inspection: 0, repair: 0, sale: Int64.max)
        let second = try receipt("two", purchase: 0, inspection: 0, repair: 0, sale: 1)
        #expect(throws: MoneyError.self) { try TradeNotebook(records: [first, second], definitions: []) }
    }

    @Test func pricingMemoryUsesLatestSameModelMarketSaleAndExcludesOtherSaleKinds() throws {
        let old = try receipt("old", sale: 1700, date: 10)
        let recent = try receipt("recent", sale: 1800, date: 20)
        let client = try receipt("client", kind: .client, sale: 4000, date: 30)
        let clearance = try receipt("clearance", kind: .liquidation, sale: 500, date: 40)
        let other = try receipt("other", definition: "gaming-1", sale: 9000, date: 50)
        let records = [client, other, old, clearance, recent]
        #expect(TradeLedger.latestMarketSale(for: "gaming-0", in: records) == recent)
        #expect(TradeLedger.latestMarketSale(for: "never-sold", in: records) == nil)
        #expect(records.count == 5)
    }

}
