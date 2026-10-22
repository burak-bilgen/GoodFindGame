import Foundation

/// Only seller-visible claims or earned inspection evidence may reach product artwork.
/// Photo framing can later vary independently without giving the renderer hidden truth.
struct ItemAppearance: Equatable, Sendable {
    enum Wear: Int, Sendable { case excellent, good, fair, poor, unverified }
    let wear: Wear
    let visibleFindings: Set<Defect>
    enum PhotoStyle: String, Sendable { case neutral, professional, casual, careless, evasive, inspection }
    let identity: String
    var photoStyle: PhotoStyle = .neutral

    static func advertised(_ listing: MarketplaceListing) -> Self {
        let style: PhotoStyle = switch listing.seller.archetype {
        case .professional, .collector: .professional
        case .clueless: .careless
        case .manipulative: .evasive
        default: .casual
        }
        return Self(wear: wear(for: listing.claimedCondition), visibleFindings: [], identity: listing.item.id.rawValue, photoStyle: style)
    }

    static func owned(_ item: ItemInstance, showFindings: Bool = true) -> Self {
        let visible: Set<Defect> = [.damagedPort, .lensFungus, .lensScratch, .boxWear, .labelDamage, .corrosion, .incompleteSet]
        return Self(wear: item.inspected ? wear(for: item.condition) : .unverified,
                    visibleFindings: item.inspected && showFindings ? Set(item.knownActiveDefects).intersection(visible) : [],
                    identity: item.id.rawValue, photoStyle: .inspection)
    }

    private static func wear(for score: Int) -> Wear {
        score >= 90 ? .excellent : score >= 75 ? .good : score >= 55 ? .fair : .poor
    }
}
