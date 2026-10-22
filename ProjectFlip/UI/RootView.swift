import SwiftUI
import OSLog

struct RootView: View {
    @State private var store: GameStore?
    @State private var failed = false
    @State private var competition: CompetitionStore?
    @State private var selectedTab = 0
    @State private var keyboardVisible = false
    @State private var tabRoots = (0..<5).map { _ in UUID() }
    @State private var notificationService = LocalNotificationService.shared
    @State private var inbox = NotificationInbox.shared
    @State private var notificationRoute: GameRoute?
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market
    @Environment(\.scenePhase) private var scenePhase

    private var waitingBuyerCount: Int {
        store?.snapshot.playerListings.filter { listing in
            listing.status == .active && store?.snapshot.hasBuyerReply(for: listing.id) != true && listing.offers.last.map { [.pending, .countered].contains($0.status) } == true
        }.count ?? 0
    }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    if let store {
                        MarketView(store: store, competition: competition)
                    } else if failed {
                        ContentUnavailableView {
                            Label("save.error.title", systemImage: "exclamationmark.triangle")
                        } description: { Text("save.error.load") } actions: {
                            Button("action.retry", action: load)
                        }
                    } else { ProgressView() }

                }
                .id(tabRoots[0])
                .tabItem { Label("market.title", systemImage: "square.grid.2x2") }.tag(0)
                NavigationStack {
                    if let store { MessagesView(store: store) }
                }
                .id(tabRoots[1])
                .tabItem { Label("messages.title", systemImage: "bubble.left.and.bubble.right") }.tag(1)
                NavigationStack {
                    if let store { InventoryView(store: store) }
                }
                .id(tabRoots[2])
                .tabItem { Label("inventory.title", systemImage: "shippingbox") }.tag(2)
                NavigationStack {
                    if let store { ShopView(store: store) }
                }
                .id(tabRoots[3])
                .tabItem { Label("shop.title", systemImage: "storefront") }.badge(waitingBuyerCount).tag(3)
                NavigationStack {
                    if let store { ProfileView(store: store, competition: competition, retryCompetition: loadCompetition) }
                }
                .id(tabRoots[4])
                .tabItem { Label("profile.title", systemImage: "person.crop.circle") }.tag(4)
            }
            .id(store?.snapshot.marketConfiguration.currency)
            .toolbar(.hidden, for: .tabBar)
            if !keyboardVisible { GameDock(selection: $selectedTab, waitingBuyers: waitingBuyerCount) { index in
                notificationRoute = nil
                tabRoots[index] = UUID()
            } }
        }
        .background(GameStyle.ink)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in keyboardVisible = true }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in keyboardVisible = false }
        .environment(\.returnToHunt, {
            notificationRoute = nil
            store?.perform { try store?.acknowledgeAwayReport() }
            tabRoots[0] = UUID()
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
        .onChange(of: GameCenterService.shared.networkGeneration) { _, _ in
            if let competition, GameCenterService.shared.playerID != nil { Task { await competition.sync(using: GameCenterService.shared) } }
        }
        .onChange(of: inbox.pending) { _, _ in consumeNotificationRoute() }
        .onChange(of: locale.identifier) { _, _ in configureNotifications() }
        .task { if store == nil { load() } }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            store?.perform { try store?.catchUp(showSummary: true) }
            configureNotifications()
            if let store { competition?.observeCareer(store.snapshot) }
            if GameCenterService.shared.playerID != nil, let competition { Task { await competition.sync(using: GameCenterService.shared) } }
            while !Task.isCancelled {
                if store?.errorKey == nil { store?.perform { try store?.processDueEvents() } }
                do { try await Task.sleep(for: .seconds(1)) }
                catch { return } // Foreground polling stops when the scene task is cancelled.
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { store?.perform { try store?.catchUp() } }
        }
        .environment(\.marketConfiguration, store?.snapshot.marketConfiguration ?? .us)
        .font(.system(.body, design: .rounded))
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
            let isolated = arguments.firstIndex(of: "--uitest-save").map { arguments.indices.contains($0 + 1) && UUID(uuidString: arguments[$0 + 1]) != nil } ?? false
            let timing: SimulationTiming = isolated && arguments.contains("--uitest-instant") ? .instant : isolated && !arguments.contains("--uitest-production-timing") ? .debug : .current
            #else
            let timing = SimulationTiming.current
            #endif
            #if DEBUG
            let competitionFixture = isolated && arguments.contains("--uitest-competition-fixture") && !FileManager.default.fileExists(atPath: repository.url.path)
            let recoveryFixture = isolated && arguments.contains("--uitest-recovery-fixture") && !FileManager.default.fileExists(atPath: repository.url.path)
            #endif
            store = try GameStore(repository: repository, definitions: SeedContent.load().items, timing: timing)
            #if DEBUG
            if competitionFixture { try store?.debugSeedCompetitionOnboarding() }
            if isolated, let index = arguments.firstIndex(of: "--uitest-advance"), arguments.indices.contains(index + 1),
               let seconds = TimeInterval(arguments[index + 1]), seconds.isFinite, (1...604_800).contains(seconds) {
                try store?.debugAdvanceTime(by: seconds)
            }
            if recoveryFixture, let store { var fixture = store.snapshot; fixture.player.cash = .zero; try store.commit(fixture) }
            #endif
            failed = false
            loadCompetition()
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
    private func loadCompetition() {
        guard let store else { return }
        do {
            var repository = try SaveRepository.application()
            #if DEBUG
            let arguments = ProcessInfo.processInfo.arguments
            if let index = arguments.firstIndex(of: "--uitest-save"), arguments.indices.contains(index + 1), let id = UUID(uuidString: arguments[index + 1]) {
                repository = SaveRepository(url: FileManager.default.temporaryDirectory.appendingPathComponent("UITests/\(id.uuidString).json"))
            }
            #endif
            let root = repository.url.deletingLastPathComponent().appendingPathComponent(repository.url.deletingPathExtension().lastPathComponent + "-competition")
            competition = try CompetitionStore(root: root, definitions: store.definitions)
            competition?.observeCareer(store.snapshot)
            configureNotifications()
        } catch { GameCenterService.shared.debugFailure(error) }
    }
    private func configureNotifications() {
        guard let store else { return }
        let definitions = store.definitions
        let service = notificationService
        let locale = locale
        let competition = competition
        store.onSnapshotCommitted = { state in
            service.requestSync(state: state, definitions: definitions, locale: locale)
            competition?.observeCareer(state)
        }
        service.requestSync(state: store.snapshot, definitions: definitions, locale: locale)
    }

    private func consumeNotificationRoute() {
        guard store != nil, let route = inbox.pending else { return }
        notificationRoute = route
        inbox.pending = nil
    }

}
