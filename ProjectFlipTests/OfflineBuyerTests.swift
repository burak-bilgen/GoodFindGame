import Foundation
import Testing
@testable import ProjectFlip

struct OfflineBuyerTests {
    @Test func backgroundSearchBudgetCannotDiscardAnotherListingsStillValidBookedOffer() throws {
        let now = Date(timeIntervalSince1970: 400_000)
        var state = try BuyerTests.offeredState()
        let firstItem = state.player.inventory[0]
        let secondItem = ItemInstance(id: ItemID("second-owned"), definitionID: firstItem.definitionID,
                                      condition: firstItem.condition, hiddenDefects: firstItem.hiddenDefects, inspected: true)
        let original = try #require(state.playerListings[0].offers.first)
        state.playerListings[0].offers = []
        state.playerListings[0].expiresAt = now.addingTimeInterval(2700)
        let noisyID = state.playerListings[0].id
        var promised = PlayerListing(id: ListingID("booked-offer"), itemID: secondItem.id,
                                     askingPrice: state.playerListings[0].askingPrice, createdAt: now, views: 0, favorites: 0)
        promised.expiresAt = now.addingTimeInterval(2700)
        state.playerListings.append(promised)
        state.player.inventory.append(secondItem)
        state.events = []
        state.lastKnownWallClock = now; state.lastSimulationAt = now
        let savedOffer = BuyerOffer(id: OfferID("saved-quote"), archetype: original.archetype,
                                   identityIndex: 7, willingness: original.willingness, amount: original.amount)
        try state.enqueue(.buyerInterest(listingID: noisyID), createdAt: now, resolveAt: now.addingTimeInterval(1))
        try state.enqueue(.buyerOffer(listingID: promised.id, expectedOfferCount: 0, offer: savedOffer,
                                     intent: "buyer.cautious", expiresAt: now.addingTimeInterval(200)), createdAt: now, resolveAt: now.addingTimeInterval(2))
        let timing = SimulationTiming(sellerReply: 0...0, shipping: 0, inspection: 0, buyerInterest: 30...30,
                                      offerLifetime: 1800, buyerArrivalsPerCatchUp: 1)
        let resolver = EventResolver(timing: timing)
        let loaded = try JSONDecoder().decode(GameSnapshot.self, from: JSONEncoder().encode(state))
        let result = try resolver.resolve(loaded, now: now.addingTimeInterval(3), definitions: SeedContent.load().items).state
        #expect(result.playerListings[1].offers == [savedOffer])
        #expect(result.needsBuyerAction(result.playerListings[1]))
        #expect(result.player.cash == state.player.cash && result.player.inventory == state.player.inventory)
        #expect(try resolver.resolve(result, now: now.addingTimeInterval(3), definitions: SeedContent.load().items).state == result)
    }
}
