import Foundation

// Work first; settled receipts remain in the trade ledger.
extension GameSnapshot {
    func needsBuyerAction(_ listing: PlayerListing) -> Bool {
        listing.status == .active && !hasBuyerReply(for: listing.id) &&
        listing.offers.last.map { [.pending, .countered].contains($0.status) } == true
    }
    var activeSales: [PlayerListing] {
        playerListings.filter { $0.status == .active }.sorted {
            let left = needsBuyerAction($0), right = needsBuyerAction($1)
            if left != right { return left }
            if left {
                let leftEnd = buyerActionDeadline($0) ?? .distantFuture, rightEnd = buyerActionDeadline($1) ?? .distantFuture
                if leftEnd != rightEnd { return leftEnd < rightEnd }
            }
            let leftDate = $0.lastActivityAt ?? $0.createdAt, rightDate = $1.lastActivityAt ?? $1.createdAt
            return leftDate == rightDate ? $0.id.rawValue < $1.id.rawValue : leftDate > rightDate
        }
    }
}

extension GameSnapshot {
    /// Only deadlines already visible to the player; no future buyer prediction.
    func buyerActionDeadline(_ listing: PlayerListing) -> Date? {
        let offerID = listing.offers.last?.id
        let replyExpiry = events.filter { event in
            guard event.status == .pending else { return false }
            if case .buyerOfferExpired(let id, let offer) = event.payload {
                return id == listing.id && offer == offerID
            }
            return false
        }.map(\.resolveAt).min() ?? .distantFuture
        let end = min(listing.expiresAt ?? .distantFuture, replyExpiry)
        return end == .distantFuture ? nil : end
    }

    var readySellerConversations: [NegotiationState] {
        conversations.filter { talk in
            !talk.closed && talk.pendingReplyEventID == nil &&
            (talk.counterPrice != nil || talk.agreedPrice != nil) &&
            market.contains { $0.id == talk.listingID && $0.available }
        }.sorted {
            let left = $0.counterExpiresAt ?? .distantFuture
            let right = $1.counterExpiresAt ?? .distantFuture
            return left == right ? $0.listingID.rawValue < $1.listingID.rawValue : left < right
        }
    }
}
