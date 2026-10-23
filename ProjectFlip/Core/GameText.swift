import Foundation
import OSLog

/// Content keys are plain Strings, preventing SwiftUI from treating key indices as format arguments.
enum GameText {
    static let supportedLanguages = ["en", "tr", "de", "fr"]
    static func string(_ key: String, locale: Locale) -> String {
        let requested = locale.language.languageCode?.identifier ?? "en"
        let language = supportedLanguages.contains(requested) ? requested : "en"
        for candidate in [language, "en"] {
            if let path = Bundle.main.path(forResource: candidate, ofType: "lproj"), let bundle = Bundle(path: path) {
                let value = bundle.localizedString(forKey: key, value: nil, table: "Localizable")
                if value != key { return value }
            }
        }
        Logger(subsystem: "ProjectFlip", category: "Localization").error("Missing content key: \(key, privacy: .public)")
        return "…"
    }
    static func marketPerson(_ kind: String, index: Int, market: MarketConfiguration, locale: Locale) -> String {
        string("people.\(kind).\(index % 10)", locale: locale)
    }
    static func format(_ key: String, locale: Locale, _ arguments: CVarArg...) -> String {
        String(format: string(key, locale: locale), locale: locale, arguments: arguments)
    }

}
