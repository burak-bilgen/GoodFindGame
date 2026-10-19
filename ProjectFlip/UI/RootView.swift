import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            NavigationStack {
                ContentUnavailableView("market.title", systemImage: "sparkle.magnifyingglass", description: Text("market.empty"))
                    .navigationTitle("market.title")
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
        .tint(Color(red: 0.19, green: 0.36, blue: 0.43))
    }
}
