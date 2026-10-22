import Foundation
import Testing
@testable import ProjectFlip

struct KnowledgeTests {
    private func state(category: ItemCategory, defects: [Defect], condition: Int = 65) throws -> GameSnapshot {
        let definitions = try SeedContent.load().items
        var state = try GameSnapshot.fresh(definitions: definitions)
        let definition = try #require(definitions.first { $0.category == category })
        state.player.inventory = [ItemInstance(id: ItemID("knowledge-test"), definitionID: definition.id, condition: condition, hiddenDefects: defects)]
        return state
    }

    @Test func categoryExperienceAndToolsGateSubtleFaultsWithoutChangingTruth() throws {
        for category in ItemCategory.allCases {
            let faults: [Defect] = switch category {
            case .gaming: [.damagedPort, .drift, .storageFailure]
            case .cameras: [.lensScratch, .cameraBatteryWear, .sensorDamage]
            case .retro: [.boxWear, .replacementParts, .counterfeitBoard]
            }
            var state = try state(category: category, defects: faults)
            let id = state.player.inventory[0].id
            state = try InspectionEngine().inspect(itemID: id, professionally: false, state: state, category: category)
            #expect(state.player.inventory[0].revealedDefects == [faults[0]])
            #expect(state.inspectionKnowledge.points(in: category) == 1)
            #expect(throws: TradingError.self) { try InspectionEngine().inspect(itemID: id, professionally: false, state: state, category: category) }
            var practiced = state
            practiced.inspectionKnowledge.experience[category.rawValue] = 3
            practiced = try InspectionEngine().buyTools(for: category, state: practiced)
            practiced = try InspectionEngine().inspect(itemID: id, professionally: false, state: practiced, category: category)
            #expect(practiced.player.inventory[0].revealedDefects == Array(faults.prefix(2)))
            #expect(practiced.inspectionKnowledge.points(in: category) == 3)
            for other in ItemCategory.allCases where other != category {
                #expect(practiced.inspectionKnowledge.points(in: other) == 0)
                #expect(!practiced.inspectionKnowledge.tools.contains(other))
            }
            state.inspectionKnowledge.experience[category.rawValue] = 16
            let skilled = try InspectionEngine().inspect(itemID: id, professionally: false, state: state, category: category)
            #expect(skilled.player.inventory[0].revealedDefects == [faults[0]]) // Knowledge alone cannot replace tools.
            state = try InspectionEngine().buyTools(for: category, state: skilled)
            state = try InspectionEngine().inspect(itemID: id, professionally: false, state: state, category: category)
            #expect(state.player.inventory[0].revealedDefects == faults)
            #expect(state.player.inventory[0].hiddenDefects == faults)
            #expect(state.inspectionKnowledge.points(in: category) == 16) // No repeat-inspection experience.
            #expect(try JSONDecoder().decode(GameSnapshot.self, from: JSONEncoder().encode(state)) == state)
        }
    }

    @Test func toolsChargeOnceRemainCategorySpecificAndDoNotRevealAnything() throws {
        let state = try state(category: .cameras, defects: [.sensorDamage])
        let next = try InspectionEngine().buyTools(for: .cameras, state: state)
        #expect(try next.player.cash == state.player.cash.subtracting(InspectionKnowledge.toolCost(for: .cameras)))
        #expect(next.player.inventory == state.player.inventory)
        #expect(next.inspectionKnowledge.tools == [.cameras])
        #expect(next.inspectionKnowledge.level(in: .cameras) == 0)
        #expect(throws: TradingError.self) { try InspectionEngine().buyTools(for: .cameras, state: next) }
        var poor = state
        poor.player.cash = .zero
        #expect(throws: TradingError.self) { try InspectionEngine().buyTools(for: .gaming, state: poor) }
    }

    @Test func actualTimedInspectionLearnsOnlyWhenReportArrivesInCorrectCategory() throws {
        let definitions = try SeedContent.load().items
        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        let initial = try state(category: .cameras, defects: [.sensorDamage])
        let actions = SimulationActions(timing: .debug)
        let booked = try actions.inspect(itemID: initial.player.inventory[0].id, professionally: true, state: initial, now: now, definitions: definitions)
        #expect(booked.inspectionKnowledge.points(in: .cameras) == 0)
        let due = try #require(booked.inspectionJobs.first?.completesAt)
        let finished = try EventResolver(timing: .debug).resolve(booked, now: due, definitions: definitions).state
        #expect(finished.inspectionKnowledge.points(in: .cameras) == 2)
        #expect(finished.inspectionKnowledge.points(in: .gaming) == 0)
        #expect(finished.player.inventory[0].revealedDefects == [.sensorDamage])
        let repeated = try EventResolver(timing: .debug).resolve(finished, now: due.addingTimeInterval(1), definitions: definitions).state
        #expect(repeated.inspectionKnowledge == finished.inspectionKnowledge)
        #expect(repeated.player.cash == booked.player.cash)
    }

    @Test func oldSaveStartsWithoutRetroactiveExperienceAndKeepsItemFacts() throws {
        var initial = try state(category: .retro, defects: [.counterfeitBoard])
        initial.player.inventory[0].inspected = true
        var object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(initial)) as? [String: Any])
        object.removeValue(forKey: "inspectionKnowledge")
        let loaded = try JSONDecoder().decode(GameSnapshot.self, from: JSONSerialization.data(withJSONObject: object))
        #expect(loaded.inspectionKnowledge == InspectionKnowledge())
        #expect(loaded.player.inventory == initial.player.inventory)
        #expect(!loaded.inspectionKnowledge.canInspect(loaded.player.inventory[0], category: .retro))
        var upgraded = loaded
        upgraded.inspectionKnowledge.tools.insert(.retro)
        #expect(upgraded.inspectionKnowledge.canInspect(upgraded.player.inventory[0], category: .retro))
        let checked = try InspectionEngine().inspect(itemID: upgraded.player.inventory[0].id, professionally: false, state: upgraded, category: .retro)
        #expect(checked.inspectionKnowledge.points(in: .retro) == 0)
        #expect(checked.player.inventory[0].revealedDefects.isEmpty)
    }

    @Test func thresholdsAreBoundedAndInvalidSavedProgressIsRejected() throws {
        var knowledge = InspectionKnowledge()
        for (points, level) in [(0, 0), (2, 0), (3, 1), (7, 1), (8, 2), (15, 2), (16, 3), (1_000_000, 3)] {
            knowledge.experience["retro"] = points
            #expect(knowledge.level(in: .retro) == level)
        }
        knowledge.learn(2, in: .retro)
        #expect(knowledge.points(in: .retro) == 1_000_000)
        knowledge.experience["retro"] = -1
        #expect(throws: SaveError.self) { try knowledge.validate() }
        knowledge.experience = [:]
        knowledge.selfInspectionCapabilities["item"] = 9
        #expect(throws: SaveError.self) { try knowledge.validate() }
        var invalid = try state(category: .gaming, defects: [])
        invalid.inspectionKnowledge = knowledge
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let repository = SaveRepository(url: root.appendingPathComponent("save.json"))
        try repository.save(invalid)
        #expect(throws: SaveError.self) { try repository.load() }
    }
}
