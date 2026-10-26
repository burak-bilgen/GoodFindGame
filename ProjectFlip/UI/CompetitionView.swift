import SwiftUI

struct CompetitionView: View {
    let career: GameStore
    let competition: CompetitionStore
    @State private var service = GameCenterService.shared
    @State private var showTrading = false
    @State private var confirmFinish = false
    @State private var now = Date.now
    @Environment(\.locale) private var locale
    @Environment(\.scenePhase) private var scenePhase

    private var period: WeeklyPeriod { .containing(now) }
    private var run: WeeklyRun? { competition.run(for: period) }
    private var eligible: Bool {
        ((try? TradeLedger.records(from: career.snapshot).filter { $0.kind == .market || $0.kind == .client }.count) ?? 0) >= 3
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                GameStageBanner(titleKey: "competition.weekly", eyebrowKey: "competition.challengeContext", symbol: "trophy.fill", color: GameStyle.amber)
                VStack(alignment: .leading, spacing: 12) {
                    Text("competition.score").font(.headline)
                    Text((run?.score ?? Int64(0)).formatted(.number.locale(locale))).font(.system(.largeTitle, design: .default, weight: .bold))
                        .foregroundStyle(GameStyle.amber).accessibilityIdentifier("weeklyScore")
                    LabeledContent("competition.timeLeft") {
                        Text(Duration.seconds(max(0, period.end.timeIntervalSince(now))), format: .units(allowed: [.days, .hours, .minutes], width: .abbreviated))
                            .monospacedDigit()
                    }
                    if let run {
                        LabeledContent("competition.trades") { Text(run.completedTrades, format: .number) }
                        if run.finalized { Label("competition.finalized", systemImage: "checkmark.seal.fill") }
                        if run.finisher { Label("competition.finisher", systemImage: "medal.fill").foregroundStyle(GameStyle.amber) }
                    }
                    if let store = competition.weeklyStore {
                        LabeledContent("competition.bankroll") { Text(store.snapshot.player.cash.formatted(locale: locale, market: career.snapshot.marketConfiguration)) }
                        if let trades = try? TradeLedger.records(from: store.snapshot), let profit = try? TradeLedger.totalProfit(trades) {
                            LabeledContent("competition.profit") { Text(profit.formatted(locale: locale, market: career.snapshot.marketConfiguration, signed: true)) }
                        }
                    }
                }.gameCard(accent: GameStyle.amber)
                Text("competition.fairness").font(.subheadline).fixedSize(horizontal: false, vertical: true)
                if run?.finalized != true {
                    if eligible || run != nil {
                        Button(run == nil ? "competition.start" : "competition.resume") {
                            competition.perform { try competition.start(playerID: service.playerID, currency: career.snapshot.marketConfiguration.currency) }
                            showTrading = competition.weeklyStore != nil
                        }.buttonStyle(GameButton()).accessibilityIdentifier("startWeekly")
                    } else { Text("competition.introLocked").font(.subheadline).foregroundStyle(GameStyle.secondaryText) }
                }
                if run != nil && run?.finalized == false {
                    Button("competition.finish") { confirmFinish = true }.buttonStyle(GameButton(secondary: true)).accessibilityIdentifier("finalizeWeekly")
                    Text("competition.finishHint").font(.caption).foregroundStyle(GameStyle.secondaryText)
                }
                if service.onlineEnabled {
                VStack(alignment: .leading, spacing: 12) {
                    Label(GameText.string(service.statusKey, locale: locale), systemImage: service.playerID == nil ? "network.slash" : "person.crop.circle.badge.checkmark")
                        .font(.subheadline)
                    if service.playerID == nil {
                        Button("competition.connect") { service.authenticate() }.buttonStyle(GameButton(secondary: true)).accessibilityIdentifier("connectGameCenter")
                    } else {
                        rankRow("competition.globalRank", rank: competition.ranks.global)
                        rankRow("competition.friendsRank", rank: competition.ranks.friends)
                        if competition.ranksUnavailable { Text("competition.ranksUnavailable").font(.caption) }
                        Button("competition.global") { service.showLeaderboard() }.buttonStyle(GameButton(secondary: true))
                        Button("competition.friends") { service.showLeaderboard(friends: true) }.buttonStyle(GameButton(secondary: true))
                        Button("competition.submit") { Task { await competition.sync(using: service) } }.buttonStyle(GameButton(secondary: true)).accessibilityIdentifier("syncCompetition")
                    }
                    Text(GameText.string(run?.clockSuspect == true ? "competition.clock" : competition.syncKey, locale: locale)).font(.caption).foregroundStyle(GameStyle.secondaryText)
                }.gameCard()
                } else {
                    Text("competition.localOnly").font(.caption).foregroundStyle(GameStyle.secondaryText).gameCard().accessibilityIdentifier("localCompetition")
                }
                if let error = competition.errorKey { Text(GameText.string(error, locale: locale)).foregroundStyle(GameStyle.loss).accessibilityIdentifier("competitionError") }
                achievementPanel
                let previous = competition.saved.runs.filter { $0.period.index < period.index }.sorted { $0.period.index > $1.period.index }
                if !previous.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("competition.previous").font(.headline)
                        ForEach(previous.prefix(8)) { result in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(result.period.start, format: .dateTime.day().month().year().locale(locale))
                                Text(result.score, format: .number).font(.title2.bold())
                                if result.finisher { Label("competition.finisher", systemImage: "medal.fill") }
                                Text("competition.expired").font(.caption).foregroundStyle(GameStyle.secondaryText)
                            }.accessibilityElement(children: .combine)
                        }
                    }.gameCard(accent: GameStyle.amber)
                }
                DisclosureGroup("competition.score") { Text("competition.scoreRules").font(.subheadline).padding(.top, 8) }.gameCard()
                Text("competition.prestige").font(.caption).foregroundStyle(GameStyle.secondaryText)
                Text("competition.integrity").font(.caption).foregroundStyle(GameStyle.secondaryText)
            }.padding(16)
        }.gameScreen().navigationTitle("competition.title").navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("competition.confirmFinish", isPresented: $confirmFinish, titleVisibility: .visible) {
                Button("competition.finish") {
                    competition.perform { try competition.finalize(period: period) }
                    Task { await competition.sync(using: service) }
                }.accessibilityIdentifier("confirmFinalizeWeekly")
                Button("competition.cancel", role: .cancel) {}
            } message: { Text("competition.finishHint") }
            .sheet(item: $service.presentation) { GameCenterSheet(presentation: $0) }
            .fullScreenCover(isPresented: $showTrading, onDismiss: { Task { await competition.sync(using: service) } }) {
                if let store = competition.weeklyStore { WeeklyTradingView(store: store, competition: competition) }
            }
            .task {
                CompetitionAnalytics.record(.opened)
                competition.observeCareer(career.snapshot)
                competition.perform { try competition.refresh() }
                await competition.sync(using: service)
            }
            .task(id: scenePhase) {
                guard scenePhase == .active else { return }
                while !Task.isCancelled {
                    now = .now
                    competition.perform { try competition.refresh(now: now) }
                    do { try await Task.sleep(for: .seconds(30)) } catch { return }
                }
            }
            .onChange(of: service.playerID) { _, _ in Task { await competition.sync(using: service) } }
    }
    private func rankRow(_ key: String, rank: Int?) -> some View {
        LabeledContent(GameText.string(key, locale: locale)) {
            if let rank { Text(rank, format: .number).bold() } else { Text("competition.unranked").foregroundStyle(GameStyle.secondaryText) }
        }
    }
    private var achievementPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("competition.achievements").font(.title2.bold())
            ForEach(TradingAchievement.available, id: \.rawValue) { achievement in
                let percent = competition.saved.achievements.progress[CompetitionIDs.achievement(achievement), default: 0]
                VStack(alignment: .leading, spacing: 8) {
                    Label(GameText.string(achievement.titleKey, locale: locale), systemImage: percent >= 100 ? "checkmark.seal.fill" : "seal")
                        .font(.headline).foregroundStyle(percent >= 100 ? GameStyle.amber : .primary)
                    Text(GameText.string(achievement.detailKey, locale: locale)).font(.caption).foregroundStyle(GameStyle.secondaryText)
                    ProgressView(value: percent, total: 100).tint(GameStyle.amber)
                        .accessibilityLabel(Text(GameText.string(achievement.titleKey, locale: locale)))
                        .accessibilityValue(Text(percent / 100, format: .percent.precision(.fractionLength(0))))
                }.accessibilityElement(children: .combine)
            }
            if service.playerID != nil { Button("competition.achievements") { service.showAchievements() }.buttonStyle(GameButton(secondary: true)) }
        }.gameCard()
    }
}

