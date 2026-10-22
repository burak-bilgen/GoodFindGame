import Foundation

/// V1: fixed-bankroll profit + portfolio ROI + capped, varied quality trades.
/// Currency conversion, unsold estimates and recovery commissions never earn points.
enum TraderScore {
    static let version = 1
    static let cap: Int64 = 1_000_000
    static let bankroll = Money(minorUnits: 100_000)
    static let transactionLimit: Int64 = 1_000_000_000

    struct Input: Equatable {
        let cost: Int64
        let proceeds: Int64
        let model: String
        let inspected: Bool
    }

    static func calculate(_ trades: [Input]) throws -> Int64 {
        guard trades.count <= 10_000 else { throw SaveError.invalidSave }
        var cost: Int64 = 0, proceeds: Int64 = 0
        var qualityModels: Set<String> = []
        for trade in trades {
            guard (1...transactionLimit).contains(trade.cost), (0...transactionLimit).contains(trade.proceeds), !trade.model.isEmpty else { throw SaveError.invalidSave }
            cost += trade.cost; proceeds += trade.proceeds // <= 10^13, safe before all multiplications below.
            if trade.inspected && trade.cost >= 1_000 && trade.proceeds - trade.cost >= 100 { qualityModels.insert(trade.model) }
        }
        let profit = max(0, proceeds - cost)
        guard profit > 0 else { return 0 }
        let normalizedProfit = min(800_000, profit * 10_000 / bankroll.minorUnits)
        let portfolioROI = min(150_000, profit * 10_000 / max(bankroll.minorUnits, cost))
        let quality = Int64(min(20, qualityModels.count)) * 2_500
        return min(cap, normalizedProfit + portfolioROI + quality)
    }

    static func calculate(_ state: GameSnapshot, period: WeeklyPeriod) throws -> Int64 {
        guard state.simulationID == period.id, state.marketConfiguration.region == .unitedStates,
              state.player.cash >= .zero, state.player.cash.minorUnits <= 100_000_000_000_000,
              state.recovery.sequence == 0, state.recovery.commissionsEarned == .zero,
              state.collections.displayed.isEmpty, state.shop == TraderShop(),
              Set(state.playerListings.map(\.id)).count == state.playerListings.count else { throw SaveError.invalidSave }
        let records = try TradeLedger.records(from: state)
        guard Set(state.playerListings.filter { $0.status == .sold }.map(\.itemID)).count == records.count,
              records.allSatisfy({ period.contains($0.soldAt) && $0.kind == .market }) else { throw SaveError.invalidSave }
        // Cash must reconcile with durable acquisition/service costs and settled receipts.
        // Delivered shipment history is excluded: its item is now in inventory or a sold receipt.
        let soldItems = state.playerListings.filter { $0.status == .sold }.compactMap(\.itemSnapshot)
        let ownedItems = state.player.inventory + state.shipments.filter { $0.status == .pending }.map(\.item)
        let allItems = ownedItems + soldItems
        guard allItems.count <= 10_000, Set(allItems.map(\.id)).count == allItems.count else { throw SaveError.invalidSave }
        var spent: Int64 = 0
        for item in allItems {
            guard (1...transactionLimit).contains(item.purchasePrice.minorUnits),
                  (0...transactionLimit).contains(item.inspectionCost.minorUnits),
                  (0...transactionLimit).contains(item.repairCost.minorUnits),
                  let acquiredAt = item.acquiredAt, period.contains(acquiredAt) else { throw SaveError.invalidSave }
            spent += item.purchasePrice.minorUnits + item.inspectionCost.minorUnits + item.repairCost.minorUnits
        }
        for category in state.inspectionKnowledge.tools { spent += InspectionKnowledge.toolCost(for: category).minorUnits }
        var received: Int64 = 0
        for record in records {
            guard (1...transactionLimit).contains(record.totalCost.minorUnits), (0...transactionLimit).contains(record.soldFor.minorUnits) else { throw SaveError.invalidSave }
            received += record.soldFor.minorUnits
        }
        guard state.player.cash.minorUnits == bankroll.minorUnits + received - spent else { throw SaveError.invalidSave }
        return try calculate(records.map { record in
            Input(cost: record.totalCost.minorUnits, proceeds: record.soldFor.minorUnits, model: record.definitionID,
                  inspected: state.playerListings.first { $0.id == record.id }?.itemSnapshot?.inspected == true)
        })
    }
}

/// Monday 00:00 UTC. App Store Connect must use this same anchor and 604800-second recurrence.
struct WeeklyPeriod: Codable, Equatable, Identifiable, Sendable {
    static let duration: TimeInterval = 604_800
    static let anchor = Date(timeIntervalSince1970: 1_704_067_200) // 2024-01-01T00:00:00Z
    let index: Int
    var id: String { "weekly-v1-\(index)" }
    var start: Date { Self.anchor.addingTimeInterval(Double(index) * Self.duration) }
    var end: Date { start.addingTimeInterval(Self.duration) }
    var seed: UInt64 { SeededRandom.seed(for: id) }
    static func containing(_ date: Date) -> Self {
        Self(index: Int(floor(date.timeIntervalSince(anchor) / duration)))
    }
    func contains(_ date: Date) -> Bool { date >= start && date < end }
    func matches(start: Date?, duration: TimeInterval) -> Bool {
        guard let start else { return false }
        return abs(start.timeIntervalSince(self.start)) < 1 && abs(duration - Self.duration) < 1
    }
    func validate() throws { guard (0...100_000).contains(index) else { throw SaveError.invalidSave } }
}
