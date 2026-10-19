import Foundation

struct InspectionEngine {
    let professionalCost: Money
    init(professionalCost: Money = GameBalanceConfig.current.professionalInspectionCost) { self.professionalCost = professionalCost }

    func inspect(itemID: ItemID, professionally: Bool, state: GameSnapshot, category: ItemCategory = .gaming) throws -> GameSnapshot {
        guard let index = state.player.inventory.firstIndex(where: { $0.id == itemID }) else { throw TradingError.unavailable }
        let item = state.player.inventory[index]
        if professionally {
            var next = try chargeProfessional(itemID: itemID, state: state)
            completeProfessional(itemID: itemID, category: category, state: &next)
            return next
        }
        guard state.inspectionKnowledge.canInspect(item, category: category) else { throw TradingError.alreadyDone }
        var next = state
        let knowledge = state.inspectionKnowledge
        let level = knowledge.level(in: category)
        let recognizable = item.hiddenDefects.filter {
            !item.revealedDefects.contains($0) && $0.detectable(condition: item.condition, level: level, hasTools: knowledge.tools.contains(category))
        }.prefix(1 + level)
        next.player.inventory[index].revealedDefects += recognizable
        next.player.inventory[index].inspected = true
        next.inspectionKnowledge.selfInspectionCapabilities[itemID.rawValue] = knowledge.capability(in: category)
        if !item.inspected { next.inspectionKnowledge.learn(1, in: category) }
        return next
    }

    /// Completion is shared by immediate tests and the persisted event resolver. Charging happens at booking.
    func completeProfessional(itemID: ItemID, category: ItemCategory?, state: inout GameSnapshot) {
        guard let index = state.player.inventory.firstIndex(where: { $0.id == itemID }), !state.player.inventory[index].professionallyInspected else { return }
        state.player.inventory[index].professionallyInspected = true
        state.player.inventory[index].inspected = true
        state.player.inventory[index].revealedDefects = state.player.inventory[index].hiddenDefects
        if let category { state.inspectionKnowledge.learn(2, in: category) }
    }

    func buyTools(for category: ItemCategory, state: GameSnapshot) throws -> GameSnapshot {
        guard !state.inspectionKnowledge.tools.contains(category) else { throw TradingError.alreadyDone }
        let cost = InspectionKnowledge.toolCost(for: category)
        guard state.player.cash >= cost else { throw TradingError.insufficientCash }
        var next = state
        next.player.cash = try state.player.cash.subtracting(cost)
        next.inspectionKnowledge.tools.insert(category)
        return next
    }

    func chargeProfessional(itemID: ItemID, state: GameSnapshot) throws -> GameSnapshot {
        guard let index = state.player.inventory.firstIndex(where: { $0.id == itemID }) else { throw TradingError.unavailable }
        guard !state.player.inventory[index].professionallyInspected,
              !state.inspectionJobs.contains(where: { $0.itemID == itemID && $0.status == .pending }) else { throw TradingError.alreadyDone }
        guard state.player.cash >= professionalCost else { throw TradingError.insufficientCash }
        var next = state
        next.player.cash = try state.player.cash.subtracting(professionalCost)
        next.player.inventory[index].inspectionCost = try state.player.inventory[index].inspectionCost.adding(professionalCost)
        return next
    }

    func estimatedValue(item: ItemInstance, definition: ItemDefinition, marketBasisPoints: Int64 = 10_000) throws -> Money {
        let known = ItemInstance(id: item.id, definitionID: item.definitionID, condition: item.condition, hiddenDefects: item.revealedDefects)
        return try PricingEngine.fairValue(of: known, definition: definition, marketBasisPoints: marketBasisPoints)
    }
}
