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
        // Interpolate the same qualitative price bands. A one-credit edit must
        // not suddenly halve liquidity at a hidden threshold.
        let bands: [(price: Double, delay: Double, chance: Double)] = [
            (0.9, 0.6, 90), (1.1, 1, 65), (1.4, 1.6, 35), (1.8, 2.3, 18), (2.5, 2.8, 0)
        ]
        let lower = bands.last(where: { $0.price <= ratio }) ?? bands[0]
        let upper = bands.first(where: { $0.price >= ratio }) ?? bands[bands.count - 1]
        let fraction = upper.price > lower.price ? (ratio - lower.price) / (upper.price - lower.price) : 0
        let priceFactor = lower.delay + fraction * (upper.delay - lower.delay)
        let audienceFactor: Double = switch definition.category {
        case .gaming: 0.9
        case .cameras: 1.15
        case .retro: 1.35
        case .home: 1
        case .furniture: 1.25
        case .everyday: 0.95
        }
        delayFactor = priceFactor * audienceFactor
        offerChance = Int((lower.chance + fraction * (upper.chance - lower.chance)).rounded())
        views = max(0, Int(Double(random.integer(in: 5...22)) / (priceFactor * audienceFactor)))
        let favoriteDivisor = 3 + 4 * min(1, max(0, (ratio - 1.1) / 0.3))
        favorites = views > 0 ? random.integer(in: 0...max(1, Int(Double(views) / favoriteDivisor))) : 0
    }
}
