import Foundation
import Testing
@testable import ProjectFlip

struct ClientExpansionTests {
    @Test func allSixContactsHaveThreeAuthoredRequestsUsingRealCatalogModels() throws {
        let definitions = try SeedContent.load().items
        let ids = Set(definitions.map(\.id))
        #expect(ClientDefinition.all.count == 6)
        #expect(Set(ClientDefinition.all.map(\.id)).count == 6)
        for client in ClientDefinition.all {
            #expect(client.requests.count == 3)
            for request in client.requests {
                #expect(!request.models.isEmpty && request.models.isSubset(of: ids))
                #expect((1...100).contains(request.minimumCondition))
                #expect(request.maximumPayment.map { $0 > .zero } ?? true)
            }
            for language in GameText.supportedLanguages {
                let locale = Locale(identifier: language)
                for suffix in ["name.unitedStates", "name.turkey", "role", "story.0", "story.1", "story.2", "ending"] {
                    #expect(GameText.string("client.\(client.id).\(suffix)", locale: locale) != "…")
                }
            }
        }
    }

    @Test func clientHonorsUnlockOnlyAtTheFinalChapterAndKeepLegacyCareerTitleIDs() throws {
        var state = try GameSnapshot.fresh(definitions: SeedContent.load().items)
        #expect(TraderTitle.earned(in: state).map(\.id) == [CareerTier.newcomer.rawValue])
        #expect(Set(ClientDefinition.all.map(\.titleID)).count == ClientDefinition.all.count)
        for client in ClientDefinition.all {
            state.clients.completed[client.id] = 2
            #expect(!TraderTitle.earned(in: state).contains { $0.id == client.titleID })
            state.clients.completed[client.id] = 3
            let earned = try #require(TraderTitle.earned(in: state).first { $0.id == client.titleID })
            #expect(earned.clientID == client.id)
            for language in GameText.supportedLanguages {
                #expect(GameText.string(earned.key, locale: Locale(identifier: language)) != "…")
            }
        }
        #expect(TraderTitle.earned(in: state).filter { $0.clientID != nil }.count == 6)
        #expect(TraderTitle.earned(in: state).first?.id == 0)
    }

    @Test func twelveNewRequestsSettleOnceAndPersistTheirProgress() throws {
        let definitions = try SeedContent.load().items
        var state = try GameSnapshot.fresh(definitions: definitions)
        state.career.creditedItems = Set((0..<24).map { ItemID("experienced-\($0)") })
        state.inspectionKnowledge.learn(16, in: .gaming)
        var expectedCash = state.player.cash
        for id in ["mira", "noah", "aya", "leon"] {
            for step in 0..<3 {
                let request = try #require(ClientEngine.request(id, state: state))
                let definition = try #require(definitions.first { request.models.contains($0.id) })
                let item = ItemInstance(id: ItemID("\(id)-\(step)"), definitionID: definition.id, condition: 95, hiddenDefects: [], inspected: true, professionallyInspected: true, purchasePrice: Money(minorUnits: 1_000))
                state.player.inventory.append(item)
                state = try ClientEngine.accept(id, state: state)
                #expect(ClientEngine.activeBrief(in: state)?.client.id == id)
                let quote = try ClientEngine.quote(item, definition: definition, state: state)
                state = try ClientEngine.fulfill(id, itemID: item.id, state: state, definitions: definitions, now: .distantPast, expectedQuote: quote)
                expectedCash = try expectedCash.adding(quote)
                #expect(state.clients.completed[id] == step + 1)
                #expect(state.clients.active == nil && !state.player.inventory.contains { $0.id == item.id })
                #expect(throws: TradingError.self) { try ClientEngine.fulfill(id, itemID: item.id, state: state, definitions: definitions, now: .distantPast) }
            }
            #expect(ClientEngine.request(id, state: state) == nil)
        }
        #expect(state.player.cash == expectedCash)
        #expect(state.playerListings.filter { $0.saleKind == .client }.count == 12)
        let restored = try JSONDecoder().decode(GameSnapshot.self, from: JSONEncoder().encode(state))
        try restored.clients.validate()
        #expect(restored == state)
    }

