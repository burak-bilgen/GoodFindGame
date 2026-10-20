import Foundation
import Testing
@testable import ProjectFlip

struct ItemFactsTests {
    private func item(_ definitionID: String, defects: [Defect] = []) throws -> (ItemInstance, ItemDefinition) {
        let definition = try #require(SeedContent.load().items.first { $0.id == definitionID })
        var item = ItemInstance(id: ItemID("facts-\(definitionID)"), definitionID: definitionID, condition: 90, hiddenDefects: defects)
        item.facts = ItemFacts.generate(for: item, definition: definition)
        return (item, definition)
    }

    @Test func generationIsStableCategorySpecificAndDoesNotChangeTheExistingEconomy() throws {
        let definitions = try SeedContent.load().items
        let now = Date(timeIntervalSinceReferenceDate: 1234)
        let first = try ListingGenerator().generate(definitions: definitions, seed: 42, now: now)
        #expect(try first == ListingGenerator().generate(definitions: definitions, seed: 42, now: now))
        #expect(first[0].askingPrice == Money(minorUnits: 237_728))
        for listing in first {
            let definition = try #require(definitions.first { $0.id == listing.item.definitionID })
            let facts = try #require(listing.item.facts)
            try facts.validate()
            #expect(facts == ItemFacts.generate(for: listing.item, definition: definition))
            #expect(listing.item.knownFactKeys.isEmpty)
            #expect(facts.category == definition.category)
            var stripped = listing.item
            stripped.facts = nil
            #expect(try PricingEngine.fairValue(of: stripped, definition: definition) == PricingEngine.fairValue(of: listing.item, definition: definition))
        }
        for id in ["cameras-8", "cameras-9", "cameras-10", "cameras-11"] {
            let (lens, _) = try item(id)
            let keys = Set(try #require(lens.facts).values.map(\.key))
            #expect(!keys.contains(.shutterCount) && !keys.contains(.batteryHealth) && !keys.contains(.sensor))
            #expect(keys.contains(.optics))
        }
        for category in ItemCategory.allCases {
            #expect(first.contains { $0.item.facts?.category == category })
        }
    }

    @Test func visibleRetroEvidenceConfirmsAllRelatedFaultsWithoutExposingAuthenticity() throws {
        let (item, _) = try item("retro-0", defects: [.missingManual, .incompleteSet, .boxWear, .counterfeitBoard])
        var state = try GameSnapshot.fresh(definitions: SeedContent.load().items)
        state.player.inventory = [item]
        let checked = try InspectionEngine().inspect(itemID: item.id, professionally: false, state: state, category: .retro)
        let result = checked.player.inventory[0]
        #expect(result.knownFactKeys == [.cosmeticScore, .completeness, .packaging, .edition])
        #expect(Set(result.revealedDefects) == [.missingManual, .incompleteSet, .boxWear])
        #expect(!result.knownFactKeys.contains(.authenticity))
        #expect(!result.revealedDefects.contains(.counterfeitBoard))
        #expect(result.hiddenDefects == item.hiddenDefects)
        #expect(checked.inspectionKnowledge.points(in: .retro) == 1)
    }

    @Test func numericalMeasurementsRequireKnowledgeAndToolsAndAnExpertReportCanRevealThem() throws {
        let (item, definition) = try item("cameras-0", defects: [.shutterWear, .cameraBatteryWear, .sensorDamage])
        var state = try GameSnapshot.fresh(definitions: SeedContent.load().items)
        state.player.inventory = [item]
        state = try InspectionEngine().inspect(itemID: item.id, professionally: false, state: state, category: .cameras)
        #expect(state.player.inventory[0].knownFactKeys == [.cosmeticScore])
        #expect(state.player.inventory[0].revealedDefects.isEmpty)
        #expect(try InspectionEngine().estimatedValue(item: state.player.inventory[0], definition: definition) == InspectionEngine().estimatedValue(item: item, definition: definition))
        state.inspectionKnowledge.experience["cameras"] = 8
        state = try InspectionEngine().buyTools(for: .cameras, state: state)
        state = try InspectionEngine().inspect(itemID: item.id, professionally: false, state: state, category: .cameras)
        #expect(state.player.inventory[0].knownFactKeys == [.cosmeticScore, .shutterCount, .batteryHealth])
        #expect(Set(state.player.inventory[0].revealedDefects) == [.shutterWear, .cameraBatteryWear])
        #expect(state.inspectionKnowledge.points(in: .cameras) == 8)
        let booked = try SimulationActions(timing: .debug).inspect(itemID: item.id, professionally: true, state: state, now: Date(timeIntervalSinceReferenceDate: 1000), definitions: [definition])
        #expect(!booked.player.inventory[0].knownFactKeys.contains(.sensor))
        let due = try #require(booked.inspectionJobs.first?.completesAt)
        let finished = try EventResolver(timing: .debug).resolve(booked, now: due, definitions: [definition]).state
        #expect(finished.player.inventory[0].knownFactKeys == Set(try #require(item.facts).values.map(\.key)))
        #expect(Set(finished.player.inventory[0].revealedDefects) == Set(item.hiddenDefects))
        #expect(finished.player.inventory[0].facts == item.facts)
        #expect(finished.inspectionKnowledge.points(in: .cameras) == 10)
        #expect(try JSONDecoder().decode(GameSnapshot.self, from: JSONEncoder().encode(finished)) == finished)
    }

    @Test func recordedResultsMatchSavedDefectsIncludingCombinedFaults() throws {
        let (camera, _) = try item("cameras-8", defects: [.lensScratch, .lensFungus])
        #expect(camera.facts?.values.first { $0.key == .optics }?.value == .term(.scratchedAndFungus))
        let (retro, _) = try item("retro-0", defects: [.counterfeitBoard, .regionMismatch, .replacementParts])
        #expect(retro.facts?.values.first { $0.key == .authenticity }?.value == .term(.reproduction))
        #expect(retro.facts?.values.first { $0.key == .region }?.value == .term(.regionB))
        #expect(retro.facts?.values.first { $0.key == .originalParts }?.value == .term(.replacedParts))
        let (cameraBody, _) = try item("cameras-0", defects: [.shutterWear, .cameraBatteryWear])
        if case .number(let n) = cameraBody.facts?.values.first(where: { $0.key == .shutterCount })?.value { #expect(n >= 120_000) }
        else { Issue.record("Missing body shutter measurement") }
        if case .number(let n) = cameraBody.facts?.values.first(where: { $0.key == .batteryHealth })?.value { #expect(n <= 65) }
        else { Issue.record("Missing body battery measurement") }
    }

    @Test func oldItemsKeepTheirFactsWithoutInventingMeasurements() throws {
        let (original, _) = try item("retro-0", defects: [.corrosion])
        var object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(original)) as? [String: Any])
        object.removeValue(forKey: "facts")
        object.removeValue(forKey: "revealedFactKeys")
        var old = try JSONDecoder().decode(ItemInstance.self, from: JSONSerialization.data(withJSONObject: object))
        old.revealFacts(knowledge: InspectionKnowledge(), professionally: true)
        #expect(old.facts == nil && old.knownFactKeys.isEmpty)
        #expect(old.hiddenDefects == original.hiddenDefects && old.condition == original.condition)
    }

    @Test func everyFindingHasTurkishAndEnglishCopy() {
        for locale in [Locale(identifier: "tr_TR"), Locale(identifier: "en_US")] {
            for key in ItemFactKey.allCases { #expect(GameText.string("facts.field.\(key.rawValue)", locale: locale) != "…") }
            for term in ItemFactTerm.allCases { #expect(GameText.string("facts.term.\(term.rawValue)", locale: locale) != "…") }
        }
    }

    @Test func invalidFieldsAndUnrecordedRevealsAreRejectedByTheSaveLoader() throws {
        let cosmetic = ItemFact(key: .cosmeticScore, value: .number(90))
        for facts in [
            ItemFacts(version: 2, category: .gaming, values: [cosmetic]),
            ItemFacts(version: 1, category: .gaming, values: [cosmetic, cosmetic]),
            ItemFacts(version: 1, category: .gaming, values: [cosmetic, ItemFact(key: .region, value: .term(.regionA))]),
            ItemFacts(version: 1, category: .cameras, values: [cosmetic, ItemFact(key: .batteryHealth, value: .number(101))]),
            ItemFacts(version: 1, category: .retro, values: [cosmetic, ItemFact(key: .authenticity, value: .term(.clear))])
        ] { #expect(throws: SaveError.self) { try facts.validate() } }
        var state = try GameSnapshot.fresh(definitions: SeedContent.load().items)
        var invalid = try item("cameras-8").0
        invalid.revealedFactKeys = [.shutterCount]
        state.player.inventory = [invalid]
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let repository = SaveRepository(url: root.appendingPathComponent("save.json"))
        try repository.save(state)
        #expect(throws: SaveError.self) { try repository.load() }
    }
}
