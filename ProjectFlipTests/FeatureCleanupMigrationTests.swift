import Foundation
import Testing
@testable import ProjectFlip

struct FeatureCleanupMigrationTests {
    @Test func legacyDisplayAndReputationAreRemovedWithoutChangingOwnedGoodsOrOffers() throws {
        let definitions = try SeedContent.load().items
        var original = GameSnapshot(schemaVersion: 1, player: PlayerState(cash: Money(minorUnits: 20_000), inventoryCapacity: 8), market: [], generation: 42)
        original.player.inventory = ["retro-0", "gaming-0"].map {
            var item = ItemInstance(id: ItemID($0), definitionID: $0, condition: 60, hiddenDefects: [], inspected: true)
            item.purchasePrice = Money(minorUnits: 4_000)
            return item
        }
        let releasedID = original.player.inventory[0].id
        original = try ResaleEngine().create(itemID: original.player.inventory[1].id, askingPrice: Money(minorUnits: 5_000), state: original, definitions: definitions, now: .distantPast)
        original = try BuyerEngine().generateOffer(listingID: original.playerListings[0].id, state: original, definitions: definitions)
        var object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(original)) as? [String: Any])
        object["collections"] = ["displayed": [releasedID.rawValue], "completedBefore": ["chapter"], "focus": "chapter"]
        var player = try #require(object["player"] as? [String: Any]); player["reputation"] = 99; object["player"] = player
        let legacy = try JSONSerialization.data(withJSONObject: object)
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let repository = SaveRepository(url: directory.appendingPathComponent("save.json"))
        try legacy.write(to: repository.url)
        let loaded = try #require(try repository.load())
        #expect(loaded == original)
        #expect(try repository.load() == original)
        #expect(try Data(contentsOf: repository.url.appendingPathExtension("pre-feature-cleanup.json")) == legacy)
        #expect(ItemTransfer.available(releasedID, state: loaded))
        #expect(!ItemTransfer.available(loaded.player.inventory[1].id, state: loaded))
        #expect(!RecoveryEngine.canBegin(loaded))
        let listed = try ResaleEngine().create(itemID: releasedID, askingPrice: Money(minorUnits: 5_000), state: loaded, definitions: definitions, now: .distantPast)
        #expect(listed.playerListings.count == loaded.playerListings.count + 1)
        let liquidated = try RecoveryEngine.liquidate(releasedID, state: loaded, definitions: definitions, now: .distantPast)
        #expect(liquidated.player.inventory.count == loaded.player.inventory.count - 1)
        let saved = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: repository.url)) as? [String: Any])
        #expect(saved["collections"] == nil)
        #expect((saved["player"] as? [String: Any])?["reputation"] == nil)
    }

    @Test func retiredCollectorAchievementRemainsValidButIsNotAnActiveGoal() throws {
        var journal = AchievementJournal()
        journal.merge([.collector: 100])
        try journal.validate()
        #expect(journal.progress[CompetitionIDs.achievement(.collector)] == 100)
        #expect(!TradingAchievement.available.contains(.collector))
    }
}
