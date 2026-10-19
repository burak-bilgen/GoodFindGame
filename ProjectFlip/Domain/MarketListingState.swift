import Foundation

enum MarketClosureReason: String, Codable { case expired, competitor, purchased, withdrawn
    var key: String { "listing.status.\(rawValue)" }
}

struct MarketListingState: Codable, Equatable, Identifiable {
    let id: ListingID
    var expiresAt: Date
    let competitorIdentityIndex: Int?
    var competitorPurchaseAt: Date?
    let initialAskingPrice: Money
    let priceDropAt: Date?
    let reducedPrice: Money?
    var priceDroppedAt: Date?
    var closedAt: Date?
    var closureReason: MarketClosureReason?
}

struct MarketFeedTiming: Sendable {
    let refresh: TimeInterval
    let remainingLifetime: ClosedRange<TimeInterval>
    let competitorDelay: ClosedRange<TimeInterval>
    let priceDropDelay: ClosedRange<TimeInterval>
    static let production = Self(refresh: 1_800, remainingLifetime: 7_200...21_600, competitorDelay: 600...5_400, priceDropDelay: 1_800...5_400)
    static let debug = Self(refresh: 90, remainingLifetime: 300...540, competitorDelay: 50...180, priceDropDelay: 35...90)
}
