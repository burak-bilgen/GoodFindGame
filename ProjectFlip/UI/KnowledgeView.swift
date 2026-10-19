import SwiftUI

struct KnowledgeView: View {
    let store: GameStore
    @Environment(\.locale) private var locale

    var body: some View {
        List {
            Text("knowledge.explanation").foregroundStyle(.secondary)
            ForEach(ItemCategory.allCases, id: \.self) { category in
                Section(GameText.string("category.\(category.rawValue)", locale: locale)) {
                    KnowledgeSummary(knowledge: store.snapshot.inspectionKnowledge, category: category)
                    Text(GameText.string("knowledge.clues.\(category.rawValue)", locale: locale))
                    Text(GameText.string("knowledge.tools.\(category.rawValue)", locale: locale)).font(.caption).foregroundStyle(.secondary)
                    if store.snapshot.inspectionKnowledge.tools.contains(category) {
                        Label("knowledge.toolsOwned", systemImage: "checkmark.seal.fill")
                            .accessibilityIdentifier("toolsOwned.\(category.rawValue)")
                    } else {
                        LabeledContent("knowledge.toolCost") { Text(InspectionKnowledge.toolCost(for: category).formatted(locale: locale)) }
                        Button("knowledge.buyTools") {
                            store.perform { try store.buyInspectionTools(for: category) }
                        }.accessibilityIdentifier("buyTools.\(category.rawValue)")
                    }
                }
            }
        }.navigationTitle("knowledge.title")
    }
}

struct KnowledgeSummary: View {
    let knowledge: InspectionKnowledge
    let category: ItemCategory
    @Environment(\.locale) private var locale

    var body: some View {
        LabeledContent("knowledge.level") {
            Text(GameText.string("knowledge.level.\(knowledge.level(in: category))", locale: locale))
        }
        LabeledContent("knowledge.experience") { Text(knowledge.points(in: category), format: .number).accessibilityIdentifier("knowledgePoints.\(category.rawValue)") }
    }
}
