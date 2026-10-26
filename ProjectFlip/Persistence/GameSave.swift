import Foundation

/// Atomic primary writes, a verified previous save, and explicit recovery.
/// Loading a damaged primary never silently replaces a player's career.
struct SaveRepository {
    let url: URL
    var backupURL: URL { url.appendingPathExtension("previous") }

    static func application() throws -> Self {
        let root = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return Self(url: root.appendingPathComponent("ProjectFlip/save.json"))
    }

    func load() throws -> GameSnapshot? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let original = try Data(contentsOf: url)
        let decoded = try decode(original)
        for suffix in decoded.migration.backupSuffixes {
            let backup = url.appendingPathExtension(suffix)
            if !FileManager.default.fileExists(atPath: backup.path) { try original.write(to: backup, options: .atomic) }
        }
        if decoded.migration.needsRewrite { try save(decoded.state) }
        return decoded.state
    }

    var canRestoreBackup: Bool {
        guard let data = try? Data(contentsOf: backupURL) else { return false }
        return (try? decode(data)) != nil
    }

    @discardableResult
    func restoreBackup() throws -> GameSnapshot {
        let original = try Data(contentsOf: backupURL)
        let restored = try decode(original).state
        if FileManager.default.fileExists(atPath: url.path) {
            let damaged = try Data(contentsOf: url)
            let preserved = url.appendingPathExtension("before-restore-\(UUID().uuidString).json")
            try damaged.write(to: preserved, options: .atomic)
        }
        // Do not rotate the damaged primary into the good backup.
        try JSONEncoder().encode(restored).write(to: url, options: .atomic)
        return restored
    }

    func save(_ state: GameSnapshot) throws {
        let data = try JSONEncoder().encode(state)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        if let previous = try? Data(contentsOf: url), previous != data,
           (try? decode(previous)) != nil {
            try previous.write(to: backupURL, options: .atomic)
        }
        try data.write(to: url, options: .atomic)
    }

    private func decode(_ original: Data) throws -> (state: GameSnapshot, migration: SaveMigrations.Prepared) {
        let migration = try SaveMigrations.prepare(original)
        let state = try JSONDecoder().decode(GameSnapshot.self, from: migration.data)
        try state.marketConfiguration.validate()
        guard state.schemaVersion == 1, state.player.cash >= .zero,
              Set(state.market.map(\.id)).count == state.market.count,
              Set(state.events.map(\.id)).count == state.events.count,
              Set(state.events.map(\.sequence)).count == state.events.count,
              state.events.allSatisfy({ $0.sequence <= state.nextEventSequence && $0.resolveAt >= $0.createdAt }),
              Set(state.player.inventory.map(\.id)).count == state.player.inventory.count else { throw SaveError.invalidSave }
        guard Set(state.marketListingStates.map(\.id)).count == state.marketListingStates.count,
              state.marketListingStates.allSatisfy({ lifecycle in
                  state.market.contains { $0.id == lifecycle.id } && lifecycle.expiresAt.timeIntervalSinceReferenceDate.isFinite &&
                  lifecycle.initialAskingPrice > .zero &&
                  (lifecycle.reducedPrice.map({ $0 > .zero && $0 < lifecycle.initialAskingPrice }) ?? true)
              }) else { throw SaveError.invalidSave }
        guard state.playerListings.allSatisfy({ $0.views >= 0 && $0.views <= 1_000_000_000 && $0.favorites >= 0 && $0.favorites <= $0.views && ($0.expiresAt?.timeIntervalSinceReferenceDate.isFinite ?? true) }) else { throw SaveError.invalidSave }
        for event in state.events {
            if case .listingAttention(_, let views, let favorites) = event.payload {
                guard (0...1_000).contains(views), (0...views).contains(favorites) else { throw SaveError.invalidSave }
            }
            if case .buyerReply(_, let offerID, let amount, let attempts) = event.payload {
                guard !offerID.rawValue.isEmpty, amount > .zero, amount <= GameBalanceConfig.current.maximumTransactionAmount, (0...2).contains(attempts) else { throw SaveError.invalidSave }
            }
        }
        let items = state.market.map(\.item) + state.player.inventory + state.shipments.map(\.item) + state.playerListings.compactMap(\.itemSnapshot)
        for item in items { try item.validateFacts() }
        try state.inspectionKnowledge.validate()
        try state.clients.validate()
        try RecoveryEngine.validate(state)
        if let calendar = state.marketCalendar {
            try calendar.validate()
            guard (state.lastMarketCycle ?? -1) >= -1, (state.lastMarketCycle ?? -1) < Int.max - 1 else { throw SaveError.invalidSave }
        } else if state.lastMarketCycle != nil || !state.marketTrends.isEmpty { throw SaveError.invalidSave }
        guard Set(state.marketTrends.map(\.id)).count == state.marketTrends.count,
              state.marketTrends.allSatisfy({ $0.startsAt < $0.endsAt && (500...1_200).contains($0.changeBasisPoints.magnitude) }) else { throw SaveError.invalidSave }
        return (state, migration)
    }
}
enum SaveError: Error { case invalidSave }
