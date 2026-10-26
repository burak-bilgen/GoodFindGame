import Foundation
import Testing
@testable import ProjectFlip

struct TradePriorityTests {
    let now = Date(timeIntervalSince1970: 100_000)
    @Test func urgentBuyerBeatsNewerActivityAndStaleTimersAreIgnored() throws {
        var state = try BuyerTests.offeredState()
        let base = state.playerListings[0]
        var urgent = PlayerListing(id: ListingID("urgent"), itemID: base.itemID, askingPrice: base.askingPrice, createdAt: now, views: 1, favorites: 0)
        urgent.offers = base.offers; urgent.lastActivityAt = now
        var fresh = PlayerListing(id: ListingID("fresh"), itemID: base.itemID, askingPrice: base.askingPrice, createdAt: now, views: 1, favorites: 0)
        fresh.offers = base.offers; fresh.lastActivityAt = now.addingTimeInterval(10)
        state.playerListings = [fresh, urgent]
        let offer = try #require(base.offers.last)
        try state.enqueue(.buyerOfferExpired(listingID: urgent.id, offerID: offer.id), createdAt: now, resolveAt: now.addingTimeInterval(20))
        try state.enqueue(.buyerOfferExpired(listingID: fresh.id, offerID: offer.id), createdAt: now, resolveAt: now.addingTimeInterval(60))
        try state.enqueue(.buyerOfferExpired(listingID: fresh.id, offerID: OfferID("old-offer")), createdAt: now, resolveAt: now.addingTimeInterval(1))
        #expect(state.activeSales.map(\.id) == [urgent.id, fresh.id])
        // A buyer considering our counter is not an action waiting on the player.
        try state.enqueue(.buyerReply(listingID: urgent.id, offerID: offer.id, amount: offer.amount, expectedAttempts: 0), createdAt: now, resolveAt: now.addingTimeInterval(2))
        #expect(state.activeSales.first?.id == fresh.id)
    }

    @Test func readySellerUsesExpiryAndUnavailableOrPendingTalksAreExcluded() throws {
        var state = try BuyerTests.offeredState()
        let listings = Array(state.market.filter(\.available).prefix(3))
        #expect(listings.count == 3)
        var later = NegotiationState(listingID: listings[0].id, patience: 100)
        later.counterPrice = listings[0].askingPrice; later.counterExpiresAt = now.addingTimeInterval(90)
        var sooner = NegotiationState(listingID: listings[1].id, patience: 100)
        sooner.agreedPrice = listings[1].askingPrice; sooner.counterExpiresAt = now.addingTimeInterval(20)
        var pending = NegotiationState(listingID: listings[2].id, patience: 100)
        pending.counterPrice = listings[2].askingPrice; pending.counterExpiresAt = now
        pending.pendingReplyEventID = "waiting"
        state.conversations = [later, pending, sooner]
        #expect(state.readySellerConversations.map(\.id) == [sooner.id, later.id])
        let index = try #require(state.market.firstIndex { $0.id == sooner.id })
        state.market[index].available = false
        #expect(state.readySellerConversations.map(\.id) == [later.id])
    }

    @Test func buyerFacesVaryAcrossRepeatedSalesWithoutChangingExistingOffersOnReload() throws {
        var state = try BuyerTests.offeredState()
        let id = state.playerListings[0].id
        let definitions = try SeedContent.load().items
        #expect(state.playerListings[0].offers[0].identityIndex == 3)
        for _ in 0..<40 {
            state = try BuyerEngine().reject(listingID: id, state: state)
            state = try BuyerEngine().generateOffer(listingID: id, state: state, definitions: definitions)
        }
        let offers = state.playerListings[0].offers
        #expect(Set(offers.map(\.identityIndex)).count >= 6)
        let loaded = try JSONDecoder().decode(GameSnapshot.self, from: JSONEncoder().encode(state))
        #expect(loaded.playerListings[0].offers == offers)
    }

    @Test func quietPriceReviewUsesObservedTrafficAndTimeWithoutTouchingAnOffer() throws {
        var listing = try BuyerTests.offeredState().playerListings[0]
        listing.offers = []; listing.views = 12
        #expect(!listing.canReviewQuietPrice(at: listing.createdAt.addingTimeInterval(119)))
        #expect(listing.canReviewQuietPrice(at: listing.createdAt.addingTimeInterval(120)))
        listing.views = 11
        #expect(!listing.canReviewQuietPrice(at: listing.createdAt.addingTimeInterval(120)))
        listing.views = 12
        listing.offers = try BuyerTests.offeredState().playerListings[0].offers
        #expect(!listing.canReviewQuietPrice(at: listing.createdAt.addingTimeInterval(120)))
        listing.offers = []; listing.status = .expired
        #expect(!listing.canReviewQuietPrice(at: listing.createdAt.addingTimeInterval(120)))
    }

}
