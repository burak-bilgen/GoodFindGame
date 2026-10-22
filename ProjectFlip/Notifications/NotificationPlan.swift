import Foundation

enum LocalNotificationCategory: String, Codable, CaseIterable, Sendable {
    case offers, logistics, auctions, market, requests
    var key: String { "notifications.category.\(rawValue)" }
}

struct NotificationPreferences: Codable, Equatable {
    var enabledCategories = Set(LocalNotificationCategory.allCases)
    var permissionPrompted = false
}

struct GameRoute: Codable, Hashable, Identifiable, Sendable {
    enum Kind: String, Codable, Sendable { case conversation, inventory, sale, marketTrend, marketListing, notificationSettings, unavailable }
    let kind: Kind
    let targetID: String?
    var id: String { "\(kind.rawValue)-\(targetID ?? "")" }
    static func conversation(_ id: ListingID) -> Self { Self(kind: .conversation, targetID: id.rawValue) }
    static func inventory(_ id: ItemID) -> Self { Self(kind: .inventory, targetID: id.rawValue) }
    static func sale(_ id: ListingID) -> Self { Self(kind: .sale, targetID: id.rawValue) }
    static func listing(_ id: ListingID) -> Self { Self(kind: .marketListing, targetID: id.rawValue) }
    static func trend(_ id: String) -> Self { Self(kind: .marketTrend, targetID: id) }
    static let settings = Self(kind: .notificationSettings, targetID: nil)
    static let unavailable = Self(kind: .unavailable, targetID: nil)

    func encoded() throws -> String {
        String(decoding: try JSONEncoder().encode(self), as: UTF8.self)
    }
    static func decode(_ value: String) throws -> Self {
        guard value.utf8.count < 2_048 else { throw RouteError.invalid }
        let route = try JSONDecoder().decode(Self.self, from: Data(value.utf8))
        switch route.kind {
        case .conversation, .inventory, .sale, .marketTrend, .marketListing:
            guard let target = route.targetID, !target.isEmpty, target.utf8.count <= 512 else { throw RouteError.invalid }
        case .notificationSettings, .unavailable: break
        }
        return route
    }
}
enum RouteError: Error { case invalid }

struct LocalNotificationSpec: Equatable, Sendable {
    let id: String
    let fireAt: Date
    let category: LocalNotificationCategory
    let title: String
    let body: String
    let route: GameRoute
}

