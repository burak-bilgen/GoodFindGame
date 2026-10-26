import Foundation
import Testing
@testable import ProjectFlip

struct ShopRemovalMigrationTests {
    private func fixture(level: Int?, investment: Int64? = nil) throws -> (GameSnapshot, Data) {
        let state = GameSnapshot(schemaVersion: 1, player: PlayerState(cash: Money(minorUnits: 50_000), inventoryCapacity: 8), market: [], generation: 42)
        var object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(state)) as? [String: Any])
        var shop: [String: Any] = ["style": "bargains", "windowLevel": level ?? 0, "featured": [], "completedSales": [], "invested": ["minorUnits": investment ?? level.map { 15_000 + Int64($0 * ($0 + 1) / 2) * 20_000 } ?? 0]]
        if level != nil { shop["name"] = "Old shop" }
        object["shop"] = shop
        return (state, try JSONSerialization.data(withJSONObject: object))
    }

    @Test(arguments: [nil, 0, 1, 2, 3, 4] as [Int?])
    func refundsActualInvestmentOnceAndKeepsBackup(level: Int?) throws {
        let (original, data) = try fixture(level: level)
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let repository = SaveRepository(url: directory.appendingPathComponent("save.json"))
        try data.write(to: repository.url)
        let migrated = try #require(try repository.load())
        let refund = level.map { 15_000 + Int64($0 * ($0 + 1) / 2) * 20_000 } ?? 0
        var expected = original
        expected.player.cash = try expected.player.cash.adding(Money(minorUnits: refund))
        #expect(migrated == expected)
        #expect(try repository.load() == expected)
        #expect(try Data(contentsOf: repository.url.appendingPathExtension("pre-shop-removal.json")) == data)
        let saved = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: repository.url)) as? [String: Any])
        #expect(saved["shop"] == nil)
        let decoded = try JSONDecoder().decode(GameSnapshot.self, from: JSONEncoder().encode(migrated))
        #expect(decoded == expected)
    }

    @Test func invalidInvestmentDoesNotRewriteSave() throws {
        let (_, data) = try fixture(level: 1, investment: 999_999)
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let repository = SaveRepository(url: directory.appendingPathComponent("save.json"))
        try data.write(to: repository.url)
        #expect(throws: SaveError.self) { try repository.load() }
        #expect(try Data(contentsOf: repository.url) == data)
    }
}
