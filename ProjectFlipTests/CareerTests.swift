import Foundation
import Testing
@testable import ProjectFlip

struct CareerTests {
    @Test func careerRecordsLossesExactlyOnceAndNeverRaisesBuyerBudgets() throws {
        let offered = try BuyerTests.offeredState()
        var sold = try BuyerEngine().accept(listingID: offered.playerListings[0].id, state: offered, now: .distantPast)
        sold.playerListings[0].itemSnapshot?.purchasePrice = Money(minorUnits: 100_000)
        CareerEngine.refresh(&sold)
        #expect(sold.career.creditedItems.count == 1)
        #expect(try TradeRecord(listing: sold.playerListings[0]).netProfit < .zero)
        CareerEngine.refresh(&sold)
        #expect(sold.career.creditedItems.count == 1)
        var low = try ResaleTests.inspectedState()
        let definitions = try SeedContent.load().items
        low = try ResaleEngine().create(itemID: low.player.inventory[0].id, askingPrice: Money(minorUnits: 4_000), state: low, definitions: definitions, now: .distantPast)
        var high = low; high.career.creditedItems = Set((0..<24).map { ItemID("past-\($0)") })
        #expect(try BuyerEngine().generateOffer(listingID: low.playerListings[0].id, state: low, definitions: definitions).playerListings == BuyerEngine().generateOffer(listingID: high.playerListings[0].id, state: high, definitions: definitions).playerListings)
    }

    @Test func accessAndSpecialistEndorsementRequireDifferentKindsOfProgress() throws {
        let definitions = try SeedContent.load().items
        var state = try GameSnapshot.fresh(definitions: definitions)
        let premium = try #require(definitions.first { $0.valueTier == .premium })
        #expect(!CareerEngine.canAccess(premium, state: state))
        state.career.creditedItems = Set((0..<8).map { ItemID("trade-\($0)") })
        state.inspectionKnowledge.learn(8, in: .cameras)
        #expect(CareerEngine.canAccess(premium, state: state))
        var knowledge = InspectionKnowledge()
        knowledge.learn(1_000, in: .cameras)
        #expect(knowledge.level(in: .cameras) == 3)
        for index in 0..<6 {
            let item = ItemInstance(id: ItemID("case-\(index)"), definitionID: "cameras-\(index)", condition: 80, hiddenDefects: [.lensFungus, .sensorDamage, .shutterWear], revealedDefects: [.lensFungus, .sensorDamage, .shutterWear], inspected: true)
            knowledge.record(item, category: .cameras)
        }
        #expect(knowledge.level(in: .cameras) == 4)
        #expect(knowledge.modelCount(in: .cameras) == 6)
        #expect(knowledge.diagnosticCount(in: .cameras) == 3)
        #expect(knowledge.level(in: .gaming) == 0)
        try knowledge.validate()
    }
    @Test func existingFirmAgreementSurvivesTheNewCareerGate() throws {
        let definitions = try SeedContent.load().items
        var original = try GameSnapshot.fresh(definitions: definitions)
        let listing = original.market[7]
        var agreement = NegotiationState(listingID: listing.id, patience: 100)
        agreement.agreedPrice = listing.askingPrice
        original.conversations = [agreement]
        var raw = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(original)) as? [String: Any])
        raw.removeValue(forKey: "career")
        let legacy = try JSONDecoder().decode(GameSnapshot.self, from: JSONSerialization.data(withJSONObject: raw))
        #expect(legacy.career.legacyAgreements?.contains(listing.id) == true)
        let purchased = try SimulationActions(timing: .instant).purchase(listingID: listing.id, state: legacy, now: .now)
        #expect(purchased.shipments.count == 1)
    }

}
