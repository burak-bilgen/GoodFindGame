import Foundation

struct ResaleEngine {
    func create(itemID: ItemID, askingPrice: Money, state: GameSnapshot, definitions: [ItemDefinition], now: Date) throws -> GameSnapshot {
        guard askingPrice > .zero, askingPrice.minorUnits <= GameBalanceConfig.current.maximumTransactionAmount.minorUnits else { throw TradingError.invalidAmount }
        guard let item = state.player.inventory.first(where: { $0.id == itemID }), let definition = definitions.first(where: { $0.id == item.definitionID }) else { throw TradingError.unavailable }
        guard item.inspected else { throw TradingError.inspectFirst }
        guard !state.playerListings.contains(where: { $0.itemID == itemID && $0.status == .active }) else { throw TradingError.alreadyDone }
        let fair = try PricingEngine.fairValue(of: item, definition: definition, marketBasisPoints: state.marketMultiplier(for: definition, at: now))
        // Phase A resolves initial attention immediately. These persisted counters come from the price model.
        let (scaled, overflow) = askingPrice.minorUnits.multipliedReportingOverflow(by: 10_000)
        guard !overflow, fair > .zero else { throw TradingError.invalidAmount }
        let ratio = scaled / fair.minorUnits
        let views = max(0, 24 - Int(ratio / 1_000))
        var next = state
        next.playerListings.append(PlayerListing(id: ListingID("resale-\(item.id.rawValue)-\(state.playerListings.count)"), itemID: item.id, askingPrice: askingPrice, createdAt: now, views: views, favorites: askingPrice <= fair ? views / 4 : 0))
        return next
    }
}
