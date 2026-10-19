import Foundation

struct InspectionEngine {
    let professionalCost: Money
    init(professionalCost: Money = Money(minorUnits: 15_000)) { self.professionalCost = professionalCost }

    func inspect(itemID: ItemID, professionally: Bool, state: GameSnapshot) throws -> GameSnapshot {
        guard let index = state.player.inventory.firstIndex(where: { $0.id == itemID }) else { throw TradingError.unavailable }
        let item = state.player.inventory[index]
        guard professionally ? !item.professionallyInspected : !item.inspected else { throw TradingError.alreadyDone }
        var next = state
        if professionally {
            guard state.player.cash >= professionalCost else { throw TradingError.insufficientCash }
            next.player.cash = try state.player.cash.subtracting(professionalCost)
            next.player.inventory[index].inspectionCost = try item.inspectionCost.adding(professionalCost)
            next.player.inventory[index].professionallyInspected = true
            next.player.inventory[index].revealedDefects = item.hiddenDefects
        } else if item.condition < 80, let visible = item.hiddenDefects.first, !item.revealedDefects.contains(visible) {
            // Phase A self-inspection recognizes one obvious fault. Knowledge/tools deepen later.
            next.player.inventory[index].revealedDefects.append(visible)
        }
        next.player.inventory[index].inspected = true
        return next
    }

    func estimatedValue(item: ItemInstance, definition: ItemDefinition) throws -> Money {
        let known = ItemInstance(id: item.id, definitionID: item.definitionID, condition: item.condition, hiddenDefects: item.revealedDefects)
        return try PricingEngine.fairValue(of: known, definition: definition)
    }
}
