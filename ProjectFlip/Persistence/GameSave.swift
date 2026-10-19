import Foundation

struct GameSnapshot: Codable, Equatable {
    let schemaVersion: Int
    var player: PlayerState
    var market: [MarketplaceListing]
    var generation: UInt64
    var conversations: [NegotiationState] = []

    enum CodingKeys: String, CodingKey { case schemaVersion, player, market, generation, conversations }
    init(schemaVersion: Int, player: PlayerState, market: [MarketplaceListing], generation: UInt64) {
        self.schemaVersion = schemaVersion; self.player = player; self.market = market; self.generation = generation
    }
    init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try values.decode(Int.self, forKey: .schemaVersion)
        player = try values.decode(PlayerState.self, forKey: .player)
        market = try values.decode([MarketplaceListing].self, forKey: .market)
        generation = try values.decode(UInt64.self, forKey: .generation)
        conversations = try values.decodeIfPresent([NegotiationState].self, forKey: .conversations) ?? []
    }

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
