import Foundation
import Testing
@testable import ProjectFlip

struct LedgerTests {
    @Test func fiveConsecutiveTradesSaveReloadAndReconcile() throws {
        let definitions = try SeedContent.load().items
        var state = try GameSnapshot.fresh(definitions: definitions)
        let initialCash = state.player.cash
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let repository = SaveRepository(url: root.appendingPathComponent("save.json"))
        for index in 0..<5 {
            let listing = state.market[index]
            state.conversations.append(try NegotiationEngine().offer(listing.askingPrice, modifier: .none, listing: listing, current: NegotiationState(listingID: listing.id, patience: listing.seller.patience)))
            state = try PurchaseEngine().buy(listingID: listing.id, state: state, now: .distantPast)
            state = try InspectionEngine().inspect(itemID: listing.item.id, professionally: index % 2 == 1, state: state)
            let value = try PricingEngine.fairValue(of: listing.item, definition: definitions[index])
            state = try ResaleEngine().create(itemID: listing.item.id, askingPrice: value, state: state, definitions: definitions, now: .distantPast)
            let resale = try #require(state.playerListings.last)
            state = try BuyerEngine().generateOffer(listingID: resale.id, state: state, definitions: definitions)
            state = try BuyerEngine().accept(listingID: resale.id, state: state, now: Date(timeIntervalSince1970: Double(index)))
            try repository.save(state)
            let reloaded = try repository.load()
            state = try #require(reloaded)
        }
        let records = try TradeLedger.records(from: state)
        #expect(records.count == 5)
        #expect(state.player.inventory.isEmpty)
        #expect(try TradeLedger.totalProfit(records) == state.player.cash.subtracting(initialCash))
        #expect(records.contains { $0.netProfit < .zero })
        #expect(records.contains { $0.netProfit > .zero })
    }

    @Test func includeEveryCostAndAllowLoss() throws {
        var state = try BuyerTests.offeredState()
        state.player.inventory[0].inspectionCost = Money(minorUnits: 30_000)
        state.player.inventory[0].repairCost = Money(minorUnits: 50_000)
        let sold = try BuyerEngine().accept(listingID: state.playerListings[0].id, state: state, now: .now)
        let records = try TradeLedger.records(from: sold)
        let record = try #require(records.first)
        #expect(record.inspectionCost == Money(minorUnits: 30_000))
        #expect(record.repairCost == Money(minorUnits: 50_000))
        #expect(try record.netProfit == record.soldFor.subtracting(record.acquiredFor).subtracting(record.inspectionCost).subtracting(record.repairCost))
        #expect(record.netProfit < .zero)
    }
}
