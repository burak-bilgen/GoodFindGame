import Foundation
import Observation

struct WeeklyRun: Codable, Equatable, Identifiable {
    let period: WeeklyPeriod
    var id: String { period.id }
    var finalized = false
    var score: Int64 = 0
    var completedTrades = 0
    var submittedScore: Int64?
    var ownerID: String?
    var clockSuspect = false
    var lastSeen: Date
    var finisher: Bool { finalized && completedTrades > 0 }
}

struct CompetitionSave: Codable, Equatable {
    var version = 1
    var runs: [WeeklyRun] = []
    var achievements = AchievementJournal()
    func validate() throws {
        guard version == 1, runs.count <= 100_000, Set(runs.map(\.id)).count == runs.count else { throw SaveError.invalidSave }
        for run in runs {
            try run.period.validate()
            guard (0...TraderScore.cap).contains(run.score), (0...10_000).contains(run.completedTrades),
                  run.submittedScore.map({ (0...TraderScore.cap).contains($0) && $0 <= run.score }) ?? true,
                  run.lastSeen.timeIntervalSinceReferenceDate.isFinite else { throw SaveError.invalidSave }
        }
        try achievements.validate()
    }
}

/// Separate files, separate state; only immutable career facts are read for achievements.
@Observable @MainActor
final class CompetitionStore {
    private(set) var saved: CompetitionSave
    private(set) var weeklyStore: GameStore?
    var errorKey: String?
    var syncKey = "competition.saved"
    var ranks = CompetitionRanks()
    var ranksUnavailable = false
    private let root: URL
    private let definitions: [ItemDefinition]
    private var syncing = false
    private var rankPlayerID: String?
    private var observedCareer: GameSnapshot?

