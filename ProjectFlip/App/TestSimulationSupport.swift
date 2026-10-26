#if DEBUG
// Internal isolated-test support. No player-facing developer screen or controls.
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
        next.market += try ListingGenerator().generate(definitions: MarketCatalog.starterFeed(from: definitions), seed: next.generation, now: next.lastSimulationAt ?? .now, market: next)
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
extension GameStore {
    /// Isolated UI tests only; uses the real purchase, inspection and settlement engines.
    func debugSeedCompetitionOnboarding() throws {
        var next = snapshot
        let now = Date.now
        for listing in Array(next.market.prefix(3)) {
            var agreement = NegotiationState(listingID: listing.id, patience: 100)
            agreement.agreedPrice = listing.askingPrice
            next.conversations.append(agreement)
            next = try PurchaseEngine().buy(listingID: listing.id, state: next, now: now)
            next = try InspectionEngine().inspect(itemID: listing.item.id, professionally: false, state: next)
            next = try ResaleEngine().create(itemID: listing.item.id, askingPrice: listing.askingPrice, state: next, definitions: definitions, now: now)
            guard let id = next.playerListings.last?.id else { throw TradingError.unavailable }
            next = try BuyerEngine().generateOffer(listingID: id, state: next, definitions: definitions)
            next = try BuyerEngine().accept(listingID: id, state: next, now: now)
        }
        try commit(next)
    }
}
#endif

#if DEBUG
extension GameStore {
    /// Isolated UI scenario: real settled receipts, a repeat-model purchase, and
    /// genuine queued traffic on an overpriced listing. No invented offer/count.
    func debugSeedQuietSale() throws {
        try debugSeedCompetitionOnboarding()
        let now = Date.now
        let began = now.addingTimeInterval(-1800)
        guard let definition = definitions.first(where: { $0.id == "gaming-0" }) else { throw TradingError.unavailable }
        var next = snapshot
        let listing = try ListingGenerator().generate(definitions: [definition], seed: 9001, now: began, starterFriendly: false)[0]
        next.market.append(listing)
        var agreement = NegotiationState(listingID: listing.id, patience: 100)
        agreement.agreedPrice = listing.askingPrice
        next.conversations.append(agreement)
        next = try PurchaseEngine().buy(listingID: listing.id, state: next, now: began)
        next = try InspectionEngine().inspect(itemID: listing.item.id, professionally: false, state: next)
        next = try ResaleEngine().create(itemID: listing.item.id, askingPrice: Money(minorUnits: 1_000_000), state: next, definitions: definitions, now: began)
        guard let id = next.playerListings.last?.id else { throw TradingError.unavailable }
        next.lastKnownWallClock = began; next.lastSimulationAt = began
        let resolver = EventResolver(timing: .production)
        try resolver.scheduleBuyer(listingID: id, state: &next, definitions: definitions, now: began)
        next = try resolver.resolve(next, now: now, definitions: definitions).state
        try commit(next)
    }
}
#endif
