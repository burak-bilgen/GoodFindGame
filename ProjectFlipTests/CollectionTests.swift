import Foundation
import Testing
@testable import ProjectFlip

struct CollectionTests {
    @Test func completionRequiresCurrentOwnershipAndNeverPrintsCashOrTrust() throws {
        let definitions = try SeedContent.load().items
        var state = try GameSnapshot.fresh(definitions: definitions)
        state.player.inventory = ["retro-0", "retro-2", "retro-8"].map { ItemInstance(id: ItemID($0), definitionID: $0, condition: 60, hiddenDefects: [], inspected: true) }
        let cash = state.player.cash
        for item in state.player.inventory { state = try CollectionEngine.toggle(item.id, state: state) }
        let collection = CollectionDefinition.all[0]
        #expect(collection.count(in: state) == 3)
        #expect(state.collections.completedBefore == ["chapter"])
        #expect(state.player.cash == cash && state.player.reputation == 0)
        #expect(state.player.inventory.count == 3)
        let id = state.player.inventory[0].id
        #expect(throws: TradingError.self) { try ResaleEngine().create(itemID: id, askingPrice: Money(minorUnits: 10_000), state: state, definitions: definitions, now: .distantPast) }
        state = try CollectionEngine.toggle(id, state: state)
        #expect(collection.count(in: state) == 2)
        #expect(state.collections.completedBefore.contains("chapter"))
        state = try CollectionEngine.toggle(id, state: state)
        #expect(state.player.cash == cash)
        #expect(try JSONDecoder().decode(GameSnapshot.self, from: JSONEncoder().encode(state)) == state)
        try CollectionEngine.validate(state)
        state.player.inventory.removeAll()
        #expect(throws: SaveError.self) { try CollectionEngine.validate(state) }
    }
}
