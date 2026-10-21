import Foundation
import Testing
@testable import ProjectFlip

struct InspectionPresentationTests {
    private func preferences() throws -> (String, UserDefaults) {
        let name = "InspectionPresentationTests-\(UUID().uuidString)"
        return (name, try #require(UserDefaults(suiteName: name)))
    }
    private func inspectedItem() -> ItemInstance {
        ItemInstance(id: ItemID("inspection-item"), definitionID: "gaming-0", condition: 79,
                     hiddenDefects: [.drift, .damagedPort], revealedDefects: [.damagedPort], inspected: true)
    }

    @Test func readReportStaysReadAcrossReconstruction() throws {
        let (name, defaults) = try preferences()
        defer { defaults.removePersistentDomain(forName: name) }
        let item = inspectedItem()
        let first = InspectionReportPresentation(item: item, simulationID: "save")
        #expect(first.needsReveal(in: defaults))
        first.markRead(in: defaults)
        let reopened = InspectionReportPresentation(item: item, simulationID: "save")
        #expect(!reopened.needsReveal(in: defaults))
        #expect(reopened.taskID == first.taskID)
    }

    @Test func newlyDiscoveredEvidenceGetsItsOwnReveal() throws {
        let (name, defaults) = try preferences()
        defer { defaults.removePersistentDomain(forName: name) }
        var item = inspectedItem()
        let first = InspectionReportPresentation(item: item, simulationID: "save")
        first.markRead(in: defaults)
        item.revealedDefects.append(.drift)
        let improved = InspectionReportPresentation(item: item, simulationID: "save")
        #expect(improved.taskID != first.taskID)
        #expect(improved.needsReveal(in: defaults))
        improved.markRead(in: defaults)
        #expect(!improved.needsReveal(in: defaults))
    }

    @Test func repairsAndEvidenceOrderingDoNotReplayAnOldReport() throws {
        let (name, defaults) = try preferences()
        defer { defaults.removePersistentDomain(forName: name) }
        var item = inspectedItem()
        item.revealedDefects.append(.drift)
        let first = InspectionReportPresentation(item: item, simulationID: "save")
        first.markRead(in: defaults)
        item.revealedDefects.reverse()
        item.repairedDefects = [.damagedPort]
        let repaired = InspectionReportPresentation(item: item, simulationID: "save")
        #expect(repaired.taskID == first.taskID)
        #expect(!repaired.needsReveal(in: defaults))
    }

    @Test func professionalReportsAndDifferentSavesRemainIndependent() throws {
        let (name, defaults) = try preferences()
        defer { defaults.removePersistentDomain(forName: name) }
        var item = inspectedItem()
        InspectionReportPresentation(item: item, simulationID: "save").markRead(in: defaults)
        #expect(InspectionReportPresentation(item: item, simulationID: "different-save").needsReveal(in: defaults))
        item.professionallyInspected = true
        #expect(InspectionReportPresentation(item: item, simulationID: "save").needsReveal(in: defaults))
    }

    @Test func legacyAcknowledgmentMigratesWithoutReplayButNewEvidenceStillReveals() throws {
        let (name, defaults) = try preferences()
        defer { defaults.removePersistentDomain(forName: name) }
        var item = inspectedItem()
        defaults.set(true, forKey: "inspectionPresented-save-inspection-item-false")
        let oldReport = InspectionReportPresentation(item: item, simulationID: "save")
        #expect(!oldReport.needsReveal(in: defaults))
        oldReport.markRead(in: defaults)
        item.revealedDefects.append(.drift)
        #expect(InspectionReportPresentation(item: item, simulationID: "save").needsReveal(in: defaults))
    }

    @Test func newlyMeasuredFactsGetOneReveal() throws {
        let (name, defaults) = try preferences()
        defer { defaults.removePersistentDomain(forName: name) }
        let definition = try #require(SeedContent.load().items.first { $0.id == "cameras-0" })
        var item = ItemInstance(id: ItemID("camera-report"), definitionID: definition.id, condition: 90,
                                hiddenDefects: [], inspected: true)
        item.facts = ItemFacts.generate(for: item, definition: definition)
        item.revealedFactKeys = [.cosmeticScore]
        let first = InspectionReportPresentation(item: item, simulationID: "save")
        first.markRead(in: defaults)
        item.revealedFactKeys = [.cosmeticScore, .batteryHealth]
        let improved = InspectionReportPresentation(item: item, simulationID: "save")
        #expect(improved.taskID != first.taskID)
        #expect(improved.needsReveal(in: defaults))
        improved.markRead(in: defaults)
        #expect(!InspectionReportPresentation(item: item, simulationID: "save").needsReveal(in: defaults))
    }

    @Test func hiddenTruthDoesNotControlPresentationMemory() throws {
        let (name, defaults) = try preferences()
        defer { defaults.removePersistentDomain(forName: name) }
        let item = inspectedItem()
        let first = InspectionReportPresentation(item: item, simulationID: "save")
        first.markRead(in: defaults)
        let differentTruth = ItemInstance(id: item.id, definitionID: item.definitionID, condition: item.condition,
                                         hiddenDefects: [.damagedPort, .wirelessFault],
                                         revealedDefects: item.revealedDefects, inspected: true)
        let sameEvidence = InspectionReportPresentation(item: differentTruth, simulationID: "save")
        #expect(sameEvidence.taskID == first.taskID)
        #expect(!sameEvidence.needsReveal(in: defaults))
    }

}
