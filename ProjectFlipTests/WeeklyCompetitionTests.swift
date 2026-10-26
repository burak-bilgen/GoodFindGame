import Foundation
import Testing
@testable import ProjectFlip

@MainActor struct WeeklyCompetitionTests {
    static func soldState(now: Date, definitions: [ItemDefinition]) throws -> GameSnapshot {
        var state = try GameSnapshot.fresh(definitions: definitions, seed: WeeklyPeriod.containing(now).seed, now: now)
        state.simulationID = WeeklyPeriod.containing(now).id
        let listing = state.market[0]
        var agreement = NegotiationState(listingID: listing.id, patience: 100)
        agreement.agreedPrice = listing.askingPrice
        state.conversations = [agreement]
        state = try PurchaseEngine().buy(listingID: listing.id, state: state, now: now)
        state = try InspectionEngine().inspect(itemID: listing.item.id, professionally: false, state: state)
        state = try ResaleEngine().create(itemID: listing.item.id, askingPrice: listing.askingPrice, state: state, definitions: definitions, now: now)
        state = try BuyerEngine().generateOffer(listingID: state.playerListings[0].id, state: state, definitions: definitions)
        return try BuyerEngine().accept(listingID: state.playerListings[0].id, state: state, now: now)
    }
    @Test func separateFilesPreserveCareerAndStandardizeChallenge() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let definitions = try SeedContent.load().items
        let careerRepository = SaveRepository(url: root.appendingPathComponent("career.json"))
        var career = try GameSnapshot.fresh(definitions: definitions, marketConfiguration: .turkey)
        career.player.cash = Money(minorUnits: 9_000_000)
        try careerRepository.save(career)
        let before = try Data(contentsOf: careerRepository.url)
        let competition = try CompetitionStore(root: root.appendingPathComponent("weekly"), definitions: definitions)
        try competition.start()
        let weekly = try #require(competition.weeklyStore)
        #expect(weekly.snapshot.player.cash == TraderScore.bankroll)
        #expect(weekly.snapshot.marketConfiguration == .us)
        #expect(weekly.snapshot.player.inventory.isEmpty)
        #expect(weekly.snapshot.inspectionKnowledge == InspectionKnowledge())
        #expect(weekly.snapshot.career == CareerRecord())
        #expect(try Data(contentsOf: careerRepository.url) == before)
        let reloaded = try CompetitionStore(root: root.appendingPathComponent("weekly"), definitions: definitions)
        try reloaded.start()
        #expect(reloaded.weeklyStore?.snapshot.market == weekly.snapshot.market)
        #expect(reloaded.saved.runs.count == 1)
        var tampered = weekly.snapshot; tampered.player.cash = Money(minorUnits: 100_001)
        #expect(throws: SaveError.self) { try TraderScore.calculate(tampered, period: .containing(.now)) }
        #expect(throws: TradingError.self) { try weekly.beginRecovery() }
    }
    @Test func finalizeFreezesRunAndRolloverPreservesBadgeAndNoOldSubmission() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let definitions = try SeedContent.load().items
        let now = Date.now, period = WeeklyPeriod.containing(now)
        let competition = try CompetitionStore(root: root, definitions: definitions)
        try competition.start(now: now)
        let store = try #require(competition.weeklyStore)
        try store.commit(Self.soldState(now: now, definitions: definitions))
        let recorded = try #require(competition.run(for: period))
        #expect(recorded.completedTrades == 1)
        let service = FakeCompetitionService()
        await competition.sync(using: service, now: now)
        #expect(service.scores.isEmpty) // Only immutable final results are submitted.
        try competition.finalize(period: period, now: now)
        #expect(competition.run(for: period)?.finisher == true)
        #expect(competition.saved.achievements.progress[CompetitionIDs.achievement(.weeklyFinisher)] == 100)
        #expect(throws: TradingError.self) { try store.commit(store.snapshot) }
        let final = competition.saved
        try competition.finalize(period: period, now: now)
        #expect(competition.saved == final)
        service.fail = true
        await competition.sync(using: service, now: now)
        #expect(competition.run(for: period)?.submittedScore == nil)
        #expect(competition.run(for: period)?.score == recorded.score)
        service.fail = false
        await competition.sync(using: service, now: now)
        #expect(service.scores.count == 1)
        await competition.sync(using: service, now: now)
        #expect(service.scores.count == 1)
        let oldCount = service.scores.count
        await competition.sync(using: service, now: period.end.addingTimeInterval(1))
        #expect(service.scores.count == oldCount)
    }
    @Test func expiredRunArchivesAndNewWeekStartsWithNoCareerResources() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let definitions = try SeedContent.load().items
        let current = WeeklyPeriod.containing(.now), old = WeeklyPeriod(index: current.index - 1)
        let oldState = try Self.soldState(now: old.end.addingTimeInterval(-60), definitions: definitions)
        let repository = SaveRepository(url: root.appendingPathComponent("\(old.id).json"))
        try repository.save(oldState)
        let meta = CompetitionSave(runs: [WeeklyRun(period: old, lastSeen: old.end.addingTimeInterval(-60))])
        try JSONEncoder().encode(meta).write(to: root.appendingPathComponent("competition.json"))
        let competition = try CompetitionStore(root: root, definitions: definitions)
        try competition.start()
        #expect(competition.saved.runs.count == 2)
        #expect(competition.saved.runs[0].finisher)
        #expect(competition.saved.runs[0].completedTrades == 1)
        #expect(competition.weeklyStore?.snapshot.player.cash == TraderScore.bankroll)
        #expect(competition.weeklyStore?.snapshot.playerListings.isEmpty == true)
        #expect(try repository.load() == oldState)
    }
    @Test func offlineEarnedAchievementRetriesAcrossRelaunchAndAccounts() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let definitions = try SeedContent.load().items
        var state = try Self.soldState(now: .now, definitions: definitions)
        state.inspectionKnowledge.learn(16, in: .cameras)
        let competition = try CompetitionStore(root: root, definitions: definitions)
        competition.observeCareer(state)
        let id = CompetitionIDs.achievement(.specialist)
        #expect(competition.saved.achievements.progress[id] == 100)
        let service = FakeCompetitionService(); service.playerID = nil
        await competition.sync(using: service)
        #expect(competition.saved.achievements.progress[id] == 100)
        let reloaded = try CompetitionStore(root: root, definitions: definitions)
        service.playerID = "account-a"; service.failReport = true
        await reloaded.sync(using: service)
        #expect(reloaded.saved.achievements.pending(for: "account-a")[id] == 100)
        service.failReport = false
        await reloaded.sync(using: service)
        #expect(reloaded.saved.achievements.pending(for: "account-a").isEmpty)
        let count = service.reported.count
        await reloaded.sync(using: service)
        #expect(service.reported.count == count)
        service.playerID = "account-b"
        await reloaded.sync(using: service)
        #expect(reloaded.saved.achievements.acknowledged["account-b"]?[id] == 100)
        #expect(reloaded.saved.achievements.progress[id] == 100)
    }
    @Test func malformedStateCannotSubmitAndWrongAccountCannotClaimResult() async throws {
        let definitions = try SeedContent.load().items
        var state = try Self.soldState(now: .now, definitions: definitions)
        let period = WeeklyPeriod.containing(.now)
        #expect(try TraderScore.calculate(state, period: period) >= 0)
        state.playerListings[0].soldAt = period.end
        #expect(throws: SaveError.self) { try TraderScore.calculate(state, period: period) }
        state.playerListings[0].soldAt = .now
        state.playerListings[0].saleKind = .consignment
        #expect(throws: SaveError.self) { try TraderScore.calculate(state, period: period) }
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let competition = try CompetitionStore(root: root, definitions: definitions)
        try competition.start(playerID: "owner")
        try competition.weeklyStore?.commit(Self.soldState(now: .now, definitions: definitions))
        try competition.finalize(period: period)
        let service = FakeCompetitionService()
        await competition.sync(using: service)
        #expect(service.scores.isEmpty)
        #expect(competition.syncKey == "competition.accountMismatch")
    }
    @Test func earnedProgressIsMonotonicAndMetadataIsBilingual() throws {
        let definitions = try SeedContent.load().items
        var career = try Self.soldState(now: .now, definitions: definitions)
        career.inspectionKnowledge.learn(16, in: .cameras)
        var journal = AchievementJournal()
        journal.merge(try AchievementEngine.progress(career))
        #expect(journal.progress[CompetitionIDs.achievement(.specialist)] == 100)
        journal.merge([.specialist: 0])
        #expect(journal.progress[CompetitionIDs.achievement(.specialist)] == 100)
        for language in ["en", "tr"] {
            for achievement in TradingAchievement.allCases {
                #expect(GameText.string(achievement.titleKey, locale: Locale(identifier: language)) != "…")
                #expect(GameText.string(achievement.detailKey, locale: Locale(identifier: language)) != "…")
            }
            #expect(GameText.string("competition.title", locale: Locale(identifier: language)) != "…")
        }
        #expect(CompetitionRoute.activity(identifier: "trading.activity.weekly.v1") == .weekly)
        #expect(CompetitionRoute.activity(identifier: "unknown") == nil)
    }
}

@MainActor final class FakeCompetitionService: CompetitionService {
    var playerID: String? = "account-a"
    var fail = false
    var failReport = false
    var scores: [Int64] = []
    var reported: [[String: Double]] = []
    var remote: [String: Double] = [:]
    func submit(score: Int64, period: WeeklyPeriod) async throws {
        if fail { throw CompetitionServiceError.unavailable }; scores.append(score)
    }
    func report(achievements: [String: Double]) async throws {
        if fail || failReport { throw CompetitionServiceError.unavailable }
        if !achievements.isEmpty { reported.append(achievements) }
    }
    func loadAchievements() async throws -> [String: Double] {
        if fail { throw CompetitionServiceError.unavailable }; return remote
    }
    func ranks(period: WeeklyPeriod) async throws -> CompetitionRanks { CompetitionRanks(global: 42, friends: 3) }
}