struct NotificationPlanner {
    func makePlan(state: GameSnapshot, definitions: [ItemDefinition], locale: Locale, now: Date, limit: Int = 48) throws -> [LocalNotificationSpec] {
        var state = state
        EventResolver().reconcile(&state)
        let clock = try GameClock.read(now: now, lastKnownWallClock: state.lastKnownWallClock, lastSimulationAt: state.lastSimulationAt)
        let title = GameText.string("notifications.title", locale: locale)
        func itemName(_ item: ItemInstance) -> String? { definitions.first { $0.id == item.definitionID }?.displayName(locale: locale) }
        func projected(_ date: Date) -> Date { now.addingTimeInterval(max(0, date.timeIntervalSince(clock.effectiveNow))) }
        var result: [LocalNotificationSpec] = []
        for event in state.events.sorted(by: { $0.resolveAt == $1.resolveAt ? $0.sequence < $1.sequence : $0.resolveAt < $1.resolveAt }) where event.status == .pending && event.resolveAt > clock.effectiveNow {
            let category: LocalNotificationCategory
            let body: String
            let route: GameRoute
            switch event.payload {
            case .sellerPriceDrop(let id):
                guard state.watchedListingIDs.contains(id),
                      MarketFeedEngine.remainsAvailable(listingID: id, at: event.resolveAt, sequence: event.sequence, state: state),
                      MarketFeedEngine.holdUntil(listingID: id, at: event.resolveAt, beforeSequence: event.sequence, state: state) == nil,
                      let listing = state.market.first(where: { $0.id == id }), let name = itemName(listing.item),
                      let lifecycle = state.marketListingStates.first(where: { $0.id == id && $0.priceDroppedAt == nil }),
                      let price = lifecycle.reducedPrice else { continue }
                category = .market
                body = GameText.format("notifications.priceDrop", locale: locale, name, price.formatted(locale: locale))
                route = .listing(id)
            case .marketCycle(let index):
                guard let calendar = state.marketCalendar else { continue }
                let trend = try calendar.trend(at: index)
                category = .market
                body = GameText.format("notifications.marketTrend", locale: locale,
                                       trend.scope.displayName(definitions: definitions, locale: locale),
                                       trend.formattedChange(locale: locale), GameText.string(trend.reason.key, locale: locale))
                route = .trend(trend.id)
            case .sellerReply(let id, let reply, let expiresAt):
                guard let listing = state.market.first(where: { $0.id == id }),
                      MarketFeedEngine.remainsAvailable(listingID: id, at: event.resolveAt, sequence: event.sequence, state: state) else { continue }
                category = .offers
                let name = GameText.string("npc.name.\(listing.seller.identityIndex % 10)", locale: locale)
                let expiry = projected(expiresAt).formatted(.dateTime.hour().minute().locale(locale))
                if let price = reply.counterPrice {
                    body = GameText.format("notifications.sellerCounter", locale: locale, name, price.formatted(locale: locale), expiry)
                } else if let price = reply.agreedPrice {
                    body = GameText.format("notifications.sellerAccepted", locale: locale, name, price.formatted(locale: locale), expiry)
                } else {
                    body = GameText.format("notifications.sellerReply", locale: locale, name)
                }
                route = .conversation(id)
            case .shipmentArrived(let id):
                guard let shipment = state.shipments.first(where: { $0.id == id && $0.status == .pending }), let name = itemName(shipment.item) else { continue }
                category = .logistics
                body = GameText.format("notifications.shipment", locale: locale, name)
                route = .inventory(shipment.item.id)
            case .inspectionCompleted(let id):
                guard let job = state.inspectionJobs.first(where: { $0.id == id && $0.status == .pending }), let item = state.player.inventory.first(where: { $0.id == job.itemID }), let name = itemName(item) else { continue }
                category = .logistics
                body = GameText.format("notifications.inspection", locale: locale, name)
                route = .inventory(job.itemID)
            case .buyerOffer(let id, _, let offer, _, let expiresAt):
                category = .offers
                let expiry = projected(expiresAt).formatted(.dateTime.hour().minute().locale(locale))
                body = GameText.format("notifications.buyerOffer", locale: locale, offer.amount.formatted(locale: locale), expiry)
                route = .sale(id)
            case .buyerReply(let id, _, _, _):
                category = .offers
                body = GameText.string("living.buyerReplyNotification", locale: locale)
                route = .sale(id)
            case .playerListingExpired(let id):
                // A committed accepting reply will settle this listing before its window ends.
                let settlesEarlier = state.events.contains { reply in
                    guard reply.status == .pending, reply.resolveAt < event.resolveAt,
                          case .buyerReply(let target, let offerID, let amount, _) = reply.payload, target == id,
                          let offer = state.playerListings.first(where: { $0.id == id })?.offers.last else { return false }
                    return offer.id == offerID && (try? BuyerEngine().counterDecision(listingID: id, amount: amount, state: state)) == .accept
                }
                if settlesEarlier { continue }
                guard let listing = state.playerListings.first(where: { $0.id == id }), let item = state.player.inventory.first(where: { $0.id == listing.itemID }), let name = itemName(item) else { continue }
                category = .offers
                body = GameText.format("living.expiredNotification", locale: locale, name)
                route = .sale(id)
            case .listingExpired(let id), .competitorPurchase(let id):
                guard state.watchedListingIDs.contains(id),
                      state.marketListingStates.contains(where: { $0.id == id && $0.closureReason == nil }),
                      MarketFeedEngine.remainsAvailable(listingID: id, at: event.resolveAt, sequence: event.sequence, state: state),
                      MarketFeedEngine.holdUntil(listingID: id, at: event.resolveAt, beforeSequence: event.sequence, state: state) == nil,
                      let listing = state.market.first(where: { $0.id == id }), let name = itemName(listing.item) else { continue }
                category = .market
                let key: String
                if case .competitorPurchase = event.payload { key = "living.watchedSold" } else { key = "living.watchedExpired" }
                body = GameText.format(key, locale: locale, name)
                route = .listing(id)
            case .listingAttention, .sellerOfferExpired, .buyerOfferExpired, .buyerInterest, .marketTrendEnded, .marketRefresh:
                continue
            }
            guard state.notificationPreferences.enabledCategories.contains(category) else { continue }
            result.append(LocalNotificationSpec(id: event.id, fireAt: projected(event.resolveAt), category: category, title: title, body: body, route: route))
            if result.count >= max(0, limit) { break }
        }
        return limit <= 0 ? [] : result
    }
}
