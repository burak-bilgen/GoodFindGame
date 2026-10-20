import SwiftUI
import OSLog

struct RootView: View {
    @State private var store: GameStore?
    @State private var failed = false
    @State private var selectedTab = 0
    @State private var marketRoot = UUID()
    @State private var notificationService = LocalNotificationService.shared
    @State private var inbox = NotificationInbox.shared
    @State private var notificationRoute: GameRoute?
    @Environment(\.locale) private var locale
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                if let store {
                    MarketView(store: store)
                } else if failed {
                    ContentUnavailableView {
                        Label("save.error.title", systemImage: "exclamationmark.triangle")
                    } description: { Text("save.error.load") } actions: {
                        Button("action.retry", action: load)
                    }
                } else { ProgressView() }

            }
            .id(marketRoot)
            .tabItem { Label("market.title", systemImage: "square.grid.2x2") }.tag(0)
            NavigationStack {
                if let store {
                    List(store.snapshot.conversations) { conversation in
                        NavigationLink {
                            ConversationView(store: store, listingID: conversation.listingID)
                        } label: {
                            if let listing = store.snapshot.market.first(where: { $0.id == conversation.listingID }), let definition = store.definition(for: listing.item) {
                                HStack(spacing: 12) {
                                    DeviceArt(symbol: definition.artSymbol, identity: definition.id).frame(width: 64, height: 72)
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(definition.name).font(.headline)
                                        Text(GameText.string("npc.name.\(listing.seller.identityIndex % 10)", locale: locale)).font(.subheadline)
                                        if conversation.pendingReplyEventID != nil {
                                            Label("seller.awaitingReply", systemImage: "clock").font(.caption).foregroundStyle(.secondary)
                                        } else if let last = conversation.messages.last {
                                            Text(GameText.string(last.intent, locale: locale)).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                                            if let amount = last.amount { Text(amount.formatted(locale: locale)).font(.caption.bold()) }
                                        }
                                    }
                                }
                            }
                        }.accessibilityIdentifier("conversation.\(conversation.listingID.rawValue)")
                    }.gameScreen().navigationTitle("messages.title")
                }
            }
            .tabItem { Label("messages.title", systemImage: "bubble.left.and.bubble.right") }.tag(1)
            NavigationStack {
                if let store { InventoryView(store: store) }
            }
            .tabItem { Label("inventory.title", systemImage: "shippingbox") }.tag(2)
            NavigationStack {
                if let store { SellingView(store: store) }
            }
            .tabItem { Label("selling.title", systemImage: "tag") }.tag(3)
            NavigationStack {
                if let store { ProfileView(store: store) }
            }
            .tabItem { Label("profile.title", systemImage: "person.crop.circle") }.tag(4)
        }
        .environment(\.returnToHunt, {
            notificationRoute = nil
            store?.perform { try store?.acknowledgeAwayReport() }
            marketRoot = UUID()
            selectedTab = 0
        })
        .onChange(of: store?.snapshot.playerListings.reduce(0, { $0 + $1.offers.count })) { old, new in
            if let old, let new, new > old { GameFeel.play(.offer) }
        }
        .alert("error.title", isPresented: Binding(get: { store?.errorKey != nil }, set: { if !$0 { store?.errorKey = nil } })) {
            Button("action.ok") { store?.errorKey = nil }
        } message: {
            Text(GameText.string(store?.errorKey ?? "save.error.write", locale: locale))
        }
        .sheet(item: Binding(get: {
            if let notificationRoute { return AppPresentation.notification(notificationRoute) }
            if store?.snapshot.awayReport.isEmpty == false { return AppPresentation.away }
            return nil
        }, set: { value in
            if value == nil {
                if notificationRoute != nil { notificationRoute = nil }
                else { store?.perform { try store?.acknowledgeAwayReport() } }
            }
        })) { presentation in
            if let store {
                switch presentation {
                case .away: WhileAwayView(store: store)
                case .notification(let route): NotificationRouteView(store: store, route: route)
                }
            }
        }
        .onChange(of: inbox.pending) { _, _ in consumeNotificationRoute() }
        .onChange(of: locale.identifier) { _, _ in configureNotifications() }
        .task { if store == nil { load() } }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            store?.perform { try store?.catchUp(showSummary: true) }
            configureNotifications()
            while !Task.isCancelled {
                if store?.errorKey == nil { store?.perform { try store?.processDueEvents() } }
                do { try await Task.sleep(for: .seconds(1)) }
                catch { return } // Foreground polling stops when the scene task is cancelled.
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { store?.perform { try store?.catchUp() } }
        }
        .tint(Color("AccentColor"))
    }
    private func load() {
        do {
            var repository = try SaveRepository.application()
            #if DEBUG
            let arguments = ProcessInfo.processInfo.arguments
            if let index = arguments.firstIndex(of: "--uitest-save"), arguments.indices.contains(index + 1), let id = UUID(uuidString: arguments[index + 1]) {
                repository = SaveRepository(url: FileManager.default.temporaryDirectory.appendingPathComponent("UITests/\(id.uuidString).json"))
            }
            #endif
            #if DEBUG
            let timing = arguments.contains("--uitest-instant") ? SimulationTiming.instant : .current
            #else
            let timing = SimulationTiming.current
            #endif
            store = try GameStore(repository: repository, definitions: SeedContent.load().items, timing: timing)
            failed = false
            configureNotifications()
            #if DEBUG
            if let index = arguments.firstIndex(of: "--uitest-route"), arguments.indices.contains(index + 1) { inbox.receive(arguments[index + 1]) }
            #endif
            consumeNotificationRoute()
        } catch {
            failed = true
            #if DEBUG
            Logger(subsystem: "ProjectFlip", category: "Load").error("Load failed: \(String(describing: error), privacy: .public)")
            #endif
        }
    }
    private func configureNotifications() {
        guard let store else { return }
        let definitions = store.definitions
        let service = notificationService
        let locale = locale
        store.onSnapshotCommitted = { state in service.requestSync(state: state, definitions: definitions, locale: locale) }
        service.requestSync(state: store.snapshot, definitions: definitions, locale: locale)
    }

    private func consumeNotificationRoute() {
        guard store != nil, let route = inbox.pending else { return }
        notificationRoute = route
        inbox.pending = nil
    }

}
