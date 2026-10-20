import SwiftUI

struct InventoryView: View {
    let store: GameStore
    @Environment(\.locale) private var locale
    var body: some View {
        List {
            if store.snapshot.player.inventory.isEmpty && !store.snapshot.shipments.contains(where: { $0.status == .pending }) {
                Text("inventory.empty").foregroundStyle(.secondary)
                HuntButton()
            }
            ForEach(store.snapshot.shipments.filter { $0.status == .pending }) { shipment in
                VStack(alignment: .leading, spacing: 8) {
                    if let definition = store.definition(for: shipment.item) {
                        DeviceArt(symbol: definition.artSymbol, identity: definition.id).frame(height: 140)
                        Text(definition.name).font(.headline)
                    }
                    DeadlineView(store: store, target: shipment.arrivesAt, titleKey: "shipping.inTransit")
                }.accessibilityIdentifier("shipment.\(shipment.item.id.rawValue)")
            }
            ForEach(store.snapshot.player.inventory) { item in
                if let definition = store.definition(for: item) {
                    NavigationLink { OwnedItemView(store: store, itemID: item.id) } label: {
                        HStack(spacing: 14) {
                            DeviceArt(symbol: definition.artSymbol, identity: definition.id).frame(width: 90, height: 90)
                            VStack(alignment: .leading, spacing: 8) {
                                Text(definition.name).font(.headline)
                                Text(item.purchasePrice.formatted(locale: locale)).foregroundStyle(.secondary)
                                Text(item.inspected ? "inspection.basicComplete" : "inspection.pendingBasic").font(.caption)
                            }
                        }
                    }.accessibilityIdentifier("inventory.\(item.id.rawValue)")
                }
            }
        }.gameScreen().navigationTitle("inventory.title")
    }
}

struct OwnedItemView: View {
    let store: GameStore
    let itemID: ItemID
    @Environment(\.locale) private var locale
    @State private var newReveal = false
    var body: some View {
        if let item = store.snapshot.player.inventory.first(where: { $0.id == itemID }), let definition = store.definition(for: item) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    DeviceArt(symbol: definition.artSymbol, identity: definition.id).frame(height: 170)
                    Text(definition.name).font(.system(.title, design: .rounded, weight: .heavy))
                    Text(item.inspected ? "inspection.basicComplete" : "inspection.pendingBasic").font(.subheadline).foregroundStyle(.secondary)
                    if store.snapshot.inspectionKnowledge.canInspect(item, category: definition.category) {
                        Button(item.inspected ? "knowledge.reinspect" : "inspection.basic") {
                            store.perform { try store.inspect(itemID: item.id, professionally: false); newReveal = true }
                        }.buttonStyle(GameButton()).accessibilityIdentifier("basicInspect")
                    }
                    if item.inspected {
                        InspectionReveal(store: store, item: item, definition: definition, animateReveal: newReveal)
                        if !store.snapshot.playerListings.contains(where: { $0.itemID == item.id && $0.status == .active }) {
                            ForEach(item.knownActiveDefects, id: \.self) { defect in
                                RepairDecision(store: store, item: item, definition: definition, defect: defect)
                            }
                            NavigationLink { CreateListingView(store: store, itemID: item.id) } label: {
                                Text(item.knownActiveDefects.isEmpty ? "selling.create" : "repair.asIs")
                            }.buttonStyle(GameButton()).accessibilityIdentifier("createListing")
                        } else { Text("selling.alreadyListed").foregroundStyle(.secondary) }
                    }
                    if let job = store.snapshot.inspectionJobs.first(where: { $0.itemID == item.id && $0.status == .pending }) {
                        DeadlineView(store: store, target: job.completesAt, titleKey: "inspection.pendingReport")
                    } else if !item.professionallyInspected {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("inspection.professional").font(.headline)
                            Text("inspection.professionalDescription").font(.subheadline).foregroundStyle(.secondary)
                            Text(InspectionEngine().professionalCost.formatted(locale: locale)).bold()
                            Button("inspection.professionalStart") { store.perform { try store.inspect(itemID: item.id, professionally: true) } }
                                .buttonStyle(.bordered).accessibilityIdentifier("professionalInspect")
                        }.gameCard()
                    }
                    NavigationLink("facts.title") { ItemFactsView(store: store, itemID: item.id) }.accessibilityIdentifier("openItemFacts")
                    DisclosureGroup("reveal.details") {
                        VStack(alignment: .leading, spacing: 12) {
                            LabeledContent("purchase.cost") { Text(item.purchasePrice.formatted(locale: locale)) }
                            KnowledgeSummary(knowledge: store.snapshot.inspectionKnowledge, category: definition.category)
                            Text("knowledge.inspectionLimit").font(.caption).foregroundStyle(.secondary)
                            NavigationLink("knowledge.open") { KnowledgeView(store: store) }
                        }.padding(.top, 10)
                    }.gameCard()
                }.padding(16)
            }.gameScreen().navigationTitle("inventory.title").navigationBarTitleDisplayMode(.inline)
                .onChange(of: item.professionallyInspected) { _, inspected in if inspected { newReveal = true } }
        }
    }
}

