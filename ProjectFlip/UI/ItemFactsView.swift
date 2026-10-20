import SwiftUI

struct ItemFactsView: View {
    let store: GameStore
    let itemID: ItemID
    @Environment(\.locale) private var locale

    var body: some View {
        if let item = store.snapshot.player.inventory.first(where: { $0.id == itemID }) {
            List {
                if let definition = store.definition(for: item) { Text(definition.name).font(.headline) }
                Text("facts.explanation").foregroundStyle(.secondary)
                if let facts = item.facts {
                    ForEach(facts.values) { fact in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(GameText.string("facts.field.\(fact.key.rawValue)", locale: locale)).font(.headline)
                            if item.knownFactKeys.contains(fact.key) {
                                FactValueText(fact: fact).accessibilityIdentifier("factValue.\(fact.key.rawValue)")
                            } else {
                                Label("facts.notChecked", systemImage: "lock").accessibilityIdentifier("factLocked.\(fact.key.rawValue)")
                                if fact.key.requiresTools {
                                    Text(GameText.format("facts.requiresSkills", locale: locale, GameText.string("knowledge.level.\(fact.key.requiredLevel)", locale: locale)))
                                        .font(.caption).foregroundStyle(.secondary)
                                } else {
                                    Text("facts.requiresBasic").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    if facts.category == .retro { Text("facts.regionGuide").font(.caption).foregroundStyle(.secondary) }
                } else {
                    Text("facts.legacyUnavailable")
                }
                Text("facts.valueGuide").font(.caption).foregroundStyle(.secondary)
            }.navigationTitle("facts.title")
        } else {
            ContentUnavailableView("listing.unavailable", systemImage: "shippingbox")
        }
    }
}

struct FactValueText: View {
    let fact: ItemFact
    @Environment(\.locale) private var locale
    var body: some View {
        switch fact.value {
        case .number(let number):
            if fact.key == .batteryHealth {
                Text((Decimal(number) / 100).formatted(.percent.locale(locale)))
            } else if fact.key == .cosmeticScore {
                Text(GameText.format("facts.score", locale: locale, number.formatted(.number.locale(locale))))
            } else {
                Text(number, format: .number)
            }
        case .term(let term):
            Text(GameText.string("facts.term.\(term.rawValue)", locale: locale))
        }
    }
}
