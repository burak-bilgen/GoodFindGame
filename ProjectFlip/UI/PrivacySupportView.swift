import SwiftUI

/// Optional publisher links are supplied by the release configuration, never guessed.
enum PublisherLinks {
    static func url(_ key: String) -> URL? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
              let url = URL(string: value), url.scheme == "https", url.host != nil else { return nil }
        return url
    }
    static var email: URL? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "SupportEmail") as? String,
              value.contains("@"), !value.contains(where: { $0.isWhitespace }),
              var parts = URLComponents(string: "mailto:") else { return nil }
        parts.path = value
        return parts.url
    }
}

struct PrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ForEach(["privacy.local", "privacy.tracking", "privacy.apple", "privacy.control", "privacy.support"], id: \.self) { key in
                    Text(LocalizedStringKey(key)).frame(maxWidth: .infinity, alignment: .leading).gameCard()
                }
                Link("privacy.applePolicy", destination: URL(string: "https://www.apple.com/legal/privacy/")!)
                if let url = PublisherLinks.url("PrivacyPolicyURL") { Link("privacy.web", destination: url) }
                if let email = PublisherLinks.email { Link("support.contact", destination: email).accessibilityIdentifier("supportContact") }
            }.buttonStyle(GameButton(secondary: true)).padding(16)
        }.gameScreen().navigationTitle("privacy.title").navigationBarTitleDisplayMode(.inline)
    }
}

struct SupportView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("support.play").gameCard()
                Text("support.saves").gameCard()
                if let url = PublisherLinks.url("SupportURL") { Link("support.web", destination: url) }
                if let email = PublisherLinks.email { Link("support.contact", destination: email).accessibilityIdentifier("supportContact") }
                NavigationLink { PrivacyView() } label: { Text("privacy.title") }
                LabeledContent("settings.version") { Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0") }
            }.buttonStyle(GameButton(secondary: true)).padding(16)
        }.gameScreen().navigationTitle("support.title").navigationBarTitleDisplayMode(.inline)
    }
}
