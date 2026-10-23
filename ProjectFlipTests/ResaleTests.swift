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


extension ResaleTests {
    @Test func aPaidPendingReportCannotBeLostByListingOrBookingServiceOnALiveSale() throws {
        let definitions = try SeedContent.load().items
        let now = Date(timeIntervalSince1970: 100_000)
        let original = try Self.inspectedState()
        let item = try #require(original.player.inventory.first)
        let booked = try SimulationActions(timing: .production).inspect(itemID: item.id, professionally: true, state: original, now: now, definitions: definitions)
        #expect(throws: TradingError.inspectionPending) {
            try ResaleEngine().create(itemID: item.id, askingPrice: Money(minorUnits: 6_000), state: booked, definitions: definitions, now: now)
        }
        let listed = try ResaleEngine().create(itemID: item.id, askingPrice: Money(minorUnits: 6_000), state: original, definitions: definitions, now: now)
        #expect(throws: TradingError.itemListed) { try InspectionEngine().chargeProfessional(itemID: item.id, state: listed) }
        let complete = try EventResolver(timing: .production).resolve(booked, now: now.addingTimeInterval(10), definitions: definitions).state
        let ready = try ResaleEngine().create(itemID: item.id, askingPrice: Money(minorUnits: 6_000), state: complete, definitions: definitions, now: now.addingTimeInterval(10))
        #expect(ready.playerListings.count == 1)
        #expect(ready.player.cash == booked.player.cash)
        #expect(ready.player.inventory[0].professionallyInspected)
    }
}
