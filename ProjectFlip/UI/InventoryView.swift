import SwiftUI

struct InventoryView: View {
    let store: GameStore
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                GameStageBanner(titleKey: "inventory.title", eyebrowKey: "game.workbench", symbol: "shippingbox.fill", color: GameStyle.amber)
                if store.snapshot.player.inventory.isEmpty && !store.snapshot.shipments.contains(where: { $0.status == .pending }) {
                    Text("inventory.empty").foregroundStyle(.secondary)
                    HuntButton()
                }
                ForEach(store.snapshot.shipments.filter { $0.status == .pending }) { shipment in
                    VStack(alignment: .leading, spacing: 8) {
                        if let definition = store.definition(for: shipment.item) {
                            DeviceArt(symbol: definition.artSymbol, identity: definition.id, appearance: store.appearance(for: shipment.item)).aspectRatio(1, contentMode: .fit)
                            Text(definition.displayName(locale: locale)).font(.headline)
                        }
                        Text("living.standardDelivery").font(.caption).foregroundStyle(.secondary)
                        DeadlineView(store: store, target: shipment.arrivesAt, titleKey: "shipping.inTransit")
                        HuntButton()
                    }.gameCard(accent: GameStyle.gain).accessibilityIdentifier("shipment.\(shipment.item.id.rawValue)")
                }
                ForEach(store.snapshot.player.inventory) { item in
                    if let definition = store.definition(for: item) {
                        NavigationLink { OwnedItemView(store: store, itemID: item.id) } label: {
                            HStack(spacing: 14) {
                                DeviceArt(symbol: definition.artSymbol, identity: definition.id, appearance: store.appearance(for: item)).frame(width: 90, height: 90)
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(definition.displayName(locale: locale)).font(.headline)
                                    Text(item.purchasePrice.formatted(locale: locale, market: market)).foregroundStyle(.secondary)
                                    Text(item.inspected ? "inspection.basicComplete" : "inspection.pendingBasic").font(.caption)
                                }
                            }.frame(maxWidth: .infinity, alignment: .leading).gameCard()
                        }.buttonStyle(.plain).accessibilityIdentifier("inventory.\(item.id.rawValue)")
                    }
                }
            }.padding(16)
        }.gameScreen().navigationTitle("inventory.title")
    }
}

