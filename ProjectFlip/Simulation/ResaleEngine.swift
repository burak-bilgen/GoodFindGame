import Foundation

struct ResaleEngine {
    func create(itemID: ItemID, askingPrice: Money, state: GameSnapshot, definitions: [ItemDefinition], now: Date) throws -> GameSnapshot {
        guard askingPrice > .zero, askingPrice.minorUnits <= GameBalanceConfig.current.maximumTransactionAmount.minorUnits else { throw TradingError.invalidAmount }
        guard let item = state.player.inventory.first(where: { $0.id == itemID }), let _ = definitions.first(where: { $0.id == item.definitionID }) else { throw TradingError.unavailable }
        guard state.recovery.itemID != itemID else { throw TradingError.consignedItem }
        guard !state.collections.displayed.contains(itemID) else { throw TradingError.itemDisplayed }
        guard item.inspected else { throw TradingError.inspectFirst }
        guard !state.inspectionJobs.contains(where: { $0.itemID == itemID && $0.status == .pending }) else { throw TradingError.inspectionPending }
        guard !state.playerListings.contains(where: { $0.itemID == itemID && $0.status == .active }) else { throw TradingError.alreadyDone }
        var next = state
        next.playerListings.append(PlayerListing(id: ListingID("resale-\(item.id.rawValue)-\(state.playerListings.count)"), itemID: item.id, askingPrice: askingPrice, createdAt: now, views: 0, favorites: 0, expiresAt: now.addingTimeInterval(45 * 60)))
        return next
    }
}
