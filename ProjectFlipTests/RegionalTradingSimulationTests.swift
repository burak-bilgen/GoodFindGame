import Foundation
import Testing
@testable import ProjectFlip

struct RegionalTradingSimulationTests {
    @Test func repeatedTradesAcrossRegionsReconcileWithoutFreeRepairMoney() throws {
        let definitions = try SeedContent.load().items
        for config in [MarketConfiguration.us, .turkey] {
            for cautious in [false, true] {
                var state = try GameSnapshot.fresh(definitions: definitions, marketConfiguration: config)
                state.simulationID = "simulation-\(config.region)-\(cautious)"
                let initialCash = state.player.cash
                var trades = 0, repaired = 0
                for index in 0..<250 {
                    let pool = definitions.filter { CareerEngine.canAccess($0, state: state) }
                    let definition = pool[index % pool.count]
                    let listing = try ListingGenerator().generate(definitions: [definition], seed: UInt64(1000 + index), now: .distantPast, market: state, starterFriendly: false, variedSellers: true)[0]
                    let publicItem = ItemInstance(id: listing.item.id, definitionID: definition.id, condition: listing.claimedCondition, hiddenDefects: [])
                    let reference = try PricingEngine.fairValue(of: publicItem, definition: definition, marketBasisPoints: state.marketMultiplier(for: definition))
                    let discountCutoff = try reference.scaled(byBasisPoints: 9_000)
                    if cautious && listing.askingPrice > discountCutoff { continue }
                    let needed = try listing.askingPrice.adding(InspectionEngine().professionalCost)
                    guard state.player.cash >= needed else { continue }
                    state.market = [listing]
                    var agreement = NegotiationState(listingID: listing.id, patience: 100)
                    agreement.agreedPrice = listing.askingPrice; state.conversations = [agreement]
                    state = try PurchaseEngine().buy(listingID: listing.id, state: state, now: .distantPast)
                    state = try InspectionEngine().inspect(itemID: listing.item.id, professionally: true, state: state, category: definition.category)
                    for fault in state.player.inventory[0].knownActiveDefects {
                        let quote = try RepairQuote(item: state.player.inventory[0], definition: definition, defect: fault, marketBasisPoints: state.marketMultiplier(for: definition))
                        if quote.cost < quote.estimatedRecovery && state.player.cash >= quote.cost {
                            state = try RepairEngine().repair(itemID: listing.item.id, defect: fault, state: state, definitions: definitions); repaired += 1
                            #expect(throws: TradingError.self) { try RepairEngine().repair(itemID: listing.item.id, defect: fault, state: state, definitions: definitions) }
                        }
                    }
                    let item = state.player.inventory[0]
                    let estimate = try InspectionEngine().estimatedValue(item: item, definition: definition, marketBasisPoints: state.marketMultiplier(for: definition))
                    state = try ResaleEngine().create(itemID: item.id, askingPrice: estimate, state: state, definitions: definitions, now: .distantPast)
                    let id = try #require(state.playerListings.last?.id)
                    state = try BuyerEngine().generateOffer(listingID: id, state: state, definitions: definitions)
                    state = try BuyerEngine().accept(listingID: id, state: state, now: .distantPast)
                    trades += 1
                    let records = try TradeLedger.records(from: state)
                    #expect(try state.player.cash == initialCash.adding(TradeLedger.totalProfit(records)))
                    #expect(state.player.inventory.isEmpty && state.player.cash >= .zero)
                }
                #expect(trades >= 5)
                let records = try TradeLedger.records(from: state)
                let losses = records.filter { $0.netProfit < .zero }.count
                print("TRADING SIM: \(config.region) \(cautious ? "public-discount filter" : "unfiltered") trades=\(trades) losses=\(losses) repairs=\(repaired) finalCanonicalCents=\(state.player.cash.minorUnits)")
            }
        }
    }
}