struct OwnedItemView: View {
    let store: GameStore
    let itemID: ItemID
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market
    var body: some View {
        if let item = store.snapshot.player.inventory.first(where: { $0.id == itemID }), let definition = store.definition(for: item) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !item.inspected {
                        DeviceArt(symbol: definition.artSymbol, identity: definition.id, appearance: store.appearance(for: item)).aspectRatio(1, contentMode: .fit)
                    }
                    Text(definition.displayName(locale: locale)).font(.system(.title, design: .rounded, weight: .heavy))
                    if item.inspected && CollectionDefinition.all.contains(where: { $0.models.contains(item.definitionID) }) {
                        Button(store.snapshot.collections.displayed.contains(item.id) ? "collections.release" : "collections.display") {
                            store.perform {
                                let completed = store.snapshot.collections.completedBefore.count
                                try store.toggleDisplay(item.id)
                                GameFeel.play(store.snapshot.collections.completedBefore.count > completed ? .profit : .reveal)
                            }
                        }.buttonStyle(GameButton(secondary: true)).accessibilityIdentifier("toggleDisplay")
                        if store.snapshot.collections.displayed.contains(item.id) { Text("collections.lockedCapital").font(.caption).foregroundStyle(GameStyle.amber) }
                    }
                    Text(item.inspected ? "inspection.basicComplete" : "inspection.pendingBasic").font(.subheadline).foregroundStyle(.secondary)
                    if store.snapshot.inspectionKnowledge.canInspect(item, category: definition.category) {
                        Button(item.inspected ? "knowledge.reinspect" : "inspection.basic") {
                            store.perform { try store.inspect(itemID: item.id, professionally: false) }
                        }.buttonStyle(GameButton()).accessibilityIdentifier("basicInspect")
                    }
                    if item.inspected {
                        InspectionReveal(store: store, item: item, definition: definition)
                            .id(InspectionReportPresentation(item: item, simulationID: store.snapshot.simulationID).taskID)
                        if !store.snapshot.collections.displayed.contains(item.id) && !store.snapshot.playerListings.contains(where: { $0.itemID == item.id && $0.status == .active }) {
                            ForEach(item.knownActiveDefects, id: \.self) { defect in
                                RepairDecision(store: store, item: item, definition: definition, defect: defect)
                            }
                            NavigationLink { CreateListingView(store: store, itemID: item.id) } label: {
                                Text(item.knownActiveDefects.isEmpty ? "selling.create" : "repair.asIs")
                            }.buttonStyle(GameButton(secondary: !item.knownActiveDefects.isEmpty)).accessibilityIdentifier("createListing")
                        } else if let sale = store.snapshot.playerListings.first(where: { $0.itemID == item.id && $0.status == .active }) {
                            NavigationLink { SaleListingView(store: store, listingID: sale.id) } label: {
                                Label("selling.follow", systemImage: "tag.fill")
                            }.buttonStyle(GameButton()).accessibilityIdentifier("continueOwnedSale")
                        }
                    }
                    if let job = store.snapshot.inspectionJobs.first(where: { $0.itemID == item.id && $0.status == .pending }) {
                        DeadlineView(store: store, target: job.completesAt, titleKey: "inspection.pendingReport")
                    } else if !item.professionallyInspected {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("inspection.professional").font(.headline)
                            Text("inspection.professionalDescription").font(.subheadline).foregroundStyle(.secondary)
                            Text(InspectionEngine().professionalCost.formatted(locale: locale, market: market)).bold()
                            Button("inspection.professionalStart") { store.perform { try store.inspect(itemID: item.id, professionally: true) } }
                                .buttonStyle(.bordered).accessibilityIdentifier("professionalInspect")
                        }.gameCard()
                    }
                    NavigationLink("facts.title") { ItemFactsView(store: store, itemID: item.id) }.accessibilityIdentifier("openItemFacts")
                    DisclosureGroup("reveal.details") {
                        VStack(alignment: .leading, spacing: 12) {
                            LabeledContent("purchase.cost") { Text(item.purchasePrice.formatted(locale: locale, market: market)) }
                            KnowledgeSummary(knowledge: store.snapshot.inspectionKnowledge, category: definition.category)
                            Text("knowledge.inspectionLimit").font(.caption).foregroundStyle(.secondary)
                            NavigationLink("knowledge.open") { KnowledgeView(store: store) }
                        }.padding(.top, 10)
                    }.gameCard()
                }.padding(16)
            }.gameScreen().navigationTitle("inventory.title").navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct InspectionReveal: View {
    let store: GameStore
    let item: ItemInstance
    let definition: ItemDefinition
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market
    @GameReduceMotion private var reduceMotion
    @State private var step = 0
    @State private var sellerPhoto = false
    private var presentation: InspectionReportPresentation {
        InspectionReportPresentation(item: item, simulationID: store.snapshot.simulationID)
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                GameEyebrow(key: "reveal.heading")
                Spacer()
                Group {
                    if step < 3 { GameScanner(size: 44) }
                    else {
                        Image(systemName: item.knownActiveDefects.isEmpty ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                            .font(.title2).foregroundStyle(item.knownActiveDefects.isEmpty ? GameStyle.gain : GameStyle.loss)
                            .frame(width: 44, height: 44)
                    }
                }.accessibilityHidden(true)
            }
            HStack(alignment: .top, spacing: 8) {
                ForEach(0..<3) { index in
                    VStack(alignment: .leading, spacing: 6) {
                        Capsule().fill(step > index ? GameStyle.gain : Color.secondary.opacity(0.15)).frame(height: 4)
                        Text(GameText.string(["game.step.condition", "game.step.findings", "game.step.value"][index], locale: locale))
                            .font(.caption2.bold()).foregroundStyle(step > index ? .primary : .secondary)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
            }.accessibilityElement(children: .ignore).accessibilityLabel(Text("game.diagnostic"))
                .accessibilityValue(Text(min(step, 3), format: .number))
            Group {
                LabeledContent("inspection.condition") { Text(item.condition, format: .number).font(.system(.largeTitle, design: .rounded, weight: .heavy)).accessibilityIdentifier("inspectionCondition") }
                Text("reveal.condition").font(.subheadline).foregroundStyle(.secondary)
            }.opacity(step >= 1 ? 1 : 0).accessibilityHidden(step < 1)
            Group {
                if let listing = store.snapshot.market.first(where: { $0.item.id == item.id }) {
                    Picker("art.compare", selection: $sellerPhoto) {
                        Text("art.sellerPresentation").tag(true)
                        Text("art.inspected").tag(false)
                    }.pickerStyle(.segmented).accessibilityIdentifier("inspectionPhotoComparison")
                    DeviceArt(symbol: definition.artSymbol, identity: definition.id, appearance: sellerPhoto ? .advertised(listing) : .owned(item))
                        .aspectRatio(1, contentMode: .fit)
                        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: sellerPhoto)
                } else {
                    DeviceArt(symbol: definition.artSymbol, identity: definition.id, appearance: .owned(item)).aspectRatio(1, contentMode: .fit)
                }
                Text("art.inspected").font(.caption).foregroundStyle(.secondary)
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
                switch Result(catching: { try ValueEstimate(item: item, definition: definition, knowledge: store.snapshot.inspectionKnowledge, marketBasisPoints: store.snapshot.marketMultiplier(for: definition)) }) {
                case .success(let estimate): ValueRangeView(estimate: estimate)
                case .failure: Text("inspection.valueUnavailable")
                }
                Text("inspection.estimateWarning").font(.caption).foregroundStyle(.secondary)
            }.opacity(step >= 3 ? 1 : 0).accessibilityHidden(step < 3)
            Button("reveal.continue") { step = 3; presentation.markRead(in: .standard) }.font(.subheadline.bold()).accessibilityIdentifier("skipReveal")
                .opacity(step < 3 ? 1 : 0).allowsHitTesting(step < 3).accessibilityHidden(step >= 3)
        }.gameCard(accent: step >= 2 ? (item.knownActiveDefects.isEmpty ? GameStyle.gain : GameStyle.loss) : nil)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.25), value: step)
        .task(id: presentation.taskID) {
            let report = presentation
            let unread = report.needsReveal(in: .standard)
            guard unread && !reduceMotion && !UIAccessibility.isVoiceOverRunning else {
                var transaction = Transaction(animation: nil)
                transaction.disablesAnimations = true
                withTransaction(transaction) { step = 3 }
                report.markRead(in: .standard)
                return
            }
            step = 1; GameFeel.play(.reveal)
            for next in 2...3 {
                do { try await Task.sleep(for: .milliseconds(650)) } catch { return }
                if step < next { step = next; if next == 2 && !item.knownActiveDefects.isEmpty { GameFeel.play(.defect) } }
            }
            guard !Task.isCancelled else { return }
            report.markRead(in: .standard)
        }
    }
}

