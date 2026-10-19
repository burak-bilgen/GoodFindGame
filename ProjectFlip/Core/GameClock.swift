import Foundation

struct ClockReading: Equatable {
    let observedNow: Date
    let effectiveNow: Date
    let elapsed: TimeInterval
    let movedBackwards: Bool
    let largeForwardJump: Bool
}

enum GameClock {
    static func read(now: Date, lastKnownWallClock: Date?, lastSimulationAt: Date?) throws -> ClockReading {
        guard now.timeIntervalSinceReferenceDate.isFinite else { throw EventQueueError.invalidTimestamp }
        let previousWallClock = lastKnownWallClock ?? lastSimulationAt ?? now
        let simulationAnchor = lastSimulationAt ?? previousWallClock
        let delta = now.timeIntervalSince(previousWallClock)
        guard delta.isFinite else { throw EventQueueError.invalidTimestamp }
        let elapsed = max(0, delta)
        let effectiveNow = simulationAnchor.addingTimeInterval(elapsed)
        guard effectiveNow.timeIntervalSinceReferenceDate.isFinite else { throw EventQueueError.invalidTimestamp }
        // The raw anchor is updated even after a rollback. Subsequent real seconds still advance
        // simulation time, rather than freezing all work until the device catches its old date.
        return ClockReading(observedNow: now, effectiveNow: effectiveNow, elapsed: elapsed,
                            movedBackwards: delta < -60, largeForwardJump: delta > 7 * 86_400)
    }
}

struct SimulationTiming: Sendable {
    let sellerReply: ClosedRange<TimeInterval>
    let shipping: TimeInterval
    let inspection: TimeInterval
    let buyerInterest: ClosedRange<TimeInterval>
    let offerLifetime: TimeInterval
    let buyerArrivalsPerCatchUp: Int

    static let production = Self(sellerReply: 120...600, shipping: 300, inspection: 900, buyerInterest: 180...420, offerLifetime: 1_080, buyerArrivalsPerCatchUp: 12)
    static let debug = Self(sellerReply: 2...4, shipping: 4, inspection: 6, buyerInterest: 3...5, offerLifetime: 120, buyerArrivalsPerCatchUp: 12)
    static let instant = Self(sellerReply: 0...0, shipping: 0, inspection: 0, buyerInterest: 0...0, offerLifetime: 1_080, buyerArrivalsPerCatchUp: 12)
    static var current: Self {
        #if DEBUG
        debug
        #else
        production
        #endif
    }

    func delay(in range: ClosedRange<TimeInterval>, seed: UInt64) -> TimeInterval {
        var random = SeededRandom(seed: seed)
        return range.lowerBound + (range.upperBound - range.lowerBound) * Double(random.integer(in: 0...10_000)) / 10_000
    }
}

extension SimulationTiming {
    /// Let the player finish the first loop before asking for multi-minute return sessions.
    var firstTrade: Self {
        Self(sellerReply: min(3, sellerReply.lowerBound)...min(3, sellerReply.upperBound),
             shipping: min(5, shipping), inspection: min(8, inspection),
             buyerInterest: min(3, buyerInterest.lowerBound)...min(3, buyerInterest.upperBound),
             offerLifetime: offerLifetime, buyerArrivalsPerCatchUp: buyerArrivalsPerCatchUp)
    }
}
