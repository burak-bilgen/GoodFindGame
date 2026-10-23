import SwiftUI

struct CareerHuntPrompt: View {
    let store: GameStore
    @Environment(\.locale) private var locale
    private var focused: CollectionDefinition? { CollectionDefinition.all.first { $0.id == store.snapshot.collections.focus } }
    @ViewBuilder private var ambitionDestination: some View {
        if focused != nil { CollectionGalleryView(store: store) }
        else if store.snapshot.clients.active != nil { ClientBookView(store: store) }
        else { TraderCareerView(store: store) }
    }
    var body: some View {
        NavigationLink { ambitionDestination } label: {
            HStack(spacing: 12) {
                Image(systemName: "seal.fill").foregroundStyle(GameStyle.amber)
                VStack(alignment: .leading, spacing: 4) {
                    Text(GameText.string(focused?.titleKey ?? (store.snapshot.clients.active != nil ? "clients.accepted" : store.snapshot.career.tier(knowledge: store.snapshot.inspectionKnowledge).key), locale: locale)).font(.headline)
                    Group {
                        if let focused { Text(GameText.format("collections.progress", locale: locale, focused.count(in: store.snapshot), focused.models.count)) }
                        else if let next = CareerTier(rawValue: store.snapshot.career.tier(knowledge: store.snapshot.inspectionKnowledge).rawValue + 1) {
                            Text(GameText.format("career.nextProgress", locale: locale, min(store.snapshot.career.creditedItems.count, next.requiredSales), next.requiredSales,
                                                 GameText.string(next.key, locale: locale)))
                            if next.requiredKnowledge > 0 {
                                Text(GameText.string("career.requirement.\(next.rawValue)", locale: locale))
                            }
                        } else { Text("career.nextHunt") }
                    }.font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right").foregroundStyle(GameStyle.amber)
            }.gameCard(accent: GameStyle.amber)
        }.buttonStyle(.plain).accessibilityIdentifier("careerHunt")
    }
}

struct TraderCareerView: View {
    let store: GameStore
    @Environment(\.locale) private var locale
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 16) {
                    TraderPortrait(identity: 0, size: 72)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(GameText.string(store.snapshot.career.tier(knowledge: store.snapshot.inspectionKnowledge).key, locale: locale)).font(.title2.bold()).accessibilityIdentifier("careerRank")
                        Text(GameText.format("career.trust", locale: locale, store.snapshot.player.reputation)).font(.subheadline)
                    }
                }.gameCard(accent: GameStyle.amber)
                if store.competitionPeriod == nil {
                NavigationLink { ClientBookView(store: store) } label: { GameMenuRow(titleKey: "clients.title", symbol: "person.2.fill") }.buttonStyle(.plain).accessibilityIdentifier("careerClients")
                NavigationLink { CollectionGalleryView(store: store) } label: { GameMenuRow(titleKey: "collections.title", symbol: "square.grid.3x1.below.line.grid.1x2") }.buttonStyle(.plain)
                }
                Text("career.principle").font(.subheadline).foregroundStyle(.secondary)
                ForEach(CareerTier.allCases, id: \.self) { tier in
                    let earned = store.snapshot.career.tier(knowledge: store.snapshot.inspectionKnowledge).rawValue >= tier.rawValue
                    VStack(alignment: .leading, spacing: 10) {
                        Label(GameText.string(tier.key, locale: locale), systemImage: earned ? "checkmark.seal.fill" : "lock.fill").font(.headline).foregroundStyle(earned ? GameStyle.gain : GameStyle.amber)
                        Text(GameText.string("career.requirement.\(tier.rawValue)", locale: locale)).font(.subheadline)
                        Text(GameText.string("career.access.\(tier.rawValue)", locale: locale)).font(.caption).foregroundStyle(.secondary)
                    }.frame(maxWidth: .infinity, alignment: .leading).gameCard(accent: earned ? GameStyle.gain : nil)
                }
                Text(GameText.format("career.record", locale: locale, store.snapshot.career.creditedItems.count, store.snapshot.career.clientJobs)).font(.caption)
                NavigationLink("knowledge.open") { KnowledgeView(store: store) }.buttonStyle(GameButton(secondary: true))
            }.padding(16)
        }.gameScreen().navigationTitle("career.title").navigationBarTitleDisplayMode(.inline)
    }
}
