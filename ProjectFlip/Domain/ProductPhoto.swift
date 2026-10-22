import Foundation

/// One fixed photograph per product mapping. Model names/prices remain distinct; hidden truth is
/// deliberately absent from this interface. New item types can retain illustration.
enum ProductPhoto {
    static let photographedHouseholdModels = Set((0..<10).map { "home-\($0)" } + (0..<3).map { "furniture-\($0)" })

    static func family(identity: String, symbol: String) -> String? {
        if photographedHouseholdModels.contains(identity) { return "model-" + identity }
        if identity.hasPrefix("cameras-") {
            return symbol == "camera.aperture" ? "lens" : "camera"
        }
        if identity.hasPrefix("retro-") {
            switch symbol {
            case "gamecontroller": return "handheld"
            case "rectangle.stack": return "boxedgame"
            case "radio": return "tape"
            case "opticaldisc": return "disc"
            case "tv": return "retrodesktop"
            default: return nil
            }
        }
        guard identity.hasPrefix("gaming-") else { return nil }
        switch symbol {
        case "gamecontroller": return identity == "gaming-15" ? "handheld" : "controller"
        case "gamecontroller.fill": return "console"
        case "display": return "display"
        case "headphones": return "headphones"
        case "hifispeaker": return "speaker"
        case "externaldrive": return "drive"
        case "desktopcomputer": return "desktop"
        default: return nil
        }
    }

    static func dedicatedMaster(for identity: String) -> String? {
        dedicatedModels.contains(identity) ? "model-" + identity : nil
    }
    static let dedicatedModels: Set<String> = ["retro-0", "retro-2", "retro-8", "cameras-0", "cameras-8", "cameras-9", "cameras-10"]

    /// A product has one fixed photograph. Cosmetic grades and seller presentation
    /// never choose another asset; condition belongs to text and inspection facts.
    static func asset(identity: String, symbol: String) -> String? {
        guard let family = family(identity: identity, symbol: symbol) else { return nil }
        return "Product-" + (dedicatedMaster(for: identity) ?? family)
    }
}
