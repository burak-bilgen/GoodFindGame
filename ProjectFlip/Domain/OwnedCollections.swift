import Foundation

struct CollectionProgress: Codable, Equatable {
    var displayed: Set<ItemID> = []
    var completedBefore: Set<String> = []
    var focus: String?
}

struct CollectionDefinition: Identifiable {
    let id: String
    let models: [String]
    static let all = [Self(id: "chapter", models: ["retro-0", "retro-2", "retro-8"]), Self(id: "focal", models: ["cameras-10", "cameras-8", "cameras-9"])]
    var titleKey: String { "collection.\(id).title" }
    func pieces(in state: GameSnapshot) -> [ItemInstance] {
        state.player.inventory.filter { state.collections.displayed.contains($0.id) && models.contains($0.definitionID) }
    }
    func count(in state: GameSnapshot) -> Int { Set(pieces(in: state).map(\.definitionID)).count }
}

enum CollectionEngine {
    static func toggle(_ itemID: ItemID, state: GameSnapshot) throws -> GameSnapshot {
        var next = state
        if next.collections.displayed.contains(itemID) { next.collections.displayed.remove(itemID); return next }
        guard let item = state.player.inventory.first(where: { $0.id == itemID }), item.inspected,
              CollectionDefinition.all.contains(where: { $0.models.contains(item.definitionID) }),
              ItemTransfer.available(itemID, state: state) else { throw TradingError.unavailable }
        next.collections.displayed.insert(itemID)
        for collection in CollectionDefinition.all where collection.count(in: next) == collection.models.count {
            next.collections.completedBefore.insert(collection.id)
        }
        return next
    }
    static func validate(_ state: GameSnapshot) throws {
        let ids = Set(state.player.inventory.map(\.id))
        let sets = Set(CollectionDefinition.all.map(\.id))
        guard state.player.inventory.filter({ state.collections.displayed.contains($0.id) }).allSatisfy({ item in item.inspected && CollectionDefinition.all.contains(where: { collection in collection.models.contains(item.definitionID) }) }),
              state.collections.displayed.isSubset(of: ids), state.collections.completedBefore.isSubset(of: sets),
              state.collections.focus.map({ sets.contains($0) }) ?? true,
              !state.playerListings.contains(where: { $0.status == .active && state.collections.displayed.contains($0.itemID) }) else { throw SaveError.invalidSave }
    }
}

extension GameStore {
    func toggleDisplay(_ itemID: ItemID) throws { try commit(CollectionEngine.toggle(itemID, state: snapshot)) }
    func focusCollection(_ id: String) throws {
        guard CollectionDefinition.all.contains(where: { $0.id == id }) else { throw TradingError.unavailable }
        var next = snapshot; next.collections.focus = id; try commit(next)
    }
}
