import Foundation
import Testing
@testable import ProjectFlip

struct InspectionTests {
    @Test func revealStableFactsAndChargeOnlyOnce() throws {
        var state = try PurchaseTests.agreedState()
        state = try PurchaseEngine().buy(listingID: state.market[0].id, state: state, now: .now)
        let original = state.player.inventory[0]
        state.player.inventory[0] = ItemInstance(id: original.id, definitionID: original.definitionID, condition: 90, hiddenDefects: [.drift, .overheating], purchasePrice: original.purchasePrice)
        let basic = try InspectionEngine().inspect(itemID: original.id, professionally: false, state: state)
        #expect(basic.player.cash == state.player.cash)
        #expect(basic.player.inventory[0].revealedDefects.isEmpty)
        let professional = try InspectionEngine().inspect(itemID: original.id, professionally: true, state: basic)
        #expect(professional.player.inventory[0].hiddenDefects == state.player.inventory[0].hiddenDefects)
        #expect(professional.player.inventory[0].revealedDefects == [.drift, .overheating])
        #expect(try professional.player.cash == basic.player.cash.subtracting(InspectionEngine().professionalCost))
        #expect(throws: TradingError.self) { try InspectionEngine().inspect(itemID: original.id, professionally: true, state: professional) }
        #expect(try JSONDecoder().decode(GameSnapshot.self, from: JSONEncoder().encode(professional)) == professional)
    }
}
