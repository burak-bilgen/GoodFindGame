import SwiftUI
import UIKit

struct NotificationSettingsView: View {
    let store: GameStore
    @State private var service = LocalNotificationService.shared
    @Environment(\.locale) private var locale
    @Environment(\.openURL) private var openURL
    @State private var requesting = false

    var body: some View {
        Form {
            Section {
                Text("notifications.explanation")
                Text(GameText.string("notifications.status.\(service.authorization.rawValue)", locale: locale))
                if service.authorization == .notDetermined || service.authorization == .unknown {
                    if !store.hasExperiencedAsyncEvent { Text("notifications.afterFirstEvent").font(.caption).foregroundStyle(.secondary) }
                    Button("notifications.enable") {
                        store.perform { try store.markNotificationPrompted() }
                        guard store.errorKey == nil else { return }
                        requesting = true
                        Task {
                            await service.requestAuthorization()
                            service.requestSync(state: store.snapshot, definitions: store.definitions, locale: locale)
                            requesting = false
                        }
                    }.disabled(!store.hasExperiencedAsyncEvent || requesting).accessibilityIdentifier("enableNotifications")
                    Button("notifications.later") { store.perform { try store.markNotificationPrompted() } }
                } else if service.authorization == .denied, let url = URL(string: UIApplication.openSettingsURLString) {
                    Button("notifications.openSettings") { openURL(url) }
                }
            }
            Section("notifications.categories") {
                ForEach(LocalNotificationCategory.allCases, id: \.self) { category in
                    Toggle(isOn: Binding(get: { store.snapshot.notificationPreferences.enabledCategories.contains(category) }, set: { enabled in
                        store.perform { try store.setNotificationCategory(category, enabled: enabled) }
                    })) { Text(GameText.string(category.key, locale: locale)) }
                        .accessibilityIdentifier("notificationCategory.\(category.rawValue)")
                }
            }
            if let key = service.lastErrorKey {
                Section {
                    Text(GameText.string(key, locale: locale))
                    Button("action.retry") { service.requestSync(state: store.snapshot, definitions: store.definitions, locale: locale) }
                }
            }
        }
        .navigationTitle("notifications.settings")
        .task { service.requestSync(state: store.snapshot, definitions: store.definitions, locale: locale) }
    }
}

struct NotificationRouteView: View {
    let store: GameStore
    let route: GameRoute
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Group {
            switch route.kind {
            case .marketListing:
                if let target = route.targetID, store.snapshot.market.contains(where: { $0.id.rawValue == target }) {
                    ListingDetailView(store: store, listingID: ListingID(target))
                } else { unavailable }
            case .marketTrend:
                if let trend = store.snapshot.marketTrends.first(where: { $0.id == route.targetID }) {
                    MarketTrendDetailView(store: store, trend: trend)
                } else { unavailable }
            case .conversation:
                if let target = route.targetID, store.snapshot.market.contains(where: { $0.id.rawValue == target }) { ConversationView(store: store, listingID: ListingID(target)) }
                else { unavailable }
            case .inventory:
                if let target = route.targetID, store.snapshot.player.inventory.contains(where: { $0.id.rawValue == target }) { OwnedItemView(store: store, itemID: ItemID(target)) }
                else { unavailable }
            case .sale:
                if let target = route.targetID, store.snapshot.playerListings.contains(where: { $0.id.rawValue == target }) { SaleListingView(store: store, listingID: ListingID(target)) }
                else { unavailable }
            case .notificationSettings: NotificationSettingsView(store: store)
            case .unavailable: unavailable
            }
            }
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("action.close") { dismiss() }.accessibilityIdentifier("closeNotificationDestination") } }
        }
    }
    private var unavailable: some View {
        VStack(spacing: 20) {
            Text("away.alreadyHandled")
            NavigationLink("trade.history") { TradeHistoryView(store: store) }
        }.padding().navigationTitle("notifications.settings")
    }
}

enum AppPresentation: Identifiable {
    case away
    case notification(GameRoute)
    var id: String {
        switch self {
        case .away: "away"
        case .notification(let route): "notification-\(route.id)"
        }
    }
}
