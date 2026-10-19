import SwiftUI
import OSLog

struct RootView: View {
    @State private var store: GameStore?
    @State private var failed = false

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
                ContentUnavailableView("messages.title", systemImage: "bubble.left.and.bubble.right", description: Text("messages.empty"))
                    .navigationTitle("messages.title")
            }
            .tabItem { Label("messages.title", systemImage: "bubble.left.and.bubble.right") }
            NavigationStack {
                ContentUnavailableView("inventory.title", systemImage: "shippingbox", description: Text("inventory.empty"))
                    .navigationTitle("inventory.title")
            }
            .tabItem { Label("inventory.title", systemImage: "shippingbox") }
            NavigationStack {
                ContentUnavailableView("selling.title", systemImage: "tag", description: Text("selling.empty"))
                    .navigationTitle("selling.title")
            }
            .tabItem { Label("selling.title", systemImage: "tag") }
            NavigationStack {
                Text("profile.intro").padding().navigationTitle("profile.title")
            }
            .tabItem { Label("profile.title", systemImage: "person.crop.circle") }
        }
        .task { if store == nil { load() } }
        .tint(Color(red: 0.19, green: 0.36, blue: 0.43))
    }
    private func load() {
        do {
            store = try GameStore(repository: .application(), definitions: SeedContent.load().items)
            failed = false
        } catch {
            failed = true
            #if DEBUG
            Logger(subsystem: "ProjectFlip", category: "Load").error("Load failed: \(String(describing: error), privacy: .public)")
            #endif
        }
    }
}