struct InspectionReveal: View {
    let store: GameStore
    let item: ItemInstance
    let definition: ItemDefinition
    var animateReveal = false
    @Environment(\.locale) private var locale
    @GameReduceMotion private var reduceMotion
    @State private var step = 0
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GameEyebrow(key: "reveal.heading")
            Group {
                LabeledContent("inspection.condition") { Text(item.condition, format: .number).font(.system(.largeTitle, design: .rounded, weight: .heavy)).accessibilityIdentifier("inspectionCondition") }
                Text("reveal.condition").font(.subheadline).foregroundStyle(.secondary)
            }.opacity(step >= 1 ? 1 : 0).accessibilityHidden(step < 1)
            Group {
                if item.knownActiveDefects.isEmpty {
                    Label(!(item.repairedDefects ?? []).isEmpty ? "inspection.repairedClear" : item.professionallyInspected ? "inspection.professionalClean" : "inspection.noObviousFault", systemImage: "checkmark.circle")
                        .font(.subheadline).foregroundStyle(GameStyle.gain)
                } else {
                    ForEach(item.knownActiveDefects, id: \.self) { defect in
                        Label(GameText.string(defect.key, locale: locale), systemImage: "exclamationmark.triangle.fill")
                            .font(.title3.bold()).foregroundStyle(GameStyle.loss).accessibilityIdentifier("revealedDefect.\(defect.rawValue)")
                    }
                }
                ForEach(item.repairedDefects ?? [], id: \.self) { defect in
                    HStack { Text(GameText.string(defect.key, locale: locale)); Spacer(); Label("reveal.repaired", systemImage: "wrench.adjustable.fill") }.font(.caption).foregroundStyle(GameStyle.gain)
                }
            }.opacity(step >= 2 ? 1 : 0).accessibilityHidden(step < 2)
            Group {
                Divider()
                GameEyebrow(key: "reveal.estimate")
                Text("inspection.estimatedValue").font(.subheadline)
                switch Result(catching: { try InspectionEngine().estimatedValue(item: item, definition: definition, marketBasisPoints: store.snapshot.marketMultiplier(for: definition)) }) {
                case .success(let estimate): Text(estimate.formatted(locale: locale)).font(.system(.title, design: .rounded, weight: .bold)).contentTransition(.numericText())
                case .failure: Text("inspection.valueUnavailable")
                }
                Text("inspection.estimateWarning").font(.caption).foregroundStyle(.secondary)
            }.opacity(step >= 3 ? 1 : 0).accessibilityHidden(step < 3)
            Button("reveal.continue") { step = 3 }.font(.subheadline.bold()).accessibilityIdentifier("skipReveal")
                .opacity(step < 3 ? 1 : 0).allowsHitTesting(step < 3).accessibilityHidden(step >= 3)
        }.gameCard()
        .animation(reduceMotion ? nil : .easeOut(duration: 0.25), value: step)
        .task(id: "\(item.id.rawValue)-\(item.professionallyInspected)") {
            let presentationKey = "inspectionPresented-\(store.snapshot.simulationID)-\(item.id.rawValue)-\(item.professionallyInspected)"
            let unread = !UserDefaults.standard.bool(forKey: presentationKey)
            guard (animateReveal || unread) && !reduceMotion && !UIAccessibility.isVoiceOverRunning else {
                step = 3
                UserDefaults.standard.set(true, forKey: presentationKey)
                return
            }
            step = 1; GameFeel.play(.reveal)
            for next in 2...3 {
                do { try await Task.sleep(for: .milliseconds(650)) } catch { return }
                if step < next { step = next; if next == 2 && !item.knownActiveDefects.isEmpty { GameFeel.play(.defect) } }
            }
            UserDefaults.standard.set(true, forKey: presentationKey)
        }
    }
}

struct RepairDecision: View {
    let store: GameStore
    let item: ItemInstance
    let definition: ItemDefinition
    let defect: Defect
    @Environment(\.locale) private var locale
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("repair.title").font(.title3.bold())
            Text(GameText.string(defect.key, locale: locale)).font(.headline)
            switch Result(catching: { try RepairQuote(item: item, definition: definition, defect: defect, marketBasisPoints: store.snapshot.marketMultiplier(for: definition)) }) {
            case .success(let quote):
                LabeledContent("repair.cost") { Text(quote.cost.formatted(locale: locale)).bold() }
                LabeledContent("repair.recovery") { Text(quote.estimatedRecovery.formatted(locale: locale)) }
                Text("repair.immediate").font(.caption).foregroundStyle(.secondary)
                Button("repair.action") { store.perform { try store.repair(itemID: item.id, defect: defect); GameFeel.play(.accepted) } }
                    .buttonStyle(.bordered).accessibilityIdentifier("repair.\(defect.rawValue)")
            case .failure: Text("inspection.valueUnavailable")
            }
        }.gameCard()
    }
}

struct HuntButton: View {
    @Environment(\.returnToHunt) private var hunt
    var body: some View {
        Button(action: hunt) { Label("hunt.next", systemImage: "magnifyingglass") }
            .buttonStyle(GameButton()).accessibilityIdentifier("returnToHunt")
    }
}