    @Test func clientBudgetsCapPaymentWithoutRefundingOverpayment() throws {
        let definitions = try SeedContent.load().items
        var state = try GameSnapshot.fresh(definitions: definitions)
        state = try ClientEngine.accept("noah", state: state)
        let definition = try #require(definitions.first { $0.id == "everyday-4" })
        let cheap = ItemInstance(id: ItemID("budget-cheap"), definitionID: definition.id, condition: 100, hiddenDefects: [],
                                 inspected: true, professionallyInspected: true, purchasePrice: Money(minorUnits: 1_000))
        let expensive = ItemInstance(id: ItemID("budget-expensive"), definitionID: definition.id, condition: 100, hiddenDefects: [],
                                     inspected: true, professionallyInspected: true, purchasePrice: Money(minorUnits: 100_000))
        let cap = try #require(ClientEngine.activeBrief(in: state)?.request.maximumPayment)
        let marketQuote = try InspectionEngine().estimatedValue(item: cheap, definition: definition, marketBasisPoints: state.marketMultiplier(for: definition)).scaled(byBasisPoints: 10_200)
        #expect(marketQuote > cap)
        #expect(try ClientEngine.quote(cheap, definition: definition, state: state) == cap)
        #expect(try ClientEngine.quote(expensive, definition: definition, state: state) == cap)
        #expect(cap < expensive.purchasePrice)
    }

    @Test func staleClientQuoteCannotTakeTheItemOrPayAnUnexpectedAmount() throws {
        let definitions = try SeedContent.load().items
        var state = try GameSnapshot.fresh(definitions: definitions)
        let definition = try #require(definitions.first { $0.id == "home-0" })
        let item = ItemInstance(id: ItemID("quote-fixture"), definitionID: definition.id, condition: 90, hiddenDefects: [], inspected: true, professionallyInspected: true)
        state.player.inventory = [item]
        state = try ClientEngine.accept("mira", state: state)
        let wrongQuote = try ClientEngine.quote(item, definition: definition, state: state).adding(Money(minorUnits: 1))
        let before = state
        #expect(throws: TradingError.quoteChanged) { try ClientEngine.fulfill("mira", itemID: item.id, state: state, definitions: definitions, now: .distantPast, expectedQuote: wrongQuote) }
        #expect(state == before)
    }

    @Test func sourcingFiltersUseModelNamesWithoutReadingHiddenTruth() throws {
        let definitions = try SeedContent.load().items
        var state = try GameSnapshot.fresh(definitions: definitions)
        let query = MarketQuery(modelIDs: ["home-0", "furniture-0"])
        let before = query.results(in: state, definitions: definitions, locale: Locale(identifier: "es_ES")).map(\.id)
        #expect(before.count == 2)
        for index in state.market.indices {
            let listing = state.market[index]
            let definition = try #require(definitions.first { $0.id == listing.item.definitionID })
            let differentTruth = ItemInstance(id: listing.item.id, definitionID: listing.item.definitionID, condition: 1,
                                              hiddenDefects: definition.possibleDefects.first.map { [$0] } ?? [])
            state.market[index] = MarketplaceListing(id: listing.id, item: differentTruth, seller: listing.seller,
                                                     askingPrice: listing.askingPrice, reservationPrice: listing.reservationPrice,
                                                     claimedCondition: listing.claimedCondition, descriptionIntent: listing.descriptionIntent,
                                                     createdAt: listing.createdAt, available: listing.available)
        }
        #expect(query.results(in: state, definitions: definitions, locale: Locale(identifier: "es_ES")).map(\.id) == before)
        #expect(MarketQuery(category: .gaming, modelIDs: ["home-0"]).results(in: state, definitions: definitions, locale: .current).isEmpty)
        #expect(MarketQuery(modelIDs: []).results(in: state, definitions: definitions, locale: .current).isEmpty)
        #expect(ClientEngine.activeBrief(in: state) == nil)
    }
}
