#if DEBUG
import SwiftUI

struct DeveloperToolsView: View {
    let store: GameStore
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market
    @State private var showTruth = false
    @State private var confirmReset = false
    @State private var selectedListing = ""

    var body: some View {
        GameForm {
            Section("debug.economy") {
                Text(store.snapshot.player.cash.formatted(locale: locale, market: market)).monospacedDigit()
                Button {
                    store.perform { try store.debugAddCash() }
                } label: {
                    HStack {
                        Text("debug.addCash")
                        Spacer()
                        Text(GameBalanceConfig.debugCashGrant.formatted(locale: locale, market: market))
                    }
                }.accessibilityIdentifier("debugAddCash")
                Button("debug.regenerate") { store.perform { try store.debugRegenerateMarket(); selectedListing = "" } }.accessibilityIdentifier("debugRegenerate")
                Button("debug.reset", role: .destructive) { confirmReset = true }
            }
            Section("debug.time") {
                Button("debug.advance30Minutes") { store.perform { try store.debugAdvanceTime(by: 30 * 60) } }.accessibilityIdentifier("debugAdvance30Minutes")
                Button("debug.advanceDay") { store.perform { try store.debugAdvanceTime(by: 24 * 60 * 60) } }.accessibilityIdentifier("debugAdvanceDay")
            }
            Section("debug.negotiation") {
                Picker("debug.listing", selection: $selectedListing) {
                    Text("debug.chooseListing").tag("")
                    ForEach(store.snapshot.market.filter(\.available)) { listing in
                        Text(store.definition(for: listing.item)?.displayName(locale: locale) ?? listing.id.rawValue).tag(listing.id.rawValue)
                    }
                }
                Button("debug.forceSeller") {
                    store.perform { try store.debugForceSellerResponse(listingID: ListingID(selectedListing)) }
                }.disabled(selectedListing.isEmpty)
                Button("debug.forceBuyer") { store.perform { try store.debugForceBuyerOffer() } }
            }
            Section {
                Toggle("debug.showTruth", isOn: $showTruth)
                if showTruth {
                    ForEach(store.snapshot.market.filter(\.available)) { listing in
                        truth(for: listing.item)
                    }
                    ForEach(store.snapshot.player.inventory) { item in truth(for: item) }
                }
            }
        }
        .gameScreen()
        .navigationTitle("debug.title")
        .confirmationDialog("debug.resetConfirm", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("debug.reset", role: .destructive) { store.perform { try store.debugReset(); selectedListing = "" } }
            Button("action.cancel", role: .cancel) {}
        }
    }

    private func truth(for item: ItemInstance) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let definition = store.definition(for: item) {
                Text(definition.displayName(locale: locale)).bold()
                Text("debug.condition \(item.condition)")
                switch Result(catching: { try PricingEngine.fairValue(of: item, definition: definition, marketBasisPoints: store.snapshot.marketMultiplier(for: definition)) }) {
                case .success(let value): Text(value.formatted(locale: locale, market: market))
                case .failure: Text("inspection.valueUnavailable")
                }
            }
            if item.hiddenDefects.isEmpty { Text("debug.noDefects") }
            ForEach(item.hiddenDefects, id: \.self) { defect in Text(GameText.string(defect.key, locale: locale)) }
        }
    }
}
#endif
