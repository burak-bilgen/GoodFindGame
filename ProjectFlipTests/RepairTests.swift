import Foundation
import Testing
@testable import ProjectFlip

struct RepairTests {
    private func fixture() throws -> (GameSnapshot, [ItemDefinition]) {
        let definitions = try SeedContent.load().items
        var state = try GameSnapshot.fresh(definitions: definitions)
        var item = ItemInstance(id: ItemID("repair-test"), definitionID: definitions[0].id, condition: 85, hiddenDefects: [.drift, .damagedPort], revealedDefects: [.drift], inspected: true, purchasePrice: Money(minorUnits: 100_000))
        item.facts = ItemFacts.generate(for: item, definition: definitions[0])
        state.player.inventory = [item]
        return (state, definitions)
    }
    @Test func repairChargesOncePreservesEvidenceAndImprovesActualResaleValue() throws {
        let (state, definitions) = try fixture()
        let original = state.player.inventory[0]
        let quote = try RepairQuote(item: original, definition: definitions[0], defect: .drift)
        let repaired = try RepairEngine().repair(itemID: original.id, defect: .drift, state: state, definitions: definitions)
        let item = repaired.player.inventory[0]
        #expect(item.hiddenDefects == original.hiddenDefects && item.facts == original.facts)
        #expect(item.activeDefects == [.damagedPort])
        #expect(item.knownActiveDefects.isEmpty)
        #expect(item.repairCost == quote.cost)
        #expect(try repaired.player.cash == state.player.cash.subtracting(quote.cost))
        #expect(try PricingEngine.fairValue(of: item, definition: definitions[0]) > PricingEngine.fairValue(of: original, definition: definitions[0]))
        #expect(throws: TradingError.self) { try RepairEngine().repair(itemID: item.id, defect: .drift, state: repaired, definitions: definitions) }
        try item.validateFacts()
        #expect(try JSONDecoder().decode(GameSnapshot.self, from: JSONEncoder().encode(repaired)) == repaired)
        let listed = try ResaleEngine().create(itemID: item.id, askingPrice: Money(minorUnits: 200_000), state: repaired, definitions: definitions, now: .now)
        let offered = try BuyerEngine().generateOffer(listingID: listed.playerListings[0].id, state: listed, definitions: definitions)
        let settled = try BuyerEngine().accept(listingID: listed.playerListings[0].id, state: offered, now: .now)
        let record = try TradeRecord(listing: settled.playerListings[0])
        #expect(record.repairCost == quote.cost)
        #expect(try record.totalCost == original.purchasePrice.adding(quote.cost))
    }
    @Test func changingDemandChangesThePotentialReturnButNeverRepricesTheService() throws {
        let (state, definitions) = try fixture()
        let item = state.player.inventory[0]
        let quiet = try RepairQuote(item: item, definition: definitions[0], defect: .drift, marketBasisPoints: 8_000)
        let busy = try RepairQuote(item: item, definition: definitions[0], defect: .drift, marketBasisPoints: 12_000)
        #expect(quiet.cost == busy.cost)
        #expect(quiet.estimatedRecovery < busy.estimatedRecovery)
    }
    @Test func repairEconomicsIncludeWorthwhileAndUnprofitableJobs() throws {
        let definitions = try SeedContent.load().items
        var worthwhile = false
        var uneconomical = false
        for definition in definitions {
            for defect in definition.possibleDefects {
                let item = ItemInstance(id: ItemID("quote"), definitionID: definition.id, condition: 80, hiddenDefects: [defect], revealedDefects: [defect], inspected: true)
                let quote = try RepairQuote(item: item, definition: definition, defect: defect)
                worthwhile = worthwhile || quote.cost < quote.estimatedRecovery
                uneconomical = uneconomical || quote.cost > quote.estimatedRecovery
            }
        }
        #expect(worthwhile && uneconomical)
    }
    @Test func quotesNeverLeakUnknownFaultsAndServiceRejectsInvalidStates() throws {
        var (state, definitions) = try fixture()
        let original = state.player.inventory[0]
        let quote = try RepairQuote(item: original, definition: definitions[0], defect: .drift)
        var other = original
        other = ItemInstance(id: original.id, definitionID: original.definitionID, condition: original.condition, hiddenDefects: [.drift], revealedDefects: [.drift], inspected: true)
        #expect(try quote == RepairQuote(item: other, definition: definitions[0], defect: .drift))
        #expect(throws: TradingError.self) { try RepairQuote(item: original, definition: definitions[0], defect: .damagedPort) }
        state.player.cash = .zero
        #expect(throws: TradingError.self) { try RepairEngine().repair(itemID: original.id, defect: .drift, state: state, definitions: definitions) }
        state.player.cash = Money(minorUnits: 1_000_000)
        state = try ResaleEngine().create(itemID: original.id, askingPrice: Money(minorUnits: 200_000), state: state, definitions: definitions, now: .now)
        #expect(throws: TradingError.self) { try RepairEngine().repair(itemID: original.id, defect: .drift, state: state, definitions: definitions) }
        state.player.inventory[0].repairedDefects = [.damagedPort]
        #expect(throws: SaveError.self) { try state.player.inventory[0].validateFacts() }
    }
}
