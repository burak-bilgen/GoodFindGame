#if DEBUG
import Foundation

extension GameStore {
    func debugReset() throws {
        try commit(GameSnapshot.fresh(definitions: definitions))
    }

    func debugAddCash() throws {
        var next = snapshot
        next.player.cash = try next.player.cash.adding(GameBalanceConfig.debugCashGrant)
        try commit(next)
    }

    func debugRegenerateMarket() throws {
        guard snapshot.generation < UInt64.max else { throw SaveError.invalidSave }
        var next = snapshot
        next.generation += 1
        let oldAvailable = Set(next.market.filter(\.available).map(\.id))
        for index in next.market.indices where next.market[index].available { next.market[index].available = false }
        for index in next.conversations.indices where oldAvailable.contains(next.conversations[index].listingID) {
            next.conversations[index].closed = true
            next.conversations[index].counterPrice = nil
            next.conversations[index].agreedPrice = nil
        }
        next.market += try ListingGenerator().generate(definitions: definitions, seed: next.generation, now: next.lastSimulationAt ?? .now, market: next)
        EventResolver(timing: timing).reconcile(&next)
        try commit(next)
    }

    func debugAdvanceTime(by seconds: TimeInterval) throws {
        guard seconds.isFinite, seconds > 0 else { throw EventQueueError.invalidTimestamp }
        let observedNow = Date.now
        let anchor = max(observedNow, snapshot.lastKnownWallClock ?? observedNow)
        try catchUp(now: anchor.addingTimeInterval(seconds), showSummary: true)
    }

    func debugForceSellerResponse(listingID: ListingID) throws {
        guard let listing = snapshot.market.first(where: { $0.id == listingID && $0.available }) else { throw TradingError.unavailable }
        var conversation = conversation(for: listing)
        conversation.closed = false
        conversation.agreedPrice = nil
        conversation.pendingReplyEventID = nil
        conversation.counterExpiresAt = nil
        conversation.counterPrice = min(listing.askingPrice, try listing.reservationPrice.scaled(byBasisPoints: 11_000))
        conversation.append("seller.counter.0", amount: conversation.counterPrice)
        try updateConversation(conversation)
    }

    func debugForceBuyerOffer() throws {
        guard let listing = snapshot.playerListings.first(where: { $0.status == .active }) else { throw TradingError.unavailable }
        var next = snapshot
        if let offer = listing.offers.last, [.pending, .countered].contains(offer.status) {
            next = try BuyerEngine().reject(listingID: listing.id, state: next)
        }
        next = try BuyerEngine().generateOffer(listingID: listing.id, state: next, definitions: definitions)
        EventResolver(timing: timing).reconcile(&next)
        try commit(next)
    }
}
#endif
