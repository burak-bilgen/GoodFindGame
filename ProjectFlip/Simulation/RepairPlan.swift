import Foundation

/// A selection of earned findings, priced together using the ordinary repair rules.
/// Acquisition costs, hidden faults and inspection evidence never select work.
struct RepairPlan: Equatable {
    let defects: [Defect]
    let cost: Money
    let estimatedRecovery: Money
    var estimatedNetChange: Money { get throws { try estimatedRecovery.subtracting(cost) } }

    init(item: ItemInstance, definition: ItemDefinition, selecting selection: Set<Defect>, marketBasisPoints: Int64 = 10_000) throws {
        guard item.inspected, item.definitionID == definition.id,
              selection.isSubset(of: Set(item.knownActiveDefects)) else { throw TradingError.unavailable }
        // Selection order cannot change the bill. Reprice after each repair so
        // compounded defect penalties are not counted twice.
        defects = selection.sorted { $0.rawValue < $1.rawValue }
        var projected = item
        var total = Money.zero
        for defect in defects {
            let quote = try RepairQuote(item: projected, definition: definition, defect: defect, marketBasisPoints: marketBasisPoints)
            total = try total.adding(quote.cost)
            projected.repairedDefects = (projected.repairedDefects ?? []) + [defect]
        }
        cost = total
        let engine = InspectionEngine()
        estimatedRecovery = max(.zero, try engine.estimatedValue(item: projected, definition: definition, marketBasisPoints: marketBasisPoints)
            .subtracting(engine.estimatedValue(item: item, definition: definition, marketBasisPoints: marketBasisPoints)))
    }
}

extension RepairEngine {
    func apply(itemID: ItemID, selection: Set<Defect>, expectedCost: Money, state: GameSnapshot, definitions: [ItemDefinition]) throws -> GameSnapshot {
        guard !selection.isEmpty, let item = state.player.inventory.first(where: { $0.id == itemID }),
              let definition = definitions.first(where: { $0.id == item.definitionID }) else { throw TradingError.unavailable }
        let plan = try RepairPlan(item: item, definition: definition, selecting: selection, marketBasisPoints: state.marketMultiplier(for: definition))
        guard plan.cost == expectedCost else { throw TradingError.quoteChanged }
        guard state.player.cash >= plan.cost else { throw TradingError.insufficientCash }
        // Mutate a private copy and commit once; a later failed job never charges
        // the player for an incomplete basket.
        var next = state
        for defect in plan.defects {
            next = try repair(itemID: itemID, defect: defect, state: next, definitions: definitions)
        }
        return next
    }
}
