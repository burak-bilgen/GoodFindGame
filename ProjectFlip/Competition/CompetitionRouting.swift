import Foundation

/// Routing seam for a future Game Center Activity. No activity is registered or advertised in V1.
/// Future adapters map their verified activity identifier to this route before presenting it.
enum CompetitionRoute: Equatable {
    case weekly
    static func activity(identifier: String) -> Self? {
        identifier == "trading.activity.weekly.v1" ? .weekly : nil
    }
}
