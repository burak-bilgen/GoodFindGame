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
    var sharedMarketMigrationNotice = false
    var career = CareerRecord()
    var clients = ClientProgress()
    var recovery = RecoveryProgress()

    enum CodingKeys: String, CodingKey { case schemaVersion, player, market, generation, conversations, playerListings, simulationID, nextEventSequence, events, shipments, inspectionJobs, lastKnownWallClock, lastSimulationAt, awayReport, notificationPreferences, watchedListingIDs, marketCalendar, lastMarketCycle, marketTrends, marketFeedStartedAt, marketListingStates, inspectionKnowledge, marketConfiguration, economyMigrationNotice, sharedMarketMigrationNotice, career, clients, recovery }
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
        recovery = try values.decodeIfPresent(RecoveryProgress.self, forKey: .recovery) ?? RecoveryProgress()
        clients = try values.decodeIfPresent(ClientProgress.self, forKey: .clients) ?? ClientProgress()
        let refund = try SaveMigrations.retiredShopRefund(from: decoder)
        if refund > .zero {
            guard player.cash >= .zero else { throw SaveError.invalidSave }
            player.cash = try player.cash.adding(refund)
        }
        career = try values.decodeIfPresent(CareerRecord.self, forKey: .career) ?? CareerRecord()
        if !values.contains(.career) || career.accessVersion == nil {
            career.legacyAccessTier = career.tier(knowledge: inspectionKnowledge)
            career.accessVersion = 2
        }
        if !values.contains(.career) { career.legacyAgreements = Set(conversations.filter { !$0.closed && ($0.agreedPrice != nil || $0.counterPrice != nil) }.map(\.listingID)) }
        marketConfiguration = try values.decodeIfPresent(MarketConfiguration.self, forKey: .marketConfiguration) ?? .us
        economyMigrationNotice = try values.decodeIfPresent(Bool.self, forKey: .economyMigrationNotice) ?? false
        sharedMarketMigrationNotice = try values.decodeIfPresent(Bool.self, forKey: .sharedMarketMigrationNotice) ?? false
        notificationPreferences = try values.decodeIfPresent(NotificationPreferences.self, forKey: .notificationPreferences) ?? NotificationPreferences()
    }

    static func fresh(definitions: [ItemDefinition], seed: UInt64 = GameBalanceConfig.current.marketSeed, now: Date = .now, marketConfiguration: MarketConfiguration = .us) throws -> Self {
        var state = Self(schemaVersion: 1, player: PlayerState(cash: GameBalanceConfig.current.startingCash, inventoryCapacity: GameBalanceConfig.current.inventorySlots), market: try ListingGenerator().generate(definitions: MarketCatalog.starterFeed(from: definitions), seed: seed, now: now), generation: seed)
        state.marketConfiguration = marketConfiguration
        state.market = try ListingGenerator().generate(definitions: MarketCatalog.starterFeed(from: definitions), seed: seed, now: now, market: state)
        return state
    }
}
