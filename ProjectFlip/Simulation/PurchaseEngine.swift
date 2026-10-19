import Foundation

struct PurchaseEngine {
    func buy(listingID: ListingID, state: GameSnapshot, now: Date) throws -> GameSnapshot {
        guard let listingIndex = state.market.firstIndex(where: { $0.id == listingID }), state.market[listingIndex].available,
              let conversationIndex = state.conversations.firstIndex(where: { $0.listingID == listingID }),
              let price = state.conversations[conversationIndex].agreedPrice,
              !state.conversations[conversationIndex].closed,
              state.conversations[conversationIndex].counterExpiresAt.map({ $0 > now }) ?? true else { throw TradingError.unavailable }
        guard price > .zero, state.player.cash >= price else { throw TradingError.insufficientCash }
        guard state.player.inventory.count < state.player.inventoryCapacity else { throw TradingError.inventoryFull }
        guard !state.player.inventory.contains(where: { $0.id == state.market[listingIndex].item.id }) else { throw TradingError.alreadyDone }
        var next = state
        var item = state.market[listingIndex].item
        item.purchasePrice = price
        item.acquiredAt = now
        item.revealedDefects = state.conversations[conversationIndex].knownDefects
        next.player.cash = try next.player.cash.subtracting(price)
        next.player.inventory.append(item)
        next.market[listingIndex].available = false
        if let lifecycle = next.marketListingStates.firstIndex(where: { $0.id == listingID }) {
            next.marketListingStates[lifecycle].closureReason = .purchased
            next.marketListingStates[lifecycle].closedAt = now
        }
        next.conversations[conversationIndex].closed = true
        next.conversations[conversationIndex].append("purchase.completed", amount: price)
        return next
    }
}
