import Foundation

struct GameSnapshot: Codable, Equatable {
    let schemaVersion: Int
    var player: PlayerState
    var market: [MarketplaceListing]
    var generation: UInt64
    var conversations: [NegotiationState] = []
    var playerListings: [PlayerListing] = []
    var simulationID = UUID().uuidString
    var nextEventSequence: UInt64 = 0
    var events: [GameEvent] = []
    var shipments: [Shipment] = []
    var inspectionJobs: [InspectionJob] = []
    var lastKnownWallClock: Date?
    var lastSimulationAt: Date?
    var awayReport: [ResolvedEvent] = []
    var marketFeedStartedAt: Date?
    var marketListingStates: [MarketListingState] = []
    var marketCalendar: MarketCalendar?
    var lastMarketCycle: Int?
    var marketTrends: [MarketTrend] = []
    var watchedListingIDs: Set<ListingID> = []
    var notificationPreferences = NotificationPreferences()
    var inspectionKnowledge = InspectionKnowledge()
    var marketConfiguration = MarketConfiguration.us
    var economyMigrationNotice = false
    var career = CareerRecord()

    enum CodingKeys: String, CodingKey { case schemaVersion, player, market, generation, conversations, playerListings, simulationID, nextEventSequence, events, shipments, inspectionJobs, lastKnownWallClock, lastSimulationAt, awayReport, notificationPreferences, watchedListingIDs, marketCalendar, lastMarketCycle, marketTrends, marketFeedStartedAt, marketListingStates, inspectionKnowledge, marketConfiguration, economyMigrationNotice, career }
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
        playerListings = try values.decodeIfPresent([PlayerListing].self, forKey: .playerListings) ?? []
        simulationID = try values.decodeIfPresent(String.self, forKey: .simulationID) ?? "legacy-\(generation)"
        nextEventSequence = try values.decodeIfPresent(UInt64.self, forKey: .nextEventSequence) ?? 0
        events = try values.decodeIfPresent([GameEvent].self, forKey: .events) ?? []
        shipments = try values.decodeIfPresent([Shipment].self, forKey: .shipments) ?? []
        inspectionJobs = try values.decodeIfPresent([InspectionJob].self, forKey: .inspectionJobs) ?? []
        lastKnownWallClock = try values.decodeIfPresent(Date.self, forKey: .lastKnownWallClock)
        lastSimulationAt = try values.decodeIfPresent(Date.self, forKey: .lastSimulationAt)
        awayReport = try values.decodeIfPresent([ResolvedEvent].self, forKey: .awayReport) ?? []
        marketFeedStartedAt = try values.decodeIfPresent(Date.self, forKey: .marketFeedStartedAt)
        marketListingStates = try values.decodeIfPresent([MarketListingState].self, forKey: .marketListingStates) ?? []
        marketCalendar = try values.decodeIfPresent(MarketCalendar.self, forKey: .marketCalendar)
        lastMarketCycle = try values.decodeIfPresent(Int.self, forKey: .lastMarketCycle)
        marketTrends = try values.decodeIfPresent([MarketTrend].self, forKey: .marketTrends) ?? []
        watchedListingIDs = try values.decodeIfPresent(Set<ListingID>.self, forKey: .watchedListingIDs) ?? []
        inspectionKnowledge = try values.decodeIfPresent(InspectionKnowledge.self, forKey: .inspectionKnowledge) ?? InspectionKnowledge()
        career = try values.decodeIfPresent(CareerRecord.self, forKey: .career) ?? CareerRecord()
        marketConfiguration = try values.decodeIfPresent(MarketConfiguration.self, forKey: .marketConfiguration) ?? .us
        economyMigrationNotice = try values.decodeIfPresent(Bool.self, forKey: .economyMigrationNotice) ?? false
        notificationPreferences = try values.decodeIfPresent(NotificationPreferences.self, forKey: .notificationPreferences) ?? NotificationPreferences()
    }

    static func fresh(definitions: [ItemDefinition], seed: UInt64 = GameBalanceConfig.current.marketSeed, now: Date = .now, marketConfiguration: MarketConfiguration = .us) throws -> Self {
        var state = Self(schemaVersion: 1, player: PlayerState(cash: GameBalanceConfig.current.startingCash, inventoryCapacity: GameBalanceConfig.current.inventorySlots), market: try ListingGenerator().generate(definitions: MarketCatalog.starterFeed(from: definitions), seed: seed, now: now), generation: seed)
        state.marketConfiguration = marketConfiguration
        state.market = try ListingGenerator().generate(definitions: MarketCatalog.starterFeed(from: definitions), seed: seed, now: now, market: state)
        return state
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
        let original = try Data(contentsOf: url)
        var object = try JSONSerialization.jsonObject(with: original) as? [String: Any] ?? [:]
        if object["marketConfiguration"] == nil {
            // One explicit rebase from legacy arbitrary credits. Preserve relative cash,
            // commitments and receipt arithmetic; keep the complete original save.
            let backup = url.appendingPathExtension("pre-economy-v2.json")
            if !FileManager.default.fileExists(atPath: backup.path) { try original.write(to: backup, options: .atomic) }
            func rebase(_ value: Any) -> Any {
                if let dict = value as? [String: Any] {
                    if dict.count == 1, let units = dict["minorUnits"] as? NSNumber { return ["minorUnits": units.int64Value / 20] }
                    return dict.mapValues(rebase)
                }
                if let array = value as? [Any] { return array.map(rebase) }
                return value
            }
            object = rebase(object) as? [String: Any] ?? [:]
            object["marketConfiguration"] = ["version": 1, "region": "unitedStates", "currency": "USD"]
            object["economyMigrationNotice"] = true
        }
        let state = try JSONDecoder().decode(GameSnapshot.self, from: JSONSerialization.data(withJSONObject: object))
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
        if let calendar = state.marketCalendar {
            try calendar.validate()
            guard (state.lastMarketCycle ?? -1) >= -1, (state.lastMarketCycle ?? -1) < Int.max - 1 else { throw SaveError.invalidSave }
        } else if state.lastMarketCycle != nil || !state.marketTrends.isEmpty { throw SaveError.invalidSave }
        guard Set(state.marketTrends.map(\.id)).count == state.marketTrends.count,
              state.marketTrends.allSatisfy({ $0.startsAt < $0.endsAt && (500...1_200).contains($0.changeBasisPoints.magnitude) }) else { throw SaveError.invalidSave }
        return state
    }

    func save(_ state: GameSnapshot) throws {
        let data = try JSONEncoder().encode(state)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }
}
enum SaveError: Error { case invalidSave }
