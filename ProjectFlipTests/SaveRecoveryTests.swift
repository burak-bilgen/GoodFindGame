import Foundation
import Testing
@testable import ProjectFlip

struct SaveRecoveryTests {
    @Test func explicitRecoveryPreservesDamagedFileAndNeverReplacesGoodBackup() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let repository = SaveRepository(url: directory.appendingPathComponent("save.json"))
        let first = try GameSnapshot.fresh(definitions: SeedContent.load().items)
        try repository.save(first)
        var second = first; second.player.cash = Money(minorUnits: 120_000)
        try repository.save(second)
        let backup = try Data(contentsOf: repository.backupURL)
        let damaged = Data("damaged primary".utf8); try damaged.write(to: repository.url)
        #expect(throws: (any Error).self) { try repository.load() }
        #expect(try Data(contentsOf: repository.url) == damaged)
        #expect(repository.canRestoreBackup)
        #expect(try repository.restoreBackup() == first)
        #expect(try repository.load() == first)
        #expect(try Data(contentsOf: repository.backupURL) == backup)
        let quarantines = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil).filter { $0.lastPathComponent.contains("before-restore") }
        #expect(quarantines.count == 1)
        #expect(try Data(contentsOf: #require(quarantines.first)) == damaged)
    }

    @Test func invalidBackupCannotReplacePrimaryAndInvalidPrimaryCannotPoisonGoodBackup() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let repository = SaveRepository(url: directory.appendingPathComponent("save.json"))
        let first = try GameSnapshot.fresh(definitions: SeedContent.load().items)
        try repository.save(first)
        let invalid = Data("invalid".utf8); try invalid.write(to: repository.backupURL)
        #expect(!repository.canRestoreBackup)
        #expect(throws: (any Error).self) { try repository.restoreBackup() }
        #expect(try repository.load() == first)
        var second = first; second.player.cash = Money(minorUnits: 150_000); try repository.save(second)
        let goodBackup = try Data(contentsOf: repository.backupURL)
        try invalid.write(to: repository.url)
        try repository.save(second)
        #expect(try Data(contentsOf: repository.backupURL) == goodBackup)
    }
}
