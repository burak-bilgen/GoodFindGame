import SwiftUI

struct RepairPlanView: View {
    let store: GameStore
    let itemID: ItemID
    @State private var selection: Set<Defect> = []
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let item = store.snapshot.player.inventory.first(where: { $0.id == itemID }), let definition = store.definition(for: item) {
                    Text(definition.displayName(locale: locale)).font(.title2.bold()).accessibilityIdentifier("repairPlanProductTitle")
                    Text("repair.plan.explain").foregroundStyle(GameStyle.secondaryText)
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(item.knownActiveDefects.sorted { $0.rawValue < $1.rawValue }, id: \.self) { defect in
                            Toggle(isOn: Binding(get: { selection.contains(defect) }, set: { enabled in
                                if enabled { selection.insert(defect) } else { selection.remove(defect) }
                            })) {
                                Text(GameText.string(defect.key, locale: locale)).font(.headline)
                            }.frame(minHeight: 44).accessibilityIdentifier("planFault.\(defect.rawValue)")
                        }
                        if item.knownActiveDefects.isEmpty { Text("repair.plan.noWork") }
                    }.gameCard()
                    switch Result(catching: { try RepairPlan(item: item, definition: definition, selecting: selection, marketBasisPoints: store.snapshot.marketMultiplier(for: definition)) }) {
                    case .success(let plan):
                        VStack(alignment: .leading, spacing: 12) {
                            LabeledContent("repair.plan.total") { Text(plan.cost.formatted(locale: locale, market: market, precise: true)).bold().accessibilityIdentifier("planCost") }
                            LabeledContent("repair.recovery") { Text(plan.estimatedRecovery.formatted(locale: locale, market: market, signed: true, precise: true)).bold() }
                            if let change = try? plan.estimatedNetChange {
                                Text("repair.marginEstimate").font(.subheadline.bold())
                                ProfitAmount(amount: change).font(.title.bold()).accessibilityIdentifier("planNet")
                                Text(change < .zero ? "repair.marginNegative" : change > .zero ? "repair.marginPositive" : "repair.marginEven")
                                    .font(.caption).foregroundStyle(GameStyle.secondaryText)
                            }
                            Text("repair.plan.uncertainty").font(.caption).foregroundStyle(GameStyle.secondaryText)
                            Button("repair.plan.apply") {
                                store.perform {
                                    try store.repair(itemID: itemID, selection: selection, expectedCost: plan.cost)
                                    GameFeel.play(.accepted)
                                    dismiss()
                                }
                            }.buttonStyle(GameButton()).accessibilityIdentifier("applyRepairPlan")
                                .disabled(selection.isEmpty || store.snapshot.player.cash < plan.cost || !ItemTransfer.available(itemID, state: store.snapshot))
                            if store.snapshot.player.cash < plan.cost { Text("error.insufficientCash").foregroundStyle(GameStyle.loss) }
                            if !ItemTransfer.available(itemID, state: store.snapshot) { Text("clients.itemBusy").font(.caption).foregroundStyle(GameStyle.secondaryText) }
                            Button("repair.plan.leave") { dismiss() }.buttonStyle(GameButton(secondary: true)).accessibilityIdentifier("leaveRepairPlan")
                        }.gameCard(accent: GameStyle.amber)
                    case .failure: Text("inspection.valueUnavailable")
                    }
                } else { Text("trade.unavailable") }
            }.padding(16)
        }.gameScreen().navigationTitle("repair.plan.title").navigationBarTitleDisplayMode(.inline)
    }
}
