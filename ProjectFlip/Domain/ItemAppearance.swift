import Foundation

/// Only seller-visible claims or earned inspection evidence may reach product artwork.
/// Photo framing can later vary independently without giving the renderer hidden truth.
struct ItemAppearance: Equatable, Sendable {
    enum Wear: Int, Sendable { case excellent, good, fair, poor, unverified }
    let wear: Wear
    let visibleFindings: Set<Defect>
    let identity: String

    static func advertised(_ listing: MarketplaceListing) -> Self {
        Self(wear: wear(for: listing.claimedCondition), visibleFindings: [], identity: listing.item.id.rawValue)
    }

    static func owned(_ item: ItemInstance, showFindings: Bool = true) -> Self {
        let visible: Set<Defect> = [.damagedPort, .lensFungus, .lensScratch, .boxWear, .labelDamage, .corrosion, .incompleteSet]
        return Self(wear: item.inspected ? wear(for: item.condition) : .unverified,
                    visibleFindings: item.inspected && showFindings ? Set(item.knownActiveDefects).intersection(visible) : [],
                    identity: item.id.rawValue)
    }

    private static func wear(for score: Int) -> Wear {
        score >= 90 ? .excellent : score >= 75 ? .good : score >= 55 ? .fair : .poor
    }
}
