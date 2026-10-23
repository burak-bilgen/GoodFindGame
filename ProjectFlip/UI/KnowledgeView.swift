import SwiftUI

struct KnowledgeView: View {
    let store: GameStore
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market

    var body: some View {
        GameList {
            Text("knowledge.explanation").foregroundStyle(GameStyle.secondaryText)
            ForEach(store.playableCategories, id: \.self) { category in
                Section(GameText.string("category.\(category.rawValue)", locale: locale)) {
                    KnowledgeSummary(knowledge: store.snapshot.inspectionKnowledge, category: category)
                    Text(GameText.string("knowledge.clues.\(category.rawValue)", locale: locale))
                    Text(GameText.string("knowledge.tools.\(category.rawValue)", locale: locale)).font(.caption).foregroundStyle(GameStyle.secondaryText)
                    if store.snapshot.inspectionKnowledge.tools.contains(category) {
                        Label("knowledge.toolsOwned", systemImage: "checkmark.seal.fill")
                            .accessibilityIdentifier("toolsOwned.\(category.rawValue)")
                    } else {
                        LabeledContent("knowledge.toolCost") { Text(InspectionKnowledge.toolCost(for: category).formatted(locale: locale, market: market)) }
                        Button("knowledge.buyTools") {
                            store.perform { try store.buyInspectionTools(for: category) }
                        }.accessibilityIdentifier("buyTools.\(category.rawValue)")
                    }
                }
            }
        }.gameScreen().navigationTitle("knowledge.title")
    }
}

struct KnowledgeSummary: View {
    let knowledge: InspectionKnowledge
    let category: ItemCategory
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market

    var body: some View {
        LabeledContent("knowledge.level") {
            Text(GameText.string("knowledge.level.\(knowledge.level(in: category))", locale: locale))
        }
        Text(GameText.format("knowledge.casebook", locale: locale, knowledge.modelCount(in: category), knowledge.diagnosticCount(in: category))).font(.caption).foregroundStyle(GameStyle.secondaryText)
        Text("knowledge.endorsement").font(.caption).foregroundStyle(GameStyle.secondaryText)
        LabeledContent("knowledge.experience") { Text(knowledge.points(in: category), format: .number).accessibilityIdentifier("knowledgePoints.\(category.rawValue)") }
    }
}
