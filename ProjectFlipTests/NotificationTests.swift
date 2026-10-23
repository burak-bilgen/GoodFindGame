import Foundation
import Testing
@testable import ProjectFlip

struct NotificationTests {
    let now = Date(timeIntervalSince1970: 100_000)

    func awaitingSeller() throws -> GameSnapshot {
        var state = try GameSnapshot.fresh(definitions: SeedContent.load().items)
        state.lastKnownWallClock = now; state.lastSimulationAt = now
        return try SimulationActions(timing: .debug).offer(listingID: state.market[0].id, amount: state.market[0].askingPrice, modifier: .none, state: state, now: now)
    }

    @Test func actualScheduledReplyHasStableIdentityAndNativeLocaleCopy() throws {
        let definitions = try SeedContent.load().items
        let state = try awaitingSeller()
        let en = try NotificationPlanner().makePlan(state: state, definitions: definitions, locale: Locale(identifier: "en_US"), now: now)
        let tr = try NotificationPlanner().makePlan(state: state, definitions: definitions, locale: Locale(identifier: "tr_TR"), now: now)
        #expect(en.count == 1)
        #expect(en[0].id == state.events[0].id)
        #expect(en[0].route == .conversation(state.market[0].id))
        #expect(en[0].body.contains("Alex accepted"))
        #expect(tr[0].body.contains("Deniz"))
        #expect(tr[0].body.contains("US$") || tr[0].body.contains("$"))
        #expect(en[0].body != tr[0].body)
        #expect(try en == NotificationPlanner().makePlan(state: state, definitions: definitions, locale: Locale(identifier: "en_US"), now: now.addingTimeInterval(1)))
    }

    @Test func disabledCategoryAndCancelledResponseProduceNoAlerts() throws {
        let definitions = try SeedContent.load().items
        var state = try awaitingSeller()
        state.notificationPreferences.enabledCategories.remove(.offers)
        #expect(try NotificationPlanner().makePlan(state: state, definitions: definitions, locale: Locale(identifier: "en_US"), now: now).isEmpty)
        state.notificationPreferences.enabledCategories.insert(.offers)
        state = try SimulationActions(timing: .debug).walkAway(listingID: state.market[0].id, state: state)
        #expect(try NotificationPlanner().makePlan(state: state, definitions: definitions, locale: Locale(identifier: "en_US"), now: now).isEmpty)
    }

    @Test func deliveryRoutesToOwnedItemAndPastEventsAreNotReScheduled() throws {
        let definitions = try SeedContent.load().items
        let actions = SimulationActions(timing: .debug)
        var state = try EventResolver(timing: .debug).resolve(awaitingSeller(), now: now.addingTimeInterval(5), definitions: definitions).state
        state = try actions.purchase(listingID: state.market[0].id, state: state, now: now.addingTimeInterval(5))
        let plan = try NotificationPlanner().makePlan(state: state, definitions: definitions, locale: Locale(identifier: "tr_TR"), now: now.addingTimeInterval(5))
        #expect(plan.count == 1)
        #expect(plan[0].category == .logistics)
        #expect(plan[0].route == .inventory(state.market[0].item.id))
        #expect(try NotificationPlanner().makePlan(state: state, definitions: definitions, locale: Locale(identifier: "en_US"), now: now.addingTimeInterval(20)).isEmpty)
    }

    @Test func overpricedInterestRetriesNeverInventBuyerOfferNotifications() throws {
        let definitions = try SeedContent.load().items
        let original = try ResaleTests.inspectedState()
        let state = try SimulationActions(timing: .debug).publish(itemID: original.player.inventory[0].id, askingPrice: Money(minorUnits: 1_000_000_000), state: original, definitions: definitions, now: now)
        #expect(state.playerListings[0].offers.isEmpty)
        let plan = try NotificationPlanner().makePlan(state: state, definitions: definitions, locale: Locale(identifier: "en_US"), now: now)
        #expect(plan.count == 1)
        #expect(state.events.contains { $0.id == plan[0].id && $0.payload == .playerListingExpired(listingID: state.playerListings[0].id) })
    }

    @Test func routeRoundTripRejectsMissingOrUnknownTargets() throws {
        let route = GameRoute.inventory(ItemID("item-42-0"))
        #expect(try GameRoute.decode(route.encoded()) == route)
        for input in ["{}", "{\"kind\":\"conversation\"}", "{\"kind\":\"external\",\"targetID\":\"x\"}"] {
            #expect(throws: (any Error).self) { try GameRoute.decode(input) }
        }
    }

    @Test func categoryPreferencesPersistAndMigrateFromOlderSaves() throws {
        var state = try awaitingSeller()
        state.notificationPreferences.enabledCategories.remove(.logistics)
        state.notificationPreferences.permissionPrompted = true
        let data = try JSONEncoder().encode(state)
        #expect(try JSONDecoder().decode(GameSnapshot.self, from: data) == state)
        var old = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        old.removeValue(forKey: "notificationPreferences")
        let decoded = try JSONDecoder().decode(GameSnapshot.self, from: JSONSerialization.data(withJSONObject: old))
        #expect(decoded.notificationPreferences.enabledCategories.count == 5)
        #expect(!decoded.notificationPreferences.permissionPrompted)
    }
}

extension NotificationTests {
    @Test func sellerNotificationUsesTheSameLocalizedIdentityAsTheConversation() throws {
        let definitions = try SeedContent.load().items
        let original = try GameSnapshot.fresh(definitions: definitions)
        let listing = original.market[1] // Jana/Julien, not legacy English Jordan.
        let state = try SimulationActions(timing: .production).offer(listingID: listing.id, amount: listing.askingPrice, modifier: .none, state: original, now: now)
        for language in GameText.supportedLanguages {
            let locale = Locale(identifier: language)
            let name = GameText.marketPerson("name", index: listing.seller.identityIndex, market: state.marketConfiguration, locale: locale)
            let plan = try NotificationPlanner().makePlan(state: state, definitions: definitions, locale: locale, now: now)
            #expect(plan.count == 1)
            #expect(plan[0].body.contains(name))
        }
    }
}
