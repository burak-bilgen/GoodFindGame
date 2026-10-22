import Foundation

struct ClientProgress: Codable, Equatable {
    var completed: [String: Int] = [:]
    var active: String?
    func validate() throws {
        guard completed.allSatisfy({ ClientDefinition.all.map(\.id).contains($0.key) && (0...3).contains($0.value) }),
              active.map({ ClientDefinition.all.map(\.id).contains($0) && completed[$0, default: 0] < 3 }) ?? true else { throw SaveError.invalidSave }
    }
}

struct ClientRequest {
    let models: Set<String>
    let minimumCondition: Int
    let career: CareerTier
    var originalBox = false
    var originalParts = false
}

struct ClientDefinition: Identifiable {
    let id: String
    let portrait: Int
    let requests: [ClientRequest]
    static let all = [
        Self(id: "rowan", portrait: 7, requests: [
            ClientRequest(models: ["retro-0", "retro-1", "retro-8"], minimumCondition: 65, career: .newcomer),
            ClientRequest(models: ["retro-0", "retro-1", "retro-2", "retro-8"], minimumCondition: 75, career: .known, originalBox: true),
            ClientRequest(models: ["retro-0", "retro-2", "retro-8"], minimumCondition: 90, career: .trusted, originalBox: true, originalParts: true)
        ]),
        Self(id: "jules", portrait: 3, requests: [
            ClientRequest(models: ["cameras-0", "cameras-1", "cameras-6", "cameras-7"], minimumCondition: 65, career: .newcomer),
            ClientRequest(models: ["cameras-8", "cameras-9", "cameras-10", "cameras-11"], minimumCondition: 75, career: .known),
            ClientRequest(models: ["cameras-2", "cameras-3", "cameras-5", "cameras-14"], minimumCondition: 85, career: .trusted)
        ])
    ]
}

enum ItemTransfer {
    static func available(_ id: ItemID, state: GameSnapshot) -> Bool {
        !state.playerListings.contains { $0.itemID == id && $0.status == .active } &&
        !state.inspectionJobs.contains { $0.itemID == id && $0.status == .pending }
    }
}

enum ClientEngine {
    static func request(_ id: String, state: GameSnapshot) -> ClientRequest? {
        guard let client = ClientDefinition.all.first(where: { $0.id == id }) else { return nil }
        let step = state.clients.completed[id, default: 0]
        return client.requests.indices.contains(step) ? client.requests[step] : nil
    }
    static func accept(_ id: String, state: GameSnapshot) throws -> GameSnapshot {
        guard state.clients.active == nil, let request = request(id, state: state), state.career.tier(knowledge: state.inspectionKnowledge).rawValue >= request.career.rawValue else { throw TradingError.unavailable }
        var next = state; next.clients.active = id; return next
    }
    static func qualifies(_ item: ItemInstance, request: ClientRequest) -> Bool {
        // Full earned evidence is an explicit client requirement. Never reject
        // using a hidden defect the player was unable to inspect.
        guard request.models.contains(item.definitionID), item.professionallyInspected,
              item.condition >= request.minimumCondition, item.knownActiveDefects.isEmpty else { return false }
        func has(_ key: ItemFactKey, terms: Set<ItemFactTerm>) -> Bool {
            guard item.knownFactKeys.contains(key), let fact = item.facts?.values.first(where: { $0.key == key }), case .term(let term) = fact.value else { return false }
            return terms.contains(term)
        }
        if request.originalBox && !has(.packaging, terms: [.originalBox, .wornOriginalBox]) { return false }
        if request.originalParts && (!has(.originalParts, terms: [.originalParts]) || !has(.authenticity, terms: [.authentic])) { return false }
        return true
    }
    static func quote(_ item: ItemInstance, definition: ItemDefinition, state: GameSnapshot) throws -> Money {
        // A modest, deterministic alternative buyer. No dependence on acquisition
        // price, no extra quest jackpot, and no trust multiplier.
        try InspectionEngine().estimatedValue(item: item, definition: definition, marketBasisPoints: state.marketMultiplier(for: definition)).scaled(byBasisPoints: 10_200)
    }
    static func fulfill(_ id: String, itemID: ItemID, state: GameSnapshot, definitions: [ItemDefinition], now: Date) throws -> GameSnapshot {
        guard state.clients.active == id, let request = request(id, state: state),
              let item = state.player.inventory.first(where: { $0.id == itemID }),
              let definition = definitions.first(where: { $0.id == item.definitionID }),
              qualifies(item, request: request), ItemTransfer.available(itemID, state: state) else { throw TradingError.unavailable }
        let amount = try quote(item, definition: definition, state: state)
        var next = state
        let step = next.clients.completed[id, default: 0]
        var sale = PlayerListing(id: ListingID("client-\(id)-\(step)-\(itemID.rawValue)"), itemID: itemID, askingPrice: amount, createdAt: now, views: 0, favorites: 0)
        sale.status = .sold; sale.itemSnapshot = item; sale.soldPrice = amount; sale.soldAt = now; sale.saleKind = .client
        next.playerListings.append(sale)
        next.player.inventory.removeAll { $0.id == itemID }
        next.player.cash = try next.player.cash.adding(amount)
        next.clients.completed[id] = step + 1; next.clients.active = nil
        CareerEngine.refresh(&next)
        return next
    }
}

extension GameStore {
    func acceptClient(_ id: String) throws { try commit(ClientEngine.accept(id, state: snapshot)) }
    func fulfillClient(_ id: String, itemID: ItemID) throws {
        try catchUp()
        try commit(ClientEngine.fulfill(id, itemID: itemID, state: snapshot, definitions: definitions, now: snapshot.lastSimulationAt ?? .now))
    }
    func pauseClient() throws { var next = snapshot; next.clients.active = nil; try commit(next) }
}
