import Foundation

/// Family-level photographs. Model names/prices remain distinct; hidden truth is
/// deliberately absent from this interface. New item types can retain illustration.
enum ProductPhoto {
    static func family(identity: String, symbol: String) -> String? {
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

    static func sceneCount(family: String) -> Int {
        ["controller", "camera", "handheld"].contains(family) ? 2 : 1
    }

    /// The item's public identity keeps its seller setting stable through purchase
    /// and inspection. Condition and hidden faults never choose the setting.
    static func scene(family: String, identity: String) -> Int {
        Int(SeededRandom.seed(for: identity) % UInt64(sceneCount(family: family)))
    }

    static func asset(family: String, wear: ItemAppearance.Wear, scene: Int = 0) -> String {
        // An uninspected item has no earned condition. Its neutral image never
        // reads hidden faults; normal purchases retain the seller's claimed image.
        let condition: String = switch wear {
        case .excellent: "excellent"
        case .good, .unverified: "good"
        case .fair: "fair"
        case .poor: "poor"
        }
        let setting = scene == 1 && sceneCount(family: family) > 1 ? "-alt" : ""
        return "Product-\(family)\(setting)-\(condition)"
    }
}
