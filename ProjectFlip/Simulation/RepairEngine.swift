import Foundation

/// A single immediate service decision. Original inspection evidence stays immutable.
struct RepairQuote: Equatable {
    let defect: Defect
    let cost: Money
    let estimatedRecovery: Money
    init(item: ItemInstance, definition: ItemDefinition, defect: Defect, marketBasisPoints: Int64 = 10_000) throws {
        guard item.inspected, item.revealedDefects.contains(defect), !(item.repairedDefects ?? []).contains(defect) else { throw TradingError.unavailable }
        self.defect = defect
        let engine = InspectionEngine()
        let before = try engine.estimatedValue(item: item, definition: definition, marketBasisPoints: marketBasisPoints)
        var repaired = item
        repaired.repairedDefects = (item.repairedDefects ?? []) + [defect]
        let after = try engine.estimatedValue(item: repaired, definition: definition, marketBasisPoints: marketBasisPoints)
        estimatedRecovery = max(.zero, try after.subtracting(before))
        // Some jobs are economical; others cost more than the likely value recovered.
        let labor = Int64(4_500 + SeededRandom.seed(for: "repair-\(defect.rawValue)") % 7_001)
        // Service cost is anchored to the item, so a demand event cannot reprice a tap.
        let neutralBefore = try engine.estimatedValue(item: item, definition: definition)
        let neutralAfter = try engine.estimatedValue(item: repaired, definition: definition)
        let serviceBasis = max(.zero, try neutralAfter.subtracting(neutralBefore))
        cost = try serviceBasis.scaled(byBasisPoints: labor).adding(Money(minorUnits: 400))
    }
}

struct RepairEngine {
    func repair(itemID: ItemID, defect: Defect, state: GameSnapshot, definitions: [ItemDefinition]) throws -> GameSnapshot {
        guard let index = state.player.inventory.firstIndex(where: { $0.id == itemID }),
              let definition = definitions.first(where: { $0.id == state.player.inventory[index].definitionID }) else { throw TradingError.unavailable }
        guard !state.playerListings.contains(where: { $0.itemID == itemID && $0.status == .active }),
              !state.inspectionJobs.contains(where: { $0.itemID == itemID && $0.status == .pending }) else { throw TradingError.alreadyDone }
        let item = state.player.inventory[index]
        let quote = try RepairQuote(item: item, definition: definition, defect: defect, marketBasisPoints: state.marketMultiplier(for: definition))
        guard state.player.cash >= quote.cost else { throw TradingError.insufficientCash }
        var next = state
        next.player.cash = try next.player.cash.subtracting(quote.cost)
        next.player.inventory[index].repairCost = try item.repairCost.adding(quote.cost)
        next.player.inventory[index].repairedDefects = (item.repairedDefects ?? []) + [defect]
        return next
    }
}
