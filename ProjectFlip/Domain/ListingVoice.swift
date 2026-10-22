import Foundation

/// Authored complete voices, not recombined sentence fragments. Separate seed
/// stream: wording never rerolls price, seller personality or the item's truth.
enum ListingVoice {
    static func key(archetype: SellerArchetype, identity: String) -> String {
        let variant = SeededRandom.seed(for: "listing-voice-v1-\(identity)") % 3
        return "listing.voice.\(archetype.rawValue).\(variant)"
    }
}
