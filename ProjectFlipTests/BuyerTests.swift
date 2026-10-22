import Foundation
import Testing
@testable import ProjectFlip

struct BuyerTests {
    static func offeredState() throws -> GameSnapshot {
        let state = try ResaleTests.inspectedState()
        let definitions = try SeedContent.load().items
        let listed = try ResaleEngine().create(itemID: state.player.inventory[0].id, askingPrice: Money(minorUnits: 6_000), state: state, definitions: definitions, now: .distantPast)
        return try BuyerEngine().generateOffer(listingID: listed.playerListings[0].id, state: listed, definitions: definitions)
    }

    @Test func saleSettlesExactlyOnceAndPreservesCosts() throws {
        let state = try Self.offeredState()
        let id = state.playerListings[0].id
        let amount = try #require(state.playerListings[0].offers.last?.amount)
        let sold = try BuyerEngine().accept(listingID: id, state: state, now: .distantPast)
        #expect(sold.player.inventory.isEmpty)
        #expect(try sold.player.cash == state.player.cash.adding(amount))
        #expect(sold.playerListings[0].itemSnapshot?.purchasePrice == state.player.inventory[0].purchasePrice)
        #expect(throws: TradingError.self) { try BuyerEngine().accept(listingID: id, state: sold, now: .now) }
        #expect(throws: TradingError.self) { try BuyerEngine().generateOffer(listingID: id, state: sold, definitions: SeedContent.load().items) }
    }

    @Test func counterAndRejectionFollowBudget() throws {
        let state = try Self.offeredState()
        let id = state.playerListings[0].id
        let offer = try #require(state.playerListings[0].offers.last)
        let sold = try BuyerEngine().counter(listingID: id, amount: offer.willingness, state: state, now: .now)
        #expect(sold.playerListings[0].status == .sold)
        let rejected = try BuyerEngine().reject(listingID: id, state: state)
        #expect(rejected.player.inventory.count == 1)
        #expect(rejected.player.cash == state.player.cash)
        let withdrawn = try BuyerEngine().counter(listingID: id, amount: offer.willingness.scaled(byBasisPoints: 20_000), state: state, now: .now)
        #expect(withdrawn.playerListings[0].offers.last?.status == .withdrawn)
    }
    @Test func rejectingEveryArchetypeDoesNotPermanentlyLockInventory() throws {
        var state = try Self.offeredState()
        let originalCash = state.player.cash
        let id = state.playerListings[0].id
        let definitions = try SeedContent.load().items
        for _ in 0..<8 {
            state = try BuyerEngine().reject(listingID: id, state: state)
            state = try BuyerEngine().generateOffer(listingID: id, state: state, definitions: definitions)
        }
        #expect(state.playerListings[0].offers.last?.status == .pending)
        #expect(state.player.cash == originalCash)
        #expect(state.player.inventory.count == 1)
    }

}
