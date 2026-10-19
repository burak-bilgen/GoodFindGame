import Foundation
import Observation
import OSLog

@Observable @MainActor
final class GameStore {
    private(set) var snapshot: GameSnapshot
    let definitions: [ItemDefinition]
    private let repository: SaveRepository
    var errorKey: String?
    private let logger = Logger(subsystem: "ProjectFlip", category: "Save")

    init(repository: SaveRepository, definitions: [ItemDefinition]) throws {
        self.repository = repository
        self.definitions = definitions
        snapshot = try repository.load() ?? GameSnapshot.fresh(definitions: definitions)
        // Never replace an unreadable save with a fresh game.
        if !FileManager.default.fileExists(atPath: repository.url.path) { try repository.save(snapshot) }
    }

    func definition(for item: ItemInstance) -> ItemDefinition? { definitions.first { $0.id == item.definitionID } }

    /// Write first, publish second: disk failures cannot grant unpersisted purchases.
    func commit(_ next: GameSnapshot) throws {
        do {
            try repository.save(next)
            snapshot = next
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
