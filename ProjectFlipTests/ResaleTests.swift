import Foundation
import Testing
@testable import ProjectFlip

struct ResaleTests {
    static func inspectedState() throws -> GameSnapshot {
        let state = try PurchaseTests.agreedState()
        let purchased = try PurchaseEngine().buy(listingID: state.market[0].id, state: state, now: .distantPast)
        return try InspectionEngine().inspect(itemID: purchased.player.inventory[0].id, professionally: false, state: purchased)
    }

    @Test func preventDuplicateListingsAndKeepInterestCoherent() throws {
        let state = try Self.inspectedState()
        let definitions = try SeedContent.load().items
        let next = try ResaleEngine().create(itemID: state.player.inventory[0].id, askingPrice: Money(minorUnits: 250_000), state: state, definitions: definitions, now: .now)
        #expect(next.playerListings.count == 1)
        #expect(next.playerListings[0].views >= next.playerListings[0].favorites)
        #expect(throws: TradingError.self) { try ResaleEngine().create(itemID: state.player.inventory[0].id, askingPrice: Money(minorUnits: 250_000), state: next, definitions: definitions, now: .now) }
        #expect(try JSONDecoder().decode(GameSnapshot.self, from: JSONEncoder().encode(next)) == next)
    }
}
