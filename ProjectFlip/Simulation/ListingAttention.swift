import Foundation

/// A saved queue samples audience response; UI never invents counts or reveals this model's score.
struct ListingAttention {
    let delayFactor: Double
    let offerChance: Int
    let views: Int
    let favorites: Int

    init(listing: PlayerListing, item: ItemInstance, definition: ItemDefinition, state: GameSnapshot, at date: Date, seed: UInt64) throws {
        let fair = try PricingEngine.fairValue(of: item, definition: definition, marketBasisPoints: state.marketMultiplier(for: definition, at: date))
        let ratio = Double(listing.askingPrice.minorUnits) / Double(max(1, fair.minorUnits))
        var random = SeededRandom(seed: seed)
        let priceFactor = ratio <= 0.9 ? 0.6 : ratio <= 1.1 ? 1.0 : ratio <= 1.4 ? 1.6 : ratio <= 2 ? 2.3 : 2.8
        let audienceFactor = definition.category == .gaming ? 0.9 : definition.category == .cameras ? 1.15 : 1.35
        delayFactor = priceFactor * audienceFactor * max(0.8, 1 - Double(state.player.reputation - 50) / 250)
        offerChance = ratio <= 0.9 ? 90 : ratio <= 1.1 ? 65 : ratio <= 1.4 ? 35 : ratio <= 2.5 ? 10 : 0
        views = max(0, Int(Double(random.integer(in: 5...22)) / (priceFactor * audienceFactor)))
        favorites = views > 0 ? random.integer(in: 0...max(1, views / (ratio <= 1.1 ? 3 : 7))) : 0
    }
}