extension RegionalTradingSimulationTests {
    @Test func evidenceAwareTradingUsesBargainingAndEarnedTools() throws {
        let definitions = try SeedContent.load().items
        for config in [MarketConfiguration.us, .turkey] {
            var state = try GameSnapshot.fresh(definitions: definitions, marketConfiguration: config)
            state.simulationID = "evidence-aware-\(config.region)"
            for category in ItemCategory.allCases { state = try InspectionEngine().buyTools(for: category, state: state) }
            let initialAfterTools = state.player.cash
            var trades = 0, reports = 0, rejected = 0
            for index in 0..<1_000 {
                let pool = definitions.filter { CareerEngine.canAccess($0, state: state) }
                let definition = pool[index % pool.count]
                let listing = try ListingGenerator().generate(definitions: [definition], seed: UInt64(5_000 + index), now: .distantPast, market: state, starterFriendly: false, variedSellers: true)[0]
                var conversation = NegotiationState(listingID: listing.id, patience: listing.seller.patience)
                conversation = try NegotiationEngine().askAboutIssues(listing: listing, current: conversation)
                let publicItem = ItemInstance(id: listing.item.id, definitionID: definition.id, condition: listing.claimedCondition, hiddenDefects: conversation.knownDefects)
                let publicEstimate = try PricingEngine.fairValue(of: publicItem, definition: definition, marketBasisPoints: state.marketMultiplier(for: definition))
                let bid = try listing.askingPrice.scaled(byBasisPoints: 8_500)
                conversation = try NegotiationEngine().offer(bid, modifier: .none, listing: listing, current: conversation, reputation: state.player.reputation)
                guard let quote = conversation.agreedPrice ?? conversation.counterPrice else { rejected += 1; continue }
                let ceiling = try publicEstimate.scaled(byBasisPoints: 8_500)
                guard quote <= ceiling, state.player.cash >= (try quote.adding(InspectionEngine().professionalCost)) else { rejected += 1; continue }
                conversation.agreedPrice = quote
                state.market = [listing]; state.conversations = [conversation]
                state = try PurchaseEngine().buy(listingID: listing.id, state: state, now: .distantPast)
                state = try InspectionEngine().inspect(itemID: listing.item.id, professionally: false, state: state, category: definition.category)
                if state.inspectionKnowledge.level(in: definition.category) < 3 {
                    state = try InspectionEngine().inspect(itemID: listing.item.id, professionally: true, state: state, category: definition.category)
                    reports += 1
                }
                let item = state.player.inventory[0]
                let estimate = try InspectionEngine().estimatedValue(item: item, definition: definition, marketBasisPoints: state.marketMultiplier(for: definition))
                state = try ResaleEngine().create(itemID: item.id, askingPrice: estimate.scaled(byBasisPoints: 11_000), state: state, definitions: definitions, now: .distantPast)
                let id = try #require(state.playerListings.last?.id)
                state = try BuyerEngine().generateOffer(listingID: id, state: state, definitions: definitions)
                state = try BuyerEngine().accept(listingID: id, state: state, now: .distantPast)
                trades += 1
                #expect(try state.player.cash == initialAfterTools.adding(TradeLedger.totalProfit(TradeLedger.records(from: state))))
            }
            let records = try TradeLedger.records(from: state)
            print("SKILLED SIM: \(config.region) trades=\(trades) rejected=\(rejected) reports=\(reports) losses=\(records.filter { $0.netProfit < .zero }.count) finalCanonicalCents=\(state.player.cash.minorUnits)")
            #expect(trades >= 10)
            #expect(reports < trades)
            #expect(state.player.cash > GameBalanceConfig.current.startingCash)
        }
    }
}

