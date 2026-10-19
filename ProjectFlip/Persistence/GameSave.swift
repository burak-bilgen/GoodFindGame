import Foundation

struct GameSnapshot: Codable, Equatable {
    let schemaVersion: Int
    var player: PlayerState
    var market: [MarketplaceListing]
    var generation: UInt64

    static func fresh(definitions: [ItemDefinition], seed: UInt64 = 42, now: Date = .now) throws -> Self {
        Self(schemaVersion: 1, player: PlayerState(cash: Money(minorUnits: 2_000_000)), market: try ListingGenerator().generate(definitions: definitions, seed: seed, now: now), generation: seed)
    }
}

struct SaveRepository {
    let url: URL

    static func application() throws -> Self {
        let root = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return Self(url: root.appendingPathComponent("ProjectFlip/save.json"))
    }

    func load() throws -> GameSnapshot? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let state = try JSONDecoder().decode(GameSnapshot.self, from: Data(contentsOf: url))
        guard state.schemaVersion == 1, state.player.cash >= .zero,
              Set(state.market.map(\.id)).count == state.market.count else { throw SaveError.invalidSave }
        return state
    }

    func save(_ state: GameSnapshot) throws {
        let data = try JSONEncoder().encode(state)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }
}
enum SaveError: Error { case invalidSave }
