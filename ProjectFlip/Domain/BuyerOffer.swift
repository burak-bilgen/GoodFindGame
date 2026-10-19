import Foundation

enum BuyerArchetype: String, Codable, CaseIterable {
    case cautious, bargainHunter, collector, impatient, reseller, lowballer
    var valueBasisPoints: Int64 {
        switch self {
        case .cautious: 9_500
        case .bargainHunter: 8_000
        case .collector: 10_800
        case .impatient: 10_000
        case .reseller: 7_200
        case .lowballer: 5_500
        }
    }
}
struct BuyerOffer: Codable, Identifiable, Equatable {
    let id: OfferID
    let archetype: BuyerArchetype
    let identityIndex: Int
    let willingness: Money
    var amount: Money
    var status: OfferStatus = .pending
    var counterAttempts = 0
}
