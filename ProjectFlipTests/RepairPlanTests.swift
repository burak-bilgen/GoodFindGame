import Foundation
import Testing
@testable import ProjectFlip

struct RepairPlanTests {
    private func fixture() throws -> (GameSnapshot, [ItemDefinition]) {
        let definitions = try SeedContent.load().items
        var state = try GameSnapshot.fresh(definitions: definitions)
        state.player.inventory = [ItemInstance(id: ItemID("repair-plan"), definitionID: "gaming-0", condition: 85,
            hiddenDefects: [.drift, .damagedPort, .batteryWear], revealedDefects: [.drift, .damagedPort],
            inspected: true, purchasePrice: Money(minorUnits: 2_000))]
        return (state, definitions)
    }

    @Test func combinedQuoteMatchesOrdinaryRepairsWithoutDoubleCountingRecovery() throws {
        let (state, definitions) = try fixture()
        let item = state.player.inventory[0]
        let definition = try #require(definitions.first { $0.id == item.definitionID })
        let selected: Set<Defect> = [.drift, .damagedPort]
        let plan = try RepairPlan(item: item, definition: definition, selecting: selected)
        var ordinary = state
        for fault in plan.defects { ordinary = try RepairEngine().repair(itemID: item.id, defect: fault, state: ordinary, definitions: definitions) }
        let result = try RepairEngine().apply(itemID: item.id, selection: selected, expectedCost: plan.cost, state: state, definitions: definitions)
        #expect(result == ordinary)
        #expect(result.player.inventory[0].repairCost == plan.cost)
        #expect(try state.player.cash.subtracting(result.player.cash) == plan.cost)
        let engine = InspectionEngine()
        #expect(try plan.estimatedRecovery == engine.estimatedValue(item: result.player.inventory[0], definition: definition).subtracting(engine.estimatedValue(item: item, definition: definition)))
        #expect(result.player.inventory[0].activeDefects == [.batteryWear])
        #expect(result.player.inventory[0].hiddenDefects == item.hiddenDefects)
        #expect(result.player.inventory[0].revealedDefects == item.revealedDefects)
        #expect(result.player.inventory[0].condition == item.condition)
        #expect(try JSONDecoder().decode(GameSnapshot.self, from: JSONEncoder().encode(result)) == result)
    }

    @Test func partialWorkLeavesOtherFindingsAndCannotSelectAnUndiscoveredFault() throws {
        let (state, definitions) = try fixture()
        let item = state.player.inventory[0], definition = definitions[0]
        let plan = try RepairPlan(item: item, definition: definition, selecting: [.drift])
        let result = try RepairEngine().apply(itemID: item.id, selection: [.drift], expectedCost: plan.cost, state: state, definitions: definitions)
        #expect(result.player.inventory[0].knownActiveDefects == [.damagedPort])
        #expect(throws: TradingError.unavailable) { try RepairPlan(item: item, definition: definition, selecting: [.batteryWear]) }
        #expect(throws: TradingError.unavailable) { try RepairPlan(item: result.player.inventory[0], definition: definition, selecting: [.drift]) }
        let alteredTruth = ItemInstance(id: item.id, definitionID: item.definitionID, condition: item.condition,
            hiddenDefects: [.drift, .damagedPort, .storageFailure], revealedDefects: item.revealedDefects, inspected: true)
        #expect(try RepairPlan(item: alteredTruth, definition: definition, selecting: [.drift]) == plan)
    }

    @Test func staleOrUnaffordablePlansDoNotPartiallyRepairAnything() throws {
        var (state, definitions) = try fixture()
        let item = state.player.inventory[0]
        let plan = try RepairPlan(item: item, definition: definitions[0], selecting: [.drift, .damagedPort])
        #expect(throws: TradingError.quoteChanged) { try RepairEngine().apply(itemID: item.id, selection: [.drift, .damagedPort], expectedCost: plan.cost.adding(Money(minorUnits: 1)), state: state, definitions: definitions) }
        state.player.cash = try plan.cost.subtracting(Money(minorUnits: 1))
        let before = state
        #expect(throws: TradingError.insufficientCash) { try RepairEngine().apply(itemID: item.id, selection: [.drift, .damagedPort], expectedCost: plan.cost, state: state, definitions: definitions) }
        #expect(state == before)
        #expect(throws: TradingError.unavailable) { try RepairEngine().apply(itemID: item.id, selection: [], expectedCost: .zero, state: state, definitions: definitions) }
    }

    @Test func demandChangesTheEstimateButNotTheBillAndListedStockStaysProtected() throws {
        let (state, definitions) = try fixture()
        let item = state.player.inventory[0]
        let quiet = try RepairPlan(item: item, definition: definitions[0], selecting: [.drift, .damagedPort], marketBasisPoints: 8_000)
        let busy = try RepairPlan(item: item, definition: definitions[0], selecting: [.drift, .damagedPort], marketBasisPoints: 12_000)
        #expect(quiet.cost == busy.cost)
        #expect(quiet.estimatedRecovery < busy.estimatedRecovery)
        let listed = try ResaleEngine().create(itemID: item.id, askingPrice: Money(minorUnits: 5_000), state: state, definitions: definitions, now: .now)
        #expect(throws: TradingError.self) { try RepairEngine().apply(itemID: item.id, selection: [.drift, .damagedPort], expectedCost: quiet.cost, state: listed, definitions: definitions) }
    }
}
