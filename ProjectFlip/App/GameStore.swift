import Foundation
import Observation
import OSLog

@Observable @MainActor
final class GameStore {
    private(set) var snapshot: GameSnapshot
    let definitions: [ItemDefinition]
    let timing: SimulationTiming
    private let repository: SaveRepository
    var errorKey: String?
    @ObservationIgnored var onSnapshotCommitted: ((GameSnapshot) -> Void)?
    private let logger = Logger(subsystem: "ProjectFlip", category: "Save")

    init(repository: SaveRepository, definitions: [ItemDefinition], timing: SimulationTiming = .current, now: Date = .now) throws {
        self.repository = repository
        self.timing = timing
        self.definitions = definitions
        snapshot = try repository.load() ?? GameSnapshot.fresh(definitions: definitions)
        // Never replace an unreadable save with a fresh game.
        if !FileManager.default.fileExists(atPath: repository.url.path) { try repository.save(snapshot) }
        try catchUp(now: now, showSummary: true)
    }

    func definition(for item: ItemInstance) -> ItemDefinition? { definitions.first { $0.id == item.definitionID } }

    /// Write first, publish second: disk failures cannot grant unpersisted purchases.
    func commit(_ next: GameSnapshot) throws {
        do {
            try repository.save(next)
            snapshot = next
            onSnapshotCommitted?(next)
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
