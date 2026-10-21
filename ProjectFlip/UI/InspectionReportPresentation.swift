import Foundation

/// Presentation memory uses revealed evidence only, never hidden item truth.
struct InspectionReportPresentation: Sendable {
    let legacyKey: String
    let revision: String

    init(item: ItemInstance, simulationID: String) {
        legacyKey = "inspectionPresented-\(simulationID)-\(item.id.rawValue)-\(item.professionallyInspected)"
        let defects = Set(item.revealedDefects.map(\.rawValue)).sorted().joined(separator: ",")
        let facts = item.knownFactKeys.map(\.rawValue).sorted().joined(separator: ",")
        revision = "defects:\(defects)|facts:\(facts)"
    }

    var taskID: String { "\(legacyKey)-\(revision)" }
    private var revisionKey: String { "\(legacyKey)-revision" }

    func needsReveal(in preferences: UserDefaults) -> Bool {
        if let presented = preferences.string(forKey: revisionKey) { return presented != revision }
        // Older builds remembered the report tier without recording its known evidence.
        return !preferences.bool(forKey: legacyKey)
    }

    func markRead(in preferences: UserDefaults) {
        preferences.set(revision, forKey: revisionKey)
        preferences.set(true, forKey: legacyKey)
    }
}