struct RepairDecision: View {
    let store: GameStore
    let item: ItemInstance
    let definition: ItemDefinition
    let defect: Defect
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market
    private var awaitingInspection: Bool {
        store.snapshot.inspectionJobs.contains { $0.itemID == item.id && $0.status == .pending }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                GameStamp(key: "repair.title", symbol: "wrench.and.screwdriver.fill")
                Spacer()
            }
            Text(GameText.string(defect.key, locale: locale)).font(.title3.bold())
            Text("game.repairChoice").font(.subheadline).foregroundStyle(.secondary)
            switch Result(catching: { try RepairQuote(item: item, definition: definition, defect: defect, marketBasisPoints: store.snapshot.marketMultiplier(for: definition)) }) {
            case .success(let quote):
                LabeledContent("repair.cost") { Text(quote.cost.formatted(locale: locale, market: market)).bold().foregroundStyle(.primary) }
                LabeledContent("repair.recovery") { Text(quote.estimatedRecovery.formatted(locale: locale, market: market, signed: true)).foregroundStyle(.primary) }
                if let difference = try? quote.estimatedRecovery.subtracting(quote.cost) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("repair.marginEstimate").font(.subheadline.weight(.semibold))
                        Text(difference.formatted(locale: locale, market: market, signed: true))
                            .font(.system(.largeTitle, design: .rounded, weight: .heavy)).monospacedDigit()
                            .foregroundStyle(difference < .zero ? GameStyle.loss : GameStyle.gain)
                            .accessibilityIdentifier("repairMargin.\(defect.rawValue)")
                        Text(difference > .zero ? "repair.marginPositive" : difference < .zero ? "repair.marginNegative" : "repair.marginEven")
                            .font(.caption).foregroundStyle(.secondary)
                    }.frame(maxWidth: .infinity, alignment: .leading).padding(12)
                        .background(.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
                }
                Text("repair.immediate").font(.caption).foregroundStyle(.secondary)
                Button("repair.action") { store.perform { try store.repair(itemID: item.id, defect: defect); GameFeel.play(.accepted) } }
                    .buttonStyle(GameButton()).accessibilityIdentifier("repair.\(defect.rawValue)")
                    .disabled(awaitingInspection || store.snapshot.player.cash < quote.cost)
                if awaitingInspection {
                    Label("repair.awaitInspection", systemImage: "hourglass").font(.caption).foregroundStyle(.secondary)
                } else if store.snapshot.player.cash < quote.cost {
                    Label("error.insufficientCash", systemImage: "wallet.bifold").font(.caption).foregroundStyle(.secondary)
                }
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
