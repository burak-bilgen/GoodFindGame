import Foundation
import Testing
@testable import ProjectFlip

struct ShopTests {
    private func starter() throws -> GameSnapshot {
        var state = try BuyerTests.offeredState()
        for index in 0..<3 {
            var sale = state.playerListings[0]
            sale = PlayerListing(id: ListingID("history-\(index)"), itemID: ItemID("history-item-\(index)"), askingPrice: Money(minorUnits: 1_000), createdAt: .distantPast, status: .sold, views: 0, favorites: 0)
            state.playerListings.append(sale)
        }
        return state
    }
    @Test func openingUsesRealCapitalAndAudienceRequiresMatchingWindowStock() throws {
        let definitions = try SeedContent.load().items
        let original = try starter()
        var shop = try ShopEngine.open(name: "  Second Chapter  ", style: .bargains, state: original)
        #expect(shop.shop.name == "Second Chapter")
        #expect(try shop.player.cash == original.player.cash.subtracting(ShopEngine.openingCost))
        let id = shop.playerListings[0].id
        shop.playerListings[0].askingPrice = Money(minorUnits: 1_000)
        #expect(ShopEngine.audience(for: shop.playerListings[0], state: shop, definitions: definitions) == nil)
        shop = try ShopEngine.toggle(id, state: shop, definitions: definitions)
        let audience = try #require(ShopEngine.audience(for: shop.playerListings[0], state: shop, definitions: definitions))
        let windowBudget = audience.reduce(Int64(0)) { $0 + $1.valueBasisPoints } / Int64(audience.count)
        let marketBudget = BuyerArchetype.marketAudience.reduce(Int64(0)) { $0 + $1.valueBasisPoints } / Int64(BuyerArchetype.marketAudience.count)
        #expect(windowBudget >= marketBudget, "Paying for a matching shop window must not replace ordinary buyers with mostly reseller lowballs")
        #expect(throws: TradingError.self) { try ShopEngine.changeStyle(.tested, state: shop) }
        let held = shop.playerListings[0].offers
        shop = try ShopEngine.toggle(id, state: shop, definitions: definitions)
        shop = try ShopEngine.changeStyle(.tested, state: shop)
        #expect(shop.playerListings[0].offers == held)
        #expect(!ShopEngine.fits(shop.playerListings[0], state: shop, definitions: definitions))
        try ShopEngine.validate(shop)
    }
    @Test func windowSaleFreesSpaceAndGrowthIsPaidAndSaved() throws {
        let definitions = try SeedContent.load().items
        var state = try ShopEngine.open(name: "Test shop", style: .bargains, state: starter())
        let id = state.playerListings[0].id
        state.playerListings[0].askingPrice = Money(minorUnits: 1_000)
        state = try ShopEngine.toggle(id, state: state, definitions: definitions)
        state = try BuyerEngine().accept(listingID: id, state: state, now: .now)
        #expect(state.shop.featured.isEmpty)
        #expect(state.shop.completedSales == [id])
        #expect(throws: TradingError.self) { try ShopEngine.expand(state: state) }
        state.shop.completedSales.insert(state.playerListings[1].id)
        let cash = state.player.cash
        state = try ShopEngine.expand(state: state)
        #expect(state.shop.capacity == 2)
        #expect(try state.player.cash == cash.subtracting(Money(minorUnits: 20_000)))
        try ShopEngine.validate(state)
        let decoded = try JSONDecoder().decode(GameSnapshot.self, from: JSONEncoder().encode(state))
        #expect(decoded.shop == state.shop)
        var invalid = state; invalid.shop.windowLevel = Int.max
        #expect(throws: SaveError.self) { try ShopEngine.validate(invalid) }
    }
}