/// The same screens and engines operate on a different store. The career is never passed here.
struct WeeklyTradingView: View {
    let store: GameStore
    let competition: CompetitionStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.locale) private var locale
    @State private var section = 0
    @State private var navigationID = UUID()
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Label("competition.challengeContext", systemImage: "trophy.fill").font(.caption.bold()).foregroundStyle(GameStyle.amber).padding(12)
                if typeSize.isAccessibilitySize {
                    HStack {
                        sectionButton("competition.market", section: 0, symbol: "magnifyingglass")
                        sectionButton("competition.inventory", section: 1, symbol: "shippingbox")
                        sectionButton("competition.selling", section: 2, symbol: "tag")
                    }.padding(.horizontal, 12)
                } else {
                    Picker("competition.weekly", selection: $section) {
                        Text("competition.market").tag(0)
                        Text("competition.inventory").tag(1)
                        Text("competition.selling").tag(2)
                    }.pickerStyle(.segmented).padding(.horizontal, 12).padding(.bottom, 8)
                }
                Group {
                    switch section {
                    case 1: InventoryView(store: store)
                    case 2: SellingView(store: store)
                    default: MarketView(store: store)
                    }
                }.id(navigationID)
            }.gameScreen()
                .toolbar { ToolbarItem(placement: .topBarLeading) { Button("competition.back") { dismiss() }.accessibilityIdentifier("leaveWeekly") } }
        }
        .environment(\.marketConfiguration, store.snapshot.marketConfiguration)
        .environment(\.returnToHunt, { navigationID = UUID(); section = 0 })
        .alert("error.title", isPresented: Binding(get: { store.errorKey != nil }, set: { if !$0 { store.errorKey = nil } })) {
            Button("action.ok") { store.errorKey = nil }
        } message: { Text(GameText.string(store.errorKey ?? "save.error.write", locale: locale)) }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            while !Task.isCancelled {
                guard let period = store.competitionPeriod, period.contains(.now), competition.run(for: period)?.finalized == false else {
                    competition.perform { try competition.refresh() }; dismiss(); return
                }
                if store.errorKey == nil { store.perform { try store.processDueEvents() } }
                do { try await Task.sleep(for: .seconds(1)) } catch { return }
            }
        }
        .onChange(of: store.snapshot.playerListings.filter { $0.status == .sold }.count) { _, _ in Task { await competition.sync(using: GameCenterService.shared) } }
    }
    private func sectionButton(_ key: String, section value: Int, symbol: String) -> some View {
        Button { section = value } label: {
            Image(systemName: symbol).frame(maxWidth: .infinity, minHeight: 44)
        }.buttonStyle(.bordered).tint(section == value ? GameStyle.amber : GameStyle.gain)
            .accessibilityLabel(Text(GameText.string(key, locale: locale)))
            .accessibilityAddTraits(section == value ? .isSelected : [])
    }

}
