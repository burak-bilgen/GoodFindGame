import Foundation
import Testing
@testable import ProjectFlip

struct RepricingTests {
    private func liveOffer() throws -> GameSnapshot {
        var state = try BuyerTests.offeredState()
        let now = Date(timeIntervalSince1970: 80_000)
        state.lastKnownWallClock = now; state.lastSimulationAt = now
        state.playerListings[0].expiresAt = now.addingTimeInterval(2_700)
        let listing = state.playerListings[0]
        let offer = try #require(listing.offers.last)
        try state.enqueue(.buyerReply(listingID: listing.id, offerID: offer.id, amount: offer.amount, expectedAttempts: 0), createdAt: now, resolveAt: now.addingTimeInterval(20))
        return state
    }

    @Test func savingTheSamePricePreservesTheBuyerAndPendingReply() throws {
        let state = try liveOffer(), listing = state.playerListings[0]
        #expect(try BuyerEngine().changePrice(listingID: listing.id, amount: listing.askingPrice, state: state) == state)
        #expect(try SimulationActions(timing: .production).changePrice(listingID: listing.id, amount: listing.askingPrice, state: state, definitions: SeedContent.load().items, now: Date(timeIntervalSince1970: 80_005)) == state)
    }

    @Test func unchangedPriceCannotRerollScheduledInterestOrExtendTheListing() throws {
        let definitions = try SeedContent.load().items
        let original = try ResaleTests.inspectedState()
        let now = Date(timeIntervalSince1970: 80_000)
        let actions = SimulationActions(timing: .production)
        let state = try actions.publish(itemID: original.player.inventory[0].id, askingPrice: Money(minorUnits: 4_000), state: original, definitions: definitions, now: now)
        let listing = state.playerListings[0]
        var replay = try JSONDecoder().decode(GameSnapshot.self, from: JSONEncoder().encode(state))
        for second in 1...10 { replay = try actions.changePrice(listingID: listing.id, amount: listing.askingPrice, state: replay, definitions: definitions, now: now.addingTimeInterval(Double(second))) }
        #expect(replay == state)
    }

    @Test func anActualEditRecordsTheNewPriceAndRetiresTheOldNegotiationOnlyOnce() throws {
        let state = try liveOffer(), listing = state.playerListings[0]
        let definitions = try SeedContent.load().items
        let actions = SimulationActions(timing: .production)
        let next = try actions.changePrice(listingID: listing.id, amount: Money(minorUnits: 4_000), state: state, definitions: definitions, now: Date(timeIntervalSince1970: 80_005))
        #expect(next.playerListings[0].offers.last?.status == .withdrawn)
        #expect(!next.hasBuyerReply(for: listing.id))
        #expect(next.playerListings[0].expiresAt == listing.expiresAt)
        #expect(next.playerListings[0].messages.last?.intent == "player.changedPrice")
        #expect(next.playerListings[0].messages.last?.amount == Money(minorUnits: 4_000))
        #expect(next.player.cash == state.player.cash && next.player.inventory == state.player.inventory)
        #expect(try actions.changePrice(listingID: listing.id, amount: Money(minorUnits: 4_000), state: next, definitions: definitions, now: Date(timeIntervalSince1970: 80_006)) == next)
    }
}