    init(root: URL, definitions: [ItemDefinition]) throws {
        self.root = root; self.definitions = definitions
        let url = root.appendingPathComponent("competition.json")
        if FileManager.default.fileExists(atPath: url.path) {
            saved = try JSONDecoder().decode(CompetitionSave.self, from: Data(contentsOf: url))
            try saved.validate()
        } else { saved = CompetitionSave() }
    }
    func run(for period: WeeklyPeriod) -> WeeklyRun? { saved.runs.first { $0.period == period } }
    func repository(for period: WeeklyPeriod) -> SaveRepository {
        SaveRepository(url: root.appendingPathComponent("\(period.id).json"))
    }
    private func persist(_ next: CompetitionSave) throws {
        try next.validate()
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try JSONEncoder().encode(next).write(to: root.appendingPathComponent("competition.json"), options: .atomic)
        saved = next
    }
    func perform(_ action: () throws -> Void) {
        do { try action(); errorKey = nil }
        catch { errorKey = "competition.error"; GameCenterService.shared.debugFailure(error) }
    }
    func observeCareer(_ career: GameSnapshot) {
        guard observedCareer != career else { return }
        // Do not cache failed writes: a later foreground refresh retries the same facts.
        perform {
            var next = saved
            next.achievements.merge(try AchievementEngine.progress(career))
            if next != saved { try persist(next) }
            observedCareer = career
        }
    }
    func start(now: Date = .now, playerID: String? = nil, currency: GameCurrency = .usd) throws {
        try refresh(now: now)
        let period = WeeklyPeriod.containing(now)
        try period.validate()
        if run(for: period) != nil {
            try open(period, now: now)
            try setDisplayCurrency(currency)
            return
        }
        let repository = repository(for: period)
        // An interrupted metadata write may leave a valid challenge file; never reroll it.
        if !FileManager.default.fileExists(atPath: repository.url.path) {
            var state = try GameSnapshot.fresh(definitions: definitions, seed: period.seed, now: now, marketConfiguration: .us)
            state.player.cash = TraderScore.bankroll
            state.marketConfiguration.currency = currency
            state.simulationID = period.id
            try repository.save(state)
        }
        var next = saved
        next.runs.append(WeeklyRun(period: period, ownerID: playerID, lastSeen: now))
        try persist(next)
        try open(period, now: now)
        CompetitionAnalytics.record(.started)
    }
    private func setDisplayCurrency(_ currency: GameCurrency) throws {
        guard let store = weeklyStore, store.snapshot.marketConfiguration.currency != currency else { return }
        var state = store.snapshot; state.marketConfiguration.currency = currency; try store.commit(state)
    }
    private func open(_ period: WeeklyPeriod, now: Date) throws {
        guard let run = run(for: period), !run.finalized, period.contains(now) else { weeklyStore = nil; return }
        if weeklyStore?.competitionPeriod == period { return }
        let store = try GameStore(repository: repository(for: period), definitions: definitions, timing: .production, now: now, competitionPeriod: period)
        store.competitionCanCommit = { [weak self] in self?.run(for: period)?.finalized == false }
        store.onSnapshotCommitted = { [weak self] _ in
            self?.perform { try self?.checkpoint(period: period) }
        }
        weeklyStore = store
        try checkpoint(period: period)
    }
    func checkpoint(period: WeeklyPeriod, now: Date = .now) throws {
        guard let index = saved.runs.firstIndex(where: { $0.period == period && !$0.finalized }), let store = weeklyStore, store.competitionPeriod == period else { return }
        var next = saved
        let score = try TraderScore.calculate(store.snapshot, period: period)
        next.runs[index].score = score
        next.runs[index].completedTrades = try TradeLedger.records(from: store.snapshot).count
        if now < next.runs[index].lastSeen.addingTimeInterval(-60) { next.runs[index].clockSuspect = true }
        next.runs[index].lastSeen = max(next.runs[index].lastSeen, now)
        if next != saved { try persist(next) }
    }
    func finalize(period: WeeklyPeriod, now: Date = .now) throws {
        guard let index = saved.runs.firstIndex(where: { $0.period == period }), !saved.runs[index].finalized else { return }
        // At rollover, read the old snapshot without advancing the economy past the deadline.
        // All settlements are explicit accept actions; pending/unsold goods score zero.
        guard let snapshot = try repository(for: period).load() else { throw SaveError.invalidSave }
        let score = try TraderScore.calculate(snapshot, period: period)
        var next = saved
        next.runs[index].score = score
        next.runs[index].completedTrades = try TradeLedger.records(from: snapshot).count
        next.runs[index].finalized = true
        next.runs[index].lastSeen = max(now, next.runs[index].lastSeen)
        if next.runs[index].finisher { next.achievements.merge([.weeklyFinisher: 100]) }
        try persist(next)
        if weeklyStore?.competitionPeriod == period { weeklyStore = nil }
        CompetitionAnalytics.record(.completed)
    }
    func refresh(now: Date = .now) throws {
        for run in saved.runs where !run.finalized && now >= run.period.end { try finalize(period: run.period, now: now) }
        let period = WeeklyPeriod.containing(now)
        if let run = run(for: period), !run.finalized { try open(period, now: now) }
    }
    /// Meaningful checkpoints are the sale count and explicit finalization, never every timer tick.
    func sync(using service: any CompetitionService, now: Date = .now) async {
        if rankPlayerID != service.playerID {
            ranks = CompetitionRanks(); ranksUnavailable = false; rankPlayerID = service.playerID
        }
        guard !syncing, let player = service.playerID else { syncKey = "competition.offline"; return }
        syncing = true
        defer { syncing = false }
        do {
            try refresh(now: now)
            var remote = try await service.loadAchievements()
            guard service.playerID == player else { throw CompetitionServiceError.accountChanged }
            let allowed = Set(TradingAchievement.allCases.map(CompetitionIDs.achievement))
            remote = remote.filter { allowed.contains($0.key) && $0.value.isFinite && (0...100).contains($0.value) }
            var next = saved
            // Remote completion is merged monotonically into the local journal.
            for (id, percent) in remote { next.achievements.progress[id] = max(next.achievements.progress[id, default: 0], percent) }
            next.achievements.acknowledge(remote, player: player)
            try persist(next)
            let pending = saved.achievements.pending(for: player)
            try await service.report(achievements: pending)
            guard service.playerID == player else { throw CompetitionServiceError.accountChanged }
            next = saved; next.achievements.acknowledge(pending, player: player); try persist(next)
            let period = WeeklyPeriod.containing(now)
            if let index = saved.runs.firstIndex(where: { $0.period == period }), saved.runs[index].completedTrades > 0 && saved.runs[index].finalized {
                let run = saved.runs[index]
                guard !run.clockSuspect else { syncKey = "competition.clock"; return }
                guard run.ownerID == nil || run.ownerID == player else { syncKey = "competition.accountMismatch"; return }
                // Persist account ownership before the network side effect.
                next = saved; next.runs[index].ownerID = player; try persist(next)
                if run.submittedScore == nil || run.score > (run.submittedScore ?? 0) {
                    // A score is derived from the durable snapshot again at the submission boundary.
                    guard let state = try repository(for: period).load(), try TraderScore.calculate(state, period: period) == run.score else { throw SaveError.invalidSave }
                    try await service.submit(score: run.score, period: period)
                    guard service.playerID == player else { throw CompetitionServiceError.accountChanged }
                    next = saved
                    next.runs[index].submittedScore = run.score
                    try persist(next)
                }
                syncKey = "competition.synced"
            } else { syncKey = "competition.saved" }
            do {
                let loaded = try await service.ranks(period: period)
                guard service.playerID == player else { throw CompetitionServiceError.accountChanged }
                ranks = loaded; ranksUnavailable = false
            } catch { ranks = CompetitionRanks(); ranksUnavailable = true }
        } catch {
            syncKey = "competition.pending"
            GameCenterService.shared.debugFailure(error)
        }
    }
}
