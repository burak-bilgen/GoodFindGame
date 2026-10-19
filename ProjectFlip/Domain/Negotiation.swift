import Foundation

struct DialogueMessage: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let intent: String
    let fromPlayer: Bool
    var amount: Money?
    var defect: Defect?
}

struct NegotiationState: Codable, Identifiable, Equatable, Sendable {
    var id: ListingID { listingID }
    let listingID: ListingID
    var offers: [Offer] = []
    var messages: [DialogueMessage] = []
    var patience: Int
    var askedAboutIssues = false
    var knownDefects: [Defect] = []
    var counterPrice: Money?
    var agreedPrice: Money?
    var closed = false
    var pendingReplyEventID: String?
    var counterExpiresAt: Date?

    mutating func append(_ intent: String, player: Bool = false, amount: Money? = nil, defect: Defect? = nil) {
        messages.append(DialogueMessage(id: "\(listingID.rawValue)-\(messages.count)", intent: intent, fromPlayer: player, amount: amount, defect: defect))
    }
}

enum OfferModifier: String, Codable, CaseIterable {
    case none, buyToday, knownIssues
    var key: String { "modifier.\(rawValue)" }
}

enum TradingError: String, Error {
    case invalidAmount, unavailable, closed, insufficientCash, inventoryFull, inspectFirst, alreadyDone
    var key: String { "error.\(rawValue)" }
}

struct NegotiationEngine {
    func offer(_ amount: Money, modifier: OfferModifier, listing: MarketplaceListing, current: NegotiationState, reputation: Int) throws -> NegotiationState {
        guard listing.available else { throw TradingError.unavailable }
        guard !current.closed, current.agreedPrice == nil else { throw TradingError.closed }
        guard amount > .zero, amount.minorUnits <= GameBalanceConfig.current.maximumTransactionAmount.minorUnits else { throw TradingError.invalidAmount }
        var next = current
        let variant = (listing.seller.identityIndex + current.offers.count) % 2
        next.append("player.offer", player: true, amount: amount)
        if modifier != .none { next.append(modifier.key, player: true) }
        var adjustment = 10_000 + max(0, listing.seller.patience - next.patience) * 10 + listing.seller.bargainingSkill * 2 - max(0, reputation - 50) * 5
        if modifier == .buyToday { adjustment -= listing.seller.urgency * 8 }
        if modifier == .knownIssues && !next.knownDefects.isEmpty { adjustment -= 600 }
        let minimum = min(listing.askingPrice, try listing.reservationPrice.scaled(byBasisPoints: Int64(adjustment)))
        var offer = Offer(id: OfferID("\(listing.id.rawValue)-offer-\(next.offers.count)"), listingID: listing.id, amount: amount, status: .pending)
        if amount >= minimum {
            offer.status = .accepted
            next.agreedPrice = amount
            next.counterPrice = nil
            next.append("seller.accept.\(variant)", amount: amount)
        } else if amount < (try minimum.scaled(byBasisPoints: 6_000)) || next.patience <= 15 {
            next.patience = max(0, next.patience - 30)
            offer.status = .rejected
            next.counterPrice = nil
            next.closed = next.patience == 0
            next.append(next.closed ? "seller.closed" : "seller.reject.\(variant)")
        } else {
            next.patience = max(0, next.patience - 10)
            let gap = try listing.askingPrice.subtracting(minimum)
            let counter = try minimum.adding(gap.scaled(byBasisPoints: 5_000))
            next.counterPrice = counter
            offer.status = .countered
            next.append("seller.counter.\(variant)", amount: counter)
        }
        next.offers.append(offer)
        return next
    }

    func askAboutIssues(listing: MarketplaceListing, current: NegotiationState) throws -> NegotiationState {
        guard listing.available, !current.closed, !current.askedAboutIssues else { throw TradingError.closed }
        var next = current
        next.askedAboutIssues = true
        next.append("player.question", player: true)
        let variant = listing.seller.identityIndex % 2
        if listing.seller.honesty < 40 {
            next.append("seller.evasive.\(variant)")
        } else if listing.seller.knowledge < 40 {
            next.append("seller.uncertain.\(variant)")
        } else if let defect = listing.item.hiddenDefects.first {
            next.knownDefects = [defect]
            next.append("seller.defect.\(variant)", defect: defect)
        } else {
            next.append("seller.clean.\(variant)")
        }
        return next
    }
}
