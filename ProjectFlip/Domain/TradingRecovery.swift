import Foundation

struct RecoveryProgress: Codable, Equatable {
    var itemID: ItemID?
    var sequence: UInt64 = 0
    var recovered: Bool?
    var commissionsEarned = Money.zero
}

enum RecoveryEngine {
    static let capitalFloor = Money(minorUnits: 7_500)
    static let serviceFee = Money(minorUnits: 1_500)
    static func canBegin(_ state: GameSnapshot) -> Bool {
        state.player.cash < capitalFloor && state.recovery.itemID == nil &&
        !state.shipments.contains { $0.status == .pending } &&
        state.player.inventory.isEmpty &&
        state.player.inventory.count < state.player.inventoryCapacity
    }
    static func begin(state: GameSnapshot, definitions: [ItemDefinition], now: Date) throws -> GameSnapshot {
        guard canBegin(state), state.recovery.sequence < UInt64.max,
              let definition = definitions.first(where: { $0.id == "gaming-0" }) else { throw TradingError.unavailable }
        var next = state; next.recovery.sequence += 1
        let id = ItemID("consignment-\(state.simulationID)-\(next.recovery.sequence)")
        var item = ItemInstance(id: id, definitionID: definition.id, condition: 80, hiddenDefects: [], acquiredAt: now)
        item.facts = ItemFacts.generate(for: item, definition: definition)
        next.player.inventory.append(item); next.recovery.itemID = id
        return next
    }
    static func complete(state: GameSnapshot, now: Date) throws -> GameSnapshot {
        guard let id = state.recovery.itemID, let item = state.player.inventory.first(where: { $0.id == id && $0.inspected }),
              !state.inspectionJobs.contains(where: { $0.itemID == id && $0.status == .pending }) else { throw TradingError.unavailable }
        let amount = min(serviceFee, max(.zero, try capitalFloor.subtracting(state.player.cash)))
        var next = state
        next.player.inventory.removeAll { $0.id == id }; next.recovery.itemID = nil
        next.player.cash = try next.player.cash.adding(amount)
        next.recovery.commissionsEarned = try next.recovery.commissionsEarned.adding(amount)
        if next.player.cash >= capitalFloor { next.recovery.recovered = true }
        var record = PlayerListing(id: ListingID("commission-\(id.rawValue)"), itemID: id, askingPrice: max(Money(minorUnits: 1), amount), createdAt: now, views: 0, favorites: 0)
        record.status = .sold; record.itemSnapshot = item; record.soldPrice = amount; record.soldAt = now; record.saleKind = .consignment
        next.playerListings.append(record)
        return next
    }
    static func liquidationQuote(_ item: ItemInstance, definition: ItemDefinition, state: GameSnapshot) throws -> Money {
        guard item.id != state.recovery.itemID, ItemTransfer.available(item.id, state: state) else { throw TradingError.unavailable }
        // A guaranteed exit below the player's cost, not a truth-revealing bid.
        return min(try item.purchasePrice.scaled(byBasisPoints: 6_500), try definition.baseValue.scaled(byBasisPoints: state.marketConfiguration.multiplier(for: definition.category)).scaled(byBasisPoints: 3_500))
    }
    static func liquidate(_ itemID: ItemID, state: GameSnapshot, definitions: [ItemDefinition], now: Date) throws -> GameSnapshot {
        guard let item = state.player.inventory.first(where: { $0.id == itemID }), let definition = definitions.first(where: { $0.id == item.definitionID }) else { throw TradingError.unavailable }
        let amount = try liquidationQuote(item, definition: definition, state: state)
        guard amount > .zero else { throw TradingError.unavailable }
        var next = state
        next.player.inventory.removeAll { $0.id == itemID }; next.player.cash = try next.player.cash.adding(amount)
        var record = PlayerListing(id: ListingID("liquidation-\(itemID.rawValue)"), itemID: itemID, askingPrice: amount, createdAt: now, views: 0, favorites: 0)
        record.status = .sold; record.itemSnapshot = item; record.soldPrice = amount; record.soldAt = now; record.saleKind = .liquidation
        next.playerListings.append(record)
        return next
    }
    static func validate(_ state: GameSnapshot) throws {
        guard state.recovery.commissionsEarned >= .zero,
              state.recovery.itemID.map({ id in state.player.inventory.contains { $0.id == id && $0.purchasePrice == .zero } && !state.playerListings.contains { $0.itemID == id && $0.status == .active } }) ?? true else { throw SaveError.invalidSave }
    }
}

extension GameStore {
    func beginRecovery() throws { try commit(RecoveryEngine.begin(state: snapshot, definitions: definitions, now: snapshot.lastSimulationAt ?? .now)) }
    func completeRecovery() throws { try commit(RecoveryEngine.complete(state: snapshot, now: snapshot.lastSimulationAt ?? .now)) }
    func liquidate(_ id: ItemID) throws { try catchUp(); try commit(RecoveryEngine.liquidate(id, state: snapshot, definitions: definitions, now: snapshot.lastSimulationAt ?? .now)) }
}
