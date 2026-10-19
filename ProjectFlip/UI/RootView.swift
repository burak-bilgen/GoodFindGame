import SwiftUI
import OSLog

struct RootView: View {
    @State private var store: GameStore?
    @State private var failed = false
    @Environment(\.locale) private var locale

    var body: some View {
        TabView {
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
            .tabItem { Label("market.title", systemImage: "square.grid.2x2") }
            NavigationStack {
                if let store {
                    List(store.snapshot.conversations) { conversation in
                        NavigationLink {
                            ConversationView(store: store, listingID: conversation.listingID)
                        } label: {
                            if let listing = store.snapshot.market.first(where: { $0.id == conversation.listingID }), let definition = store.definition(for: listing.item) { Text(definition.name) }
                        }
                    }.navigationTitle("messages.title")
                }
            }
            .tabItem { Label("messages.title", systemImage: "bubble.left.and.bubble.right") }
            NavigationStack {
                if let store { InventoryView(store: store) }
            }
            .tabItem { Label("inventory.title", systemImage: "shippingbox") }
            NavigationStack {
                if let store { SellingView(store: store) }
            }
            .tabItem { Label("selling.title", systemImage: "tag") }
            NavigationStack {
                if let store { ProfileView(store: store) }
            }
            .tabItem { Label("profile.title", systemImage: "person.crop.circle") }
        }
        .alert("error.title", isPresented: Binding(get: { store?.errorKey != nil }, set: { if !$0 { store?.errorKey = nil } })) {
            Button("action.ok") { store?.errorKey = nil }
        } message: {
            Text(GameText.string(store?.errorKey ?? "save.error.write", locale: locale))
        }
        .task { if store == nil { load() } }
        .tint(Color(red: 0.19, green: 0.36, blue: 0.43))
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
            store = try GameStore(repository: repository, definitions: SeedContent.load().items)
            failed = false
        } catch {
            failed = true
            #if DEBUG
            Logger(subsystem: "ProjectFlip", category: "Load").error("Load failed: \(String(describing: error), privacy: .public)")
            #endif
        }
    }
}
