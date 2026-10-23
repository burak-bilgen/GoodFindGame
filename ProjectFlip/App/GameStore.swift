import Foundation
import Observation
import OSLog

@Observable @MainActor
final class GameStore {
    private(set) var snapshot: GameSnapshot
    let definitions: [ItemDefinition]
    let competitionPeriod: WeeklyPeriod?
    @ObservationIgnored var competitionCanCommit: (() -> Bool)?
    let timing: SimulationTiming
    private let repository: SaveRepository
    var errorKey: String?
    @ObservationIgnored var onSnapshotCommitted: ((GameSnapshot) -> Void)?
    private let logger = Logger(subsystem: "ProjectFlip", category: "Save")

    init(repository: SaveRepository, definitions: [ItemDefinition], timing: SimulationTiming = .current, now: Date = .now, competitionPeriod: WeeklyPeriod? = nil) throws {
        self.repository = repository
        self.competitionPeriod = competitionPeriod
        self.timing = timing
        self.definitions = definitions
        snapshot = try repository.load() ?? GameSnapshot.fresh(definitions: definitions, marketConfiguration: .initial(locale: .current))
        // Never replace an unreadable save with a fresh game.
        if !FileManager.default.fileExists(atPath: repository.url.path) { try repository.save(snapshot) }
        try catchUp(now: now, showSummary: true)
    }

    func definition(for item: ItemInstance) -> ItemDefinition? { definitions.first { $0.id == item.definitionID } }

    /// Paused categories cannot sell a new player a kit for nonexistent stock.
    /// Historical holdings and earned knowledge remain accessible in old saves.
    var playableCategories: [ItemCategory] {
        var categories = Set(MarketCatalog.active(definitions).map(\.category))
        let savedItems = snapshot.market.map(\.item) + snapshot.player.inventory + snapshot.shipments.map(\.item)
        categories.formUnion(savedItems.compactMap { definition(for: $0)?.category })
        categories.formUnion(snapshot.inspectionKnowledge.tools)
        categories.formUnion(ItemCategory.allCases.filter { snapshot.inspectionKnowledge.points(in: $0) > 0 })
        return ItemCategory.allCases.filter { categories.contains($0) }
    }

    /// Condition facts are earned through inspection; the product photo stays fixed.
    func appearance(for item: ItemInstance) -> ItemAppearance {
        if item.inspected { return .owned(item) }
        return snapshot.market.first(where: { $0.item.id == item.id }).map(ItemAppearance.advertised) ?? .owned(item)
    }

    /// Write first, publish second: disk failures cannot grant unpersisted purchases.
    func commit(_ next: GameSnapshot) throws {
        do {
            if let period = competitionPeriod {
                guard period.contains(.now), competitionCanCommit?() ?? true, next.simulationID == period.id,
                      next.marketConfiguration.region == .unitedStates,
                      next.recovery.sequence == 0, next.recovery.commissionsEarned == .zero,
                      next.clients == ClientProgress(), next.collections == CollectionProgress(), next.shop == TraderShop() else { throw TradingError.unavailable }
            }
            var finalized = next
            InboxOrder.recordChanges(from: snapshot, in: &finalized, now: .now)
            CareerEngine.refresh(&finalized)
            ShopEngine.refresh(&finalized)
            try repository.save(finalized)
            snapshot = finalized
            onSnapshotCommitted?(finalized)
        } catch {
            #if DEBUG
            logger.error("Save failed: \(String(describing: error), privacy: .public)")
            #endif
            throw error
        }
    }
    func conversation(for listing: MarketplaceListing) -> NegotiationState {
        snapshot.conversations.first { $0.listingID == listing.id } ?? NegotiationState(listingID: listing.id, patience: listing.seller.patience)
    }

    func updateConversation(_ value: NegotiationState) throws {
        var next = snapshot
        if let index = next.conversations.firstIndex(where: { $0.id == value.id }) { next.conversations[index] = value }
        else { next.conversations.append(value) }
        EventResolver(timing: timing).reconcile(&next)
        try commit(next)
    }

    func perform(_ action: () throws -> Void) {
        do { try action() }
        catch let error as TradingError { errorKey = error.key }
        catch {
            errorKey = "save.error.write"
            #if DEBUG
            logger.error("Action failed: \(String(describing: error), privacy: .public)")
            #endif
        }
    }

}

extension GameStore {
    func previousTradeCount(with sellerID: SellerID) -> Int {
        let acquiredIDs = Set(snapshot.player.inventory.map(\.id) + snapshot.shipments.map { $0.item.id } + snapshot.playerListings.filter { $0.status == .sold }.map(\.itemID))
        return snapshot.market.filter { $0.seller.id == sellerID && acquiredIDs.contains($0.item.id) }.count
    }
}

extension GameStore {
    var hasExperiencedAsyncEvent: Bool { !snapshot.events.isEmpty || !snapshot.shipments.isEmpty || !snapshot.inspectionJobs.isEmpty }
    func setNotificationCategory(_ category: LocalNotificationCategory, enabled: Bool) throws {
        var next = snapshot
        if enabled { next.notificationPreferences.enabledCategories.insert(category) }
        else { next.notificationPreferences.enabledCategories.remove(category) }
        try commit(next)
    }
    func markNotificationPrompted() throws {
        var next = snapshot
        next.notificationPreferences.permissionPrompted = true
        try commit(next)
    }
}

extension GameStore {
    func toggleWatch(listingID: ListingID) throws {
        guard snapshot.market.contains(where: { $0.id == listingID }) else { throw TradingError.unavailable }
        var next = snapshot
        if next.watchedListingIDs.contains(listingID) { next.watchedListingIDs.remove(listingID) }
        else { next.watchedListingIDs.insert(listingID) }
        try commit(next)
    }
}
