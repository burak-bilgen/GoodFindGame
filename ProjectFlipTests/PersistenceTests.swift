import Foundation
import Testing
@testable import ProjectFlip

struct PersistenceTests {
    @Test func roundTripPreservesTruthAndRejectsCorruption() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("save.json")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let repository = SaveRepository(url: url)
        let state = try GameSnapshot.fresh(definitions: SeedContent.load().items)
        try repository.save(state)
        #expect(try repository.load() == state)
        let invalid = Data("broken".utf8)
        try invalid.write(to: url)
        #expect(throws: (any Error).self) { try repository.load() }
        #expect(try Data(contentsOf: url) == invalid)
    }
}
