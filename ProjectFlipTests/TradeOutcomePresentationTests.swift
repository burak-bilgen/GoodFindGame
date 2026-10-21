import Foundation
import Testing
@testable import ProjectFlip

struct TradeOutcomePresentationTests {
    private func record(for item: ItemInstance, soldFor: Int64 = 50_000) throws -> TradeRecord {
        var listing = PlayerListing(id: ListingID("outcome-test"), itemID: item.id, askingPrice: Money(minorUnits: soldFor), createdAt: .distantPast, views: 0, favorites: 0)
        listing.status = .sold
        listing.itemSnapshot = item
        listing.soldPrice = Money(minorUnits: soldFor)
        listing.soldAt = .distantPast
        return try TradeRecord(listing: listing)
    }

    @Test func undiscoveredTruthCannotChangeWhatTheLossTeaches() throws {
        let unknown = ItemInstance(id: ItemID("outcome"), definitionID: "gaming-0", condition: 80, hiddenDefects: [.drift], revealedDefects: [], inspected: true, purchasePrice: Money(minorUnits: 100_000))
        let clean = ItemInstance(id: unknown.id, definitionID: unknown.definitionID, condition: unknown.condition, hiddenDefects: [], inspected: true, purchasePrice: unknown.purchasePrice)
        let settled = try record(for: unknown)
        let result = TradeOutcomePresentation(record: settled, item: unknown)
        #expect(result.defects.isEmpty)
        #expect(result.lessonKey == "result.lesson.price")
        #expect(result == TradeOutcomePresentation(record: settled, item: clean))
    }
    @Test func onlyDiscoveredUnrepairedFaultsBelongInTheDebrief() throws {
        var item = ItemInstance(id: ItemID("outcome"), definitionID: "gaming-0", condition: 80, hiddenDefects: [.drift, .damagedPort, .overheating], revealedDefects: [.drift, .damagedPort], inspected: true, purchasePrice: Money(minorUnits: 100_000))
        item.repairedDefects = [.damagedPort]
        let result = TradeOutcomePresentation(record: try record(for: item), item: item)
        #expect(result.defects == [.drift])
        #expect(result.lessonKey == "result.lesson.fault")
    }

    @Test func serviceLossNamesOnlyTheChargesThatActuallyConsumedTheMargin() throws {
        for (inspection, repair, lesson) in [(20_000, 0, "result.lesson.inspection"), (0, 30_000, "result.lesson.repair"), (20_000, 30_000, "result.lesson.costs")] {
            var item = ItemInstance(id: ItemID("outcome"), definitionID: "gaming-0", condition: 80, hiddenDefects: [], inspected: true, purchasePrice: Money(minorUnits: 100_000))
            item.inspectionCost = Money(minorUnits: Int64(inspection))
            item.repairCost = Money(minorUnits: Int64(repair))
            let result = TradeOutcomePresentation(record: try record(for: item, soldFor: 110_000), item: item)
            #expect(result.lessonKey == lesson)
        }
    }

    @Test func knownFaultDoesNotTurnAWinOrBreakEvenIntoALossLesson() throws {
        let item = ItemInstance(id: ItemID("outcome"), definitionID: "gaming-0", condition: 80, hiddenDefects: [.drift], revealedDefects: [.drift], inspected: true, purchasePrice: Money(minorUnits: 100_000))
        #expect(TradeOutcomePresentation(record: try record(for: item, soldFor: 100_001), item: item).lessonKey == "result.lesson.win")
        #expect(TradeOutcomePresentation(record: try record(for: item, soldFor: 100_000), item: item).lessonKey == "result.lesson.even")
    }

    @Test func missingLegacyContextDoesNotInventADiagnosis() throws {
        let item = ItemInstance(id: ItemID("outcome"), definitionID: "gaming-0", condition: 80, hiddenDefects: [.drift], inspected: true, purchasePrice: Money(minorUnits: 100_000))
        let result = TradeOutcomePresentation(record: try record(for: item), item: nil)
        #expect(result.defects.isEmpty)
        #expect(result.lessonKey == "result.lesson.price")
    }

    @Test func settlementAndSaveReloadPreserveTheSameEarnedEvidenceAndLesson() throws {
        let definitions = try SeedContent.load().items
        var state = try GameSnapshot.fresh(definitions: definitions)
        var item = ItemInstance(id: ItemID("outcome"), definitionID: definitions[0].id, condition: 79, hiddenDefects: [.drift, .damagedPort], revealedDefects: [.damagedPort], inspected: true, purchasePrice: Money(minorUnits: 100_000))
        item.facts = ItemFacts.generate(for: item, definition: definitions[0])
        state.player.inventory = [item]
        state = try ResaleEngine().create(itemID: item.id, askingPrice: Money(minorUnits: 50_000), state: state, definitions: definitions, now: .distantPast)
        let listingID = try #require(state.playerListings.first?.id)
        state = try BuyerEngine().generateOffer(listingID: listingID, state: state, definitions: definitions)
        state = try BuyerEngine().accept(listingID: listingID, state: state, now: .distantPast)
        let settled = try #require(state.playerListings.first)
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let repository = SaveRepository(url: root.appendingPathComponent("save.json"))
        try repository.save(state)
        let restored = try repository.load()
        let loaded = try #require(restored)
        let reopened = try #require(loaded.playerListings.first)
        #expect(reopened.itemSnapshot?.hiddenDefects == [.drift, .damagedPort])
        #expect(reopened.itemSnapshot?.revealedDefects == [.damagedPort])
        let original = TradeOutcomePresentation(record: try TradeRecord(listing: settled), item: settled.itemSnapshot)
        let receipt = TradeOutcomePresentation(record: try TradeRecord(listing: reopened), item: reopened.itemSnapshot)
        #expect(original == receipt)
        #expect(receipt.defects == [.damagedPort])
        #expect(receipt.lessonKey == "result.lesson.fault")
    }

}
