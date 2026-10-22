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
