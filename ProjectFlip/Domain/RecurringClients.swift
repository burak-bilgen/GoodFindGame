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
    var maximumPayment: Money?
}

struct ClientDefinition: Identifiable {
    let id: String
    let portrait: Int
    let titleID: Int
    let requests: [ClientRequest]
    var honorKey: String {
        switch id {
        case "rowan": "clients.confidant"
        case "jules": "clients.preferred"
        default: "client.\(id).honor"
        }
    }
    static let all = [
        Self(id: "rowan", portrait: 2, titleID: 100, requests: [
            ClientRequest(models: ["retro-0", "retro-1", "retro-8"], minimumCondition: 65, career: .newcomer),
            ClientRequest(models: ["retro-0", "retro-1", "retro-2", "retro-8"], minimumCondition: 75, career: .known, originalBox: true),
            ClientRequest(models: ["retro-0", "retro-2", "retro-8"], minimumCondition: 90, career: .trusted, originalBox: true, originalParts: true)
        ]),
        Self(id: "jules", portrait: 3, titleID: 101, requests: [
            ClientRequest(models: ["cameras-0", "cameras-1", "cameras-6", "cameras-7"], minimumCondition: 65, career: .newcomer),
            ClientRequest(models: ["cameras-8", "cameras-9", "cameras-10", "cameras-11"], minimumCondition: 75, career: .known),
            ClientRequest(models: ["cameras-2", "cameras-3", "cameras-5", "cameras-14"], minimumCondition: 85, career: .trusted)
        ]),
        Self(id: "mira", portrait: 5, titleID: 102, requests: [
            ClientRequest(models: ["home-0", "home-2", "home-3"], minimumCondition: 60, career: .newcomer, maximumPayment: Money(minorUnits: 11000)),
            ClientRequest(models: ["home-5", "home-8", "home-9"], minimumCondition: 75, career: .known, maximumPayment: Money(minorUnits: 16000)),
            ClientRequest(models: ["home-0", "home-9"], minimumCondition: 90, career: .specialist, maximumPayment: Money(minorUnits: 24000))
        ]),
        Self(id: "noah", portrait: 4, titleID: 103, requests: [
            ClientRequest(models: ["everyday-4", "everyday-5", "everyday-9"], minimumCondition: 55, career: .newcomer, maximumPayment: Money(minorUnits: 6000)),
            ClientRequest(models: ["everyday-2", "everyday-6", "everyday-7"], minimumCondition: 70, career: .known, maximumPayment: Money(minorUnits: 18000)),
            ClientRequest(models: ["everyday-4", "everyday-5"], minimumCondition: 90, career: .specialist, maximumPayment: Money(minorUnits: 12000))
        ]),
        Self(id: "aya", portrait: 7, titleID: 104, requests: [
            ClientRequest(models: ["furniture-0", "furniture-1", "furniture-3", "furniture-9"], minimumCondition: 60, career: .newcomer, maximumPayment: Money(minorUnits: 9000)),
            ClientRequest(models: ["furniture-4", "furniture-7", "furniture-8"], minimumCondition: 75, career: .known, maximumPayment: Money(minorUnits: 20000)),
            ClientRequest(models: ["furniture-2", "furniture-5", "furniture-6"], minimumCondition: 90, career: .specialist, maximumPayment: Money(minorUnits: 40000))
        ]),
        Self(id: "leon", portrait: 8, titleID: 105, requests: [
            ClientRequest(models: ["gaming-4", "gaming-5", "gaming-12", "gaming-13"], minimumCondition: 60, career: .newcomer, maximumPayment: Money(minorUnits: 8000)),
            ClientRequest(models: ["gaming-7", "gaming-9", "gaming-11"], minimumCondition: 75, career: .known, maximumPayment: Money(minorUnits: 40000)),
            ClientRequest(models: ["gaming-14", "gaming-18", "gaming-19"], minimumCondition: 85, career: .specialist, maximumPayment: Money(minorUnits: 90000))
        ])
    ]
}

enum ItemTransfer {
    static func available(_ id: ItemID, state: GameSnapshot) -> Bool {
        state.recovery.itemID != id &&
        !state.playerListings.contains { $0.itemID == id && $0.status == .active } &&
        !state.inspectionJobs.contains { $0.itemID == id && $0.status == .pending }
    }
}

enum ClientEngine {
    struct Brief {
        let client: ClientDefinition
        let request: ClientRequest
    }
    static func activeBrief(in state: GameSnapshot) -> Brief? {
        guard let id = state.clients.active, let client = ClientDefinition.all.first(where: { $0.id == id }),
              let request = request(id, state: state) else { return nil }
        return Brief(client: client, request: request)
    }
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
        let marketQuote = try InspectionEngine().estimatedValue(item: item, definition: definition, marketBasisPoints: state.marketMultiplier(for: definition)).scaled(byBasisPoints: 10_200)
        if let brief = activeBrief(in: state), brief.request.models.contains(item.definitionID), let cap = brief.request.maximumPayment {
            return min(marketQuote, cap)
        }
        return marketQuote
    }
    static func fulfill(_ id: String, itemID: ItemID, state: GameSnapshot, definitions: [ItemDefinition], now: Date, expectedQuote: Money? = nil) throws -> GameSnapshot {
        guard state.clients.active == id, let request = request(id, state: state),
              let item = state.player.inventory.first(where: { $0.id == itemID }),
              let definition = definitions.first(where: { $0.id == item.definitionID }),
              qualifies(item, request: request), ItemTransfer.available(itemID, state: state) else { throw TradingError.unavailable }
        let amount = try quote(item, definition: definition, state: state)
        guard expectedQuote.map({ $0 == amount }) ?? true else { throw TradingError.quoteChanged }
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
    func fulfillClient(_ id: String, itemID: ItemID, expectedQuote: Money? = nil) throws {
        try catchUp()
        try commit(ClientEngine.fulfill(id, itemID: itemID, state: snapshot, definitions: definitions, now: snapshot.lastSimulationAt ?? .now, expectedQuote: expectedQuote))
    }
    func pauseClient() throws { var next = snapshot; next.clients.active = nil; try commit(next) }
}
