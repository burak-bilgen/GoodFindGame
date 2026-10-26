import Foundation
import Testing
@testable import ProjectFlip

struct MarketDiscoveryTests {
    @Test func singleArrivalsCanReachEveryIllustratedModelAcrossCategoryCycles() throws {
        let definitions = try SeedContent.load().items
        let active = MarketCatalog.active(definitions)
        var seen = Set<String>()
        for seed: UInt64 in 1...6000 {
            let arrival = MarketCatalog.liveFeed(from: definitions, count: 1, seed: seed)
            #expect(arrival.count == 1)
            seen.formUnion(arrival.map(\.id))
        }
        let missing = Set(active.map(\.id)).subtracting(seen)
        print("DISCOVERY COVERAGE: \(seen.count)/\(active.count); missing \(missing.sorted())")
        #expect(missing.isEmpty)
    }

    @Test func completeRotationAlsoWorksWithPartiallyUnlockedCategoryPools() throws {
        let definitions = try SeedContent.load().items
        for categories: [ItemCategory] in [[.gaming], [.cameras, .retro], ItemCategory.allCases] {
            for limit in [5, 7, 20] {
                let pool = categories.flatMap { category in Array(definitions.filter { $0.category == category }.prefix(limit)) }
                let active = MarketCatalog.active(pool)
                let bound = categories.count * (categories.map { category in active.filter { $0.category == category }.count }.max() ?? 0)
                var seen = Set<String>()
                for seed in 0..<bound {
                    seen.formUnion(MarketCatalog.liveFeed(from: pool, count: 1, seed: UInt64(seed)).map(\.id))
                }
                #expect(seen == Set(active.map(\.id)))
            }
        }
    }

}
