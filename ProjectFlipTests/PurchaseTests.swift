import Foundation
import Testing
@testable import ProjectFlip

struct PurchaseTests {
    static func agreedState() throws -> GameSnapshot {
        var state = try GameSnapshot.fresh(definitions: SeedContent.load().items)
        let listing = state.market[0]
        state.conversations = [try NegotiationEngine().offer(listing.askingPrice, modifier: .none, listing: listing, current: NegotiationState(listingID: listing.id, patience: listing.seller.patience), reputation: 50)]
        return state
    }

    @Test func purchasePreservesTruthAndCannotRepeat() throws {
        let state = try Self.agreedState()
        let next = try PurchaseEngine().buy(listingID: state.market[0].id, state: state, now: .distantPast)
        #expect(next.player.inventory.count == 1)
        #expect(next.player.inventory[0].hiddenDefects == state.market[0].item.hiddenDefects)
        #expect(try next.player.cash == state.player.cash.subtracting(state.market[0].askingPrice))
        #expect(throws: TradingError.self) { try PurchaseEngine().buy(listingID: state.market[0].id, state: next, now: .now) }
    }

    @Test func insufficientFundsAndCapacityCannotMutateState() throws {
        var state = try Self.agreedState()
        state.player.cash = .zero
        #expect(throws: TradingError.self) { try PurchaseEngine().buy(listingID: state.market[0].id, state: state, now: .now) }
        #expect(state.player.inventory.isEmpty)
        state.player.cash = Money(minorUnits: 2_000_000)
        state.player.inventoryCapacity = 0
        #expect(throws: TradingError.self) { try PurchaseEngine().buy(listingID: state.market[0].id, state: state, now: .now) }
    }
}
