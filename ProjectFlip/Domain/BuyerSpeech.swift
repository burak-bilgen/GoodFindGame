/// Dialogue uses its own stable identity hash, never the economic random stream.
/// Persisted messages keep their original intent when older saves are loaded.
enum BuyerSpeech {
    static func opening(archetype: BuyerArchetype, offerID: OfferID) -> String {
        let variant = SeededRandom.seed(for: "speech-\(offerID.rawValue)") % 3
        let base = "buyer.offer.\(archetype.rawValue)"
        return variant == 0 ? base : "\(base).\(variant)"
    }
}
