import Foundation
import Testing
@testable import ProjectFlip

struct ClientTests {
    @Test func deliveryPaysOnceReplacesResaleAndRemembersTheClient() throws {
        let definitions = try SeedContent.load().items
        var state = try GameSnapshot.fresh(definitions: definitions)
        let definition = try #require(definitions.first { $0.id == "retro-0" })
        var item = ItemInstance(id: ItemID("client-fixture"), definitionID: definition.id, condition: 85, hiddenDefects: [], inspected: true, professionallyInspected: true, purchasePrice: Money(minorUnits: 5_000))
        item.facts = ItemFacts.generate(for: item, definition: definition)
        item.revealFacts(knowledge: state.inspectionKnowledge, professionally: true)
        state.player.inventory = [item]
        state = try ClientEngine.accept("rowan", state: state)
        #expect(throws: TradingError.self) { try ClientEngine.accept("jules", state: state) }
        let quote = try ClientEngine.quote(item, definition: definition, state: state)
        let cash = state.player.cash
        let delivered = try ClientEngine.fulfill("rowan", itemID: item.id, state: state, definitions: definitions, now: .distantPast)
        #expect(try delivered.player.cash == cash.adding(quote))
        #expect(delivered.clients.completed["rowan"] == 1 && delivered.clients.active == nil)
        #expect(delivered.player.inventory.isEmpty)
        #expect(delivered.career.clientJobs == 1)
        #expect(delivered.career.tier(knowledge: delivered.inspectionKnowledge) == .known)
        #expect(try TradeLedger.records(from: delivered).count == 1)
        #expect(throws: TradingError.self) { try ClientEngine.fulfill("rowan", itemID: item.id, state: delivered, definitions: definitions, now: .distantPast) }
        #expect(try JSONDecoder().decode(GameSnapshot.self, from: JSONEncoder().encode(delivered)) == delivered)
    }
    @Test func requirementsUseEarnedEvidenceAndNeverTakeAnActiveListing() throws {
        let definitions = try SeedContent.load().items
        var state = try GameSnapshot.fresh(definitions: definitions)
        let request = try #require(ClientEngine.request("rowan", state: state))
        var item = ItemInstance(id: ItemID("unverified"), definitionID: "retro-0", condition: 90, hiddenDefects: [.counterfeitBoard], inspected: true)
        #expect(!ClientEngine.qualifies(item, request: request))
        item.professionallyInspected = true; item.revealedDefects = [.counterfeitBoard]
        #expect(!ClientEngine.qualifies(item, request: request))
        item = ItemInstance(id: item.id, definitionID: "retro-0", condition: 90, hiddenDefects: [], inspected: true, professionallyInspected: true)
        state.player.inventory = [item]
        state = try ClientEngine.accept("rowan", state: state)
        state = try ResaleEngine().create(itemID: item.id, askingPrice: Money(minorUnits: 7_000), state: state, definitions: definitions, now: .distantPast)
        #expect(throws: TradingError.self) { try ClientEngine.fulfill("rowan", itemID: item.id, state: state, definitions: definitions, now: .distantPast) }
        var bad = ClientProgress(); bad.completed["rowan"] = -1
        #expect(throws: SaveError.self) { try bad.validate() }
    }
}
