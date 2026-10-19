import Foundation
import OSLog

/// Content keys are plain Strings, preventing SwiftUI from treating key indices as format arguments.
enum GameText {
    static func string(_ key: String, locale: Locale) -> String {
        let language = locale.language.languageCode?.identifier == "tr" ? "tr" : "en"
        for candidate in [language, "en"] {
            if let path = Bundle.main.path(forResource: candidate, ofType: "lproj"), let bundle = Bundle(path: path) {
                let value = bundle.localizedString(forKey: key, value: nil, table: "Localizable")
                if value != key { return value }
            }
        }
        Logger(subsystem: "ProjectFlip", category: "Localization").error("Missing content key: \(key, privacy: .public)")
        return "…"
    }
}