extension RegionalTradingSimulationTests {
    /// Public-information strategies across identical opportunities. Independent
    /// bankrolls avoid hiding losing outcomes once a sequential run goes broke.
    @Test func decisionQualityProducesDifferentSustainableOutcomes() throws {
        let definitions = MarketCatalog.active(try SeedContent.load().items)
        var winRates: [Double] = []
        for strategy in 0...2 {
            var wins = 0, losses = 0, profit: Int64 = 0, invested: Int64 = 0
            var largeRiskWins = 0, largeRiskLosses = 0
            for sample in 0..<600 {
                var state = try GameSnapshot.fresh(definitions: definitions)
                state.simulationID = "quality-\(sample)"
                state.player.cash = Money(minorUnits: 1_000_000)
                let definition = definitions[sample % definitions.count]
                let listing = try ListingGenerator().generate(definitions: [definition], seed: UInt64(20_000 + sample), now: .distantPast, starterFriendly: false, variedSellers: true)[0]
                var talk = NegotiationState(listingID: listing.id, patience: listing.seller.patience)
                talk = try NegotiationEngine().askAboutIssues(listing: listing, current: talk)
                let visible = ItemInstance(id: listing.item.id, definitionID: definition.id, condition: listing.claimedCondition, hiddenDefects: talk.knownDefects)
                let reference = try PricingEngine.fairValue(of: visible, definition: definition)
                if strategy == 0 {
                    talk.agreedPrice = listing.askingPrice
                } else {
                    talk = try NegotiationEngine().offer(listing.askingPrice.scaled(byBasisPoints: 8_500), modifier: talk.knownDefects.isEmpty ? .buyToday : .knownIssues, listing: listing, current: talk, reputation: 0)
                    guard let quote = talk.agreedPrice ?? talk.counterPrice,
                          quote <= (try reference.scaled(byBasisPoints: strategy == 1 ? 10_000 : 8_500)) else { continue }
                    talk.agreedPrice = quote
                }
                state.market = [listing]; state.conversations = [talk]
                state = try PurchaseEngine().buy(listingID: listing.id, state: state, now: .distantPast)
                state = try InspectionEngine().inspect(itemID: listing.item.id, professionally: false, state: state, category: definition.category)
                if strategy == 2 {
                    for defect in state.player.inventory[0].knownActiveDefects {
                        let quote = try RepairQuote(item: state.player.inventory[0], definition: definition, defect: defect)
                        if quote.cost < (try quote.estimatedRecovery.scaled(byBasisPoints: 7_500)) {
                            state = try RepairEngine().repair(itemID: listing.item.id, defect: defect, state: state, definitions: definitions)
                        }
                    }
                }
                let item = state.player.inventory[0]
                let estimate = try InspectionEngine().estimatedValue(item: item, definition: definition)
                // A previous closed listing prevents every sample receiving the tutorial buyer.
                state.playerListings = [PlayerListing(id: ListingID("previous"), itemID: ItemID("previous"), askingPrice: Money(minorUnits: 1), createdAt: .distantPast, status: .cancelled, views: 0, favorites: 0)]
                state = try ResaleEngine().create(itemID: item.id, askingPrice: estimate.scaled(byBasisPoints: strategy == 2 ? 10_500 : 10_000), state: state, definitions: definitions, now: .distantPast)
                let id = state.playerListings[1].id
                for attempt in 0..<(strategy == 2 ? 3 : 1) {
                    state = try BuyerEngine().generateOffer(listingID: id, state: state, definitions: definitions)
                    guard let offer = state.playerListings[1].offers.last else { break }
                    // A skilled player can pass on two lowballs, not shop forever.
                    if try strategy == 2 && attempt < 2 && offer.amount < estimate.scaled(byBasisPoints: 8_500) {
                        state = try BuyerEngine().reject(listingID: id, state: state)
                        continue
                    }
                    state = try BuyerEngine().accept(listingID: id, state: state, now: .distantPast)
                    break
                }
                if state.playerListings[1].status == .active {
                    // Overpricing an undiscovered severe fault may attract nobody.
                    // Count a real liquidation loss rather than silently dropping it.
                    state.playerListings[1].status = .cancelled
                    state = try RecoveryEngine.liquidate(item.id, state: state, definitions: definitions, now: .distantPast)
                }
                let record = try TradeRecord(listing: #require(state.playerListings.last))
                if record.netProfit > .zero { wins += 1 } else if record.netProfit < .zero { losses += 1 }
                profit += record.netProfit.minorUnits; invested += record.totalCost.minorUnits
                if listing.seller.archetype == .clueless || listing.seller.archetype == .manipulative {
                    let tradeROI = Double(record.netProfit.minorUnits) / Double(max(1, record.totalCost.minorUnits))
                    if tradeROI >= 0.30 { largeRiskWins += 1 }
                    if tradeROI <= -0.30 { largeRiskLosses += 1 }
                }
            }
            let count = wins + losses
            let winRate = Double(wins) / Double(max(1, count))
            let roi = Double(profit) / Double(max(1, invested))
            print("QUALITY strategy=\(strategy) trades=\(count) wins=\(wins) losses=\(losses) ROI=\(roi)")
            #expect(count >= 60)
            if strategy == 0 {
                #expect(winRate < 0.5 && roi < 0)
                #expect(largeRiskWins >= 5 && largeRiskLosses >= 5, "Risky sellers must retain both substantial upside and meaningful losses")
                print("QUALITY risky trades: \(largeRiskWins) above +30% ROI, \(largeRiskLosses) below -30% ROI")
            }
            if strategy == 1 { #expect(winRate >= 0.50 && winRate <= 0.75 && roi >= 0 && roi < 0.15) }
            if strategy == 2 { #expect(winRate >= 0.80 && winRate < 0.97 && roi >= 0.12) }
            winRates.append(winRate)
        }
        #expect(winRates[0] < winRates[1] && winRates[1] < winRates[2])
    }
}
