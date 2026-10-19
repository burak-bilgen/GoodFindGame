import Foundation

enum ScheduledStatus: String, Codable { case pending, completed, cancelled }

enum GameEventPayload: Codable, Equatable {
    case sellerReply(listingID: ListingID, reply: NegotiationState, expiresAt: Date)
    case sellerOfferExpired(listingID: ListingID, expiresAt: Date)
    case shipmentArrived(shipmentID: String)
    case inspectionCompleted(jobID: String)
    case buyerOffer(listingID: ListingID, expectedOfferCount: Int, offer: BuyerOffer, intent: String, expiresAt: Date)
    case buyerOfferExpired(listingID: ListingID, offerID: OfferID)
    case buyerInterest(listingID: ListingID)
    case marketRefresh
    case listingExpired(listingID: ListingID)
    case competitorPurchase(listingID: ListingID)
    case sellerPriceDrop(listingID: ListingID)
    case marketCycle(index: Int)
    case marketTrendEnded(trendID: String)

    var targetID: String {
        switch self {
        case .sellerReply(let id, _, _), .sellerOfferExpired(let id, _), .buyerOffer(let id, _, _, _, _), .buyerOfferExpired(let id, _), .buyerInterest(let id): id.rawValue
        case .shipmentArrived(let id), .inspectionCompleted(let id), .marketTrendEnded(let id): id
        case .marketRefresh: "market-refresh"
        case .listingExpired(let id), .competitorPurchase(let id), .sellerPriceDrop(let id): id.rawValue
        case .marketCycle(let index): "market-cycle-\(index)"
        }
    }

    var generatesBuyerInterest: Bool {
        switch self {
        case .buyerOffer, .buyerInterest: true
        default: false
        }
    }
}

struct GameEvent: Codable, Identifiable, Equatable {
    let id: String
    let sequence: UInt64
    let createdAt: Date
    let resolveAt: Date
    let payload: GameEventPayload
    let seed: UInt64
    var status: ScheduledStatus = .pending
}

struct Shipment: Codable, Identifiable, Equatable {
    let id: String
    let item: ItemInstance
    let arrivesAt: Date
    var status: ScheduledStatus = .pending
}

struct InspectionJob: Codable, Identifiable, Equatable {
    let id: String
    let itemID: ItemID
    let completesAt: Date
    let cost: Money
    var status: ScheduledStatus = .pending
}

enum ResolvedEventKind: String, Codable, CaseIterable { case sellerReply, shipment, inspection, buyerOffer, offerExpired, marketTrend, priceDrop, listingClosed }
struct ResolvedEvent: Codable, Identifiable, Equatable {
    let id: String
    let kind: ResolvedEventKind
    let targetID: String
    let occurredAt: Date
}

enum EventQueueError: Error { case invalidTimestamp, sequenceExhausted }

extension GameSnapshot {
    @discardableResult
    mutating func enqueue(_ payload: GameEventPayload, createdAt: Date, resolveAt: Date) throws -> GameEvent {
        guard createdAt.timeIntervalSinceReferenceDate.isFinite, resolveAt.timeIntervalSinceReferenceDate.isFinite,
              resolveAt >= createdAt else { throw EventQueueError.invalidTimestamp }
        guard nextEventSequence < UInt64.max else { throw EventQueueError.sequenceExhausted }
        nextEventSequence += 1
        let id = "event-\(simulationID)-\(nextEventSequence)"
        let event = GameEvent(id: id, sequence: nextEventSequence, createdAt: createdAt, resolveAt: resolveAt, payload: payload, seed: SeededRandom.seed(for: id))
        events.append(event)
        return event
    }
}
