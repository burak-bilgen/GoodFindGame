import SwiftUI
import GameKit
import Observation
import OSLog
import Network

/// Brand-neutral, versioned identifiers. Display branding remains Project Flip.
enum CompetitionIDs {
    static let weekly = "trading.weekly.v1"
    static func achievement(_ value: TradingAchievement) -> String { "trading.achievement.\(value.rawValue).v1" }
}

struct CompetitionRanks: Equatable {
    var global: Int?
    var friends: Int?
}

@MainActor protocol CompetitionService: AnyObject {
    var playerID: String? { get }
    func submit(score: Int64, period: WeeklyPeriod) async throws
    func report(achievements: [String: Double]) async throws
    func loadAchievements() async throws -> [String: Double]
    func ranks(period: WeeklyPeriod) async throws -> CompetitionRanks
}

enum CompetitionServiceError: Error { case unavailable, wrongOccurrence, accountChanged }

/// No authentication on launch. Only a deliberate Competition button installs the handler.
@Observable @MainActor
final class GameCenterService: CompetitionService {
    static let shared = GameCenterService()
    var playerID: String?
    var statusKey = "competition.offline"
    var presentation: GameCenterPresentation?
    var networkGeneration = 0
    private let networkMonitor = NWPathMonitor()
    private var installedHandler = false
    private var requestedUI = false
    private var pendingAuthentication: UIViewController?
    private let logger = Logger(subsystem: "ProjectFlip", category: "GameCenter")

    private init() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            guard path.status == .satisfied else { return }
            Task { @MainActor in self?.networkGeneration &+= 1 }
        }
        networkMonitor.start(queue: DispatchQueue(label: "ProjectFlip.competition.network"))
    }

    func authenticate() {
        requestedUI = true
        if let pendingAuthentication {
            presentation = GameCenterPresentation(controller: pendingAuthentication, isAuthentication: true)
            self.pendingAuthentication = nil
            return
        }
        guard !installedHandler else { return }
        installedHandler = true
        statusKey = "competition.connecting"
        GKLocalPlayer.local.authenticateHandler = { [weak self] controller, error in
            Task { @MainActor in
                guard let self else { return }
                if let controller {
                    if self.requestedUI && self.presentation == nil {
                        self.presentation = GameCenterPresentation(controller: controller, isAuthentication: true)
                        self.requestedUI = false
                    } else { self.pendingAuthentication = controller }
                } else {
                    if self.presentation?.isAuthentication == true { self.presentation = nil }
                    self.playerID = GKLocalPlayer.local.isAuthenticated ? GKLocalPlayer.local.gamePlayerID : nil
                    self.statusKey = self.playerID == nil ? "competition.signInSettings" : "competition.connected"
                    self.requestedUI = false
                    CompetitionAnalytics.record(self.playerID == nil ? .authFailure : .authSuccess)
                }
                if let error { self.debugFailure(error) }
            }
        }
    }

    private func leaderboard(_ period: WeeklyPeriod) async throws -> GKLeaderboard {
        guard playerID != nil, GKLocalPlayer.local.isAuthenticated else { throw CompetitionServiceError.unavailable }
        let boards = try await GKLeaderboard.loadLeaderboards(IDs: [CompetitionIDs.weekly])
        guard let board = boards.first, period.matches(start: board.startDate, duration: board.duration), period.contains(.now) else { throw CompetitionServiceError.wrongOccurrence }
        return board
    }
    func submit(score: Int64, period: WeeklyPeriod) async throws {
        guard (0...TraderScore.cap).contains(score), let account = playerID else { throw CompetitionServiceError.unavailable }
        let board = try await leaderboard(period)
        guard playerID == account, GKLocalPlayer.local.gamePlayerID == account else { throw CompetitionServiceError.accountChanged }
        try await board.submitScore(Int(score), context: TraderScore.version, player: GKLocalPlayer.local)
        CompetitionAnalytics.record(.scoreSubmitted)
        #if DEBUG
        logger.debug("Score v\(TraderScore.version) period=\(period.id, privacy: .public) score=\(score)")
        #endif
    }
    func report(achievements: [String: Double]) async throws {
        guard playerID != nil, GKLocalPlayer.local.isAuthenticated else { throw CompetitionServiceError.unavailable }
        let values = achievements.map { id, percent in
            let achievement = GKAchievement(identifier: id)
            achievement.percentComplete = min(100, max(0, percent)); achievement.showsCompletionBanner = false
            return achievement
        }
        if !values.isEmpty { try await GKAchievement.report(values) }
    }
    func loadAchievements() async throws -> [String: Double] {
        guard playerID != nil, GKLocalPlayer.local.isAuthenticated else { throw CompetitionServiceError.unavailable }
        let values = try await GKAchievement.loadAchievements()
        return Dictionary(values.map { ($0.identifier, $0.percentComplete) }, uniquingKeysWith: max)
    }
    func ranks(period: WeeklyPeriod) async throws -> CompetitionRanks {
        let board = try await leaderboard(period)
        let global = try await board.loadEntries(for: .global, timeScope: .allTime, range: NSRange(location: 1, length: 1))
        let friends = try await board.loadEntries(for: .friendsOnly, timeScope: .allTime, range: NSRange(location: 1, length: 1))
        return CompetitionRanks(global: global.0?.rank, friends: friends.0?.rank)
    }
    func showLeaderboard(friends: Bool = false) {
        guard playerID != nil else { return }
        let access = GKAccessPoint.shared
        guard !access.isPresentingGameCenter else { return }
        access.isActive = false
        access.trigger(leaderboardID: CompetitionIDs.weekly, playerScope: friends ? .friendsOnly : .global, timeScope: .allTime, handler: nil)
        CompetitionAnalytics.record(.leaderboardOpened)
    }
    func showAchievements() {
        guard playerID != nil else { return }
        let access = GKAccessPoint.shared
        guard !access.isPresentingGameCenter else { return }
        access.isActive = false
        access.trigger(state: .achievements, handler: {})
    }
    func debugFailure(_ error: any Error) {
        #if DEBUG
        logger.error("Game Center: \(String(describing: error), privacy: .public)")
        #endif
    }
}

struct GameCenterPresentation: Identifiable {
    let id = UUID()
    let controller: UIViewController
    var isAuthentication = false
}
struct GameCenterSheet: UIViewControllerRepresentable {
    let presentation: GameCenterPresentation
    func makeUIViewController(context: Context) -> UIViewController { presentation.controller }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

enum CompetitionAnalytics {
    enum Event: String { case authSuccess, authFailure, opened, started, completed, scoreSubmitted, leaderboardOpened, achievementEarned, deepLinkOpened }
    static func record(_ event: Event) {
        // Internal hook only: no identifiers, amounts, advertising IDs or network analytics.
        #if DEBUG
        Logger(subsystem: "ProjectFlip", category: "CompetitionAnalytics").debug("\(event.rawValue, privacy: .public)")
        #endif
    }
}
