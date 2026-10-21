import Foundation

struct PricingEngine {
    static func fairValue(of item: ItemInstance, definition: ItemDefinition, marketBasisPoints: Int64 = 10_000) throws -> Money {
        let conditioned = try definition.baseValue.scaled(byBasisPoints: Int64(4_000 + item.condition * 60))
        let penalty = item.activeDefects.reduce(Int64(0)) { $0 + $1.valuePenaltyBasisPoints }
        let defective = try conditioned.scaled(byBasisPoints: max(2_000, 10_000 - penalty))
        return try defective.scaled(byBasisPoints: marketBasisPoints)
    }
}

struct ListingGenerator {
    func generate(definitions: [ItemDefinition], seed: UInt64, now: Date, marketBasisPoints: Int64 = 10_000, market: GameSnapshot? = nil, starterFriendly: Bool = true) throws -> [MarketplaceListing] {
        var random = SeededRandom(seed: seed)
        return try definitions.enumerated().map { index, definition in
            let marketBasisPoints = try market?.marketMultiplier(for: definition, at: now) ?? marketBasisPoints
            let archetype = SellerArchetype.allCases[index % SellerArchetype.allCases.count]
            let knowledge = archetype == .clueless ? 20 : (archetype == .professional ? 95 : random.integer(in: 35...80))
            let honesty = archetype == .manipulative ? 15 : random.integer(in: 65...100)
            let urgency = archetype == .urgent ? 95 : random.integer(in: 10...70)
            let seller = SellerProfile(id: SellerID("seller-\(seed)-\(index)"), identityIndex: index, archetype: archetype, knowledge: knowledge, honesty: honesty, urgency: urgency, bargainingSkill: random.integer(in: 30...90), patience: random.integer(in: 45...90), tradeCount: random.integer(in: 1...140), ratingTenths: random.integer(in: 35...50))
            // One existing, novice-detectable fault teaches the first repair-or-sell choice.
            // No additional random draw: all later stock keeps its existing stream.
            let starterLesson = starterFriendly && index == 0 && definition.possibleDefects.contains(.damagedPort)
            let defects: [Defect] = starterLesson ? [.damagedPort] :
                (!starterFriendly || index > 0) && random.integer(in: 0...99) < 45 ? [definition.possibleDefects[random.integer(in: 0...(definition.possibleDefects.count - 1))]] : []
            let rolledCondition = random.integer(in: 55...98)
            let condition = starterLesson ? min(79, rolledCondition) : rolledCondition
            var item = ItemInstance(id: ItemID("item-\(seed)-\(index)"), definitionID: definition.id, condition: condition, hiddenDefects: defects)
            item.facts = ItemFacts.generate(for: item, definition: definition)
            let cleanValue = try PricingEngine.fairValue(of: ItemInstance(id: item.id, definitionID: item.definitionID, condition: condition, hiddenDefects: []), definition: definition, marketBasisPoints: marketBasisPoints)
            let trueValue = try PricingEngine.fairValue(of: item, definition: definition, marketBasisPoints: marketBasisPoints)
            // Belief and presentation differ: an uninformed seller cannot price an unknown fault.
            let sellerBelief = knowledge < 40 ? cleanValue : trueValue
            let perceived = honesty < 40 ? cleanValue : sellerBelief
            let bias: Int
            if starterLesson { bias = 6_000 }
            else if starterFriendly && index == 0 { bias = 8_500 }
            else {
                let roll = random.integer(in: 8_000...13_000) - 8_000
                let range: (Int, Int) = switch archetype {
                case .clueless: (5_500, 13_500)
                case .urgent: (7_500, 10_000)
                case .professional: (9_700, 11_800)
                case .stubborn: (12_000, 17_000)
                case .collector: (11_000, 15_000)
                case .manipulative: (6_000, 12_500)
                case .friendly: (8_000, 10_500)
                case .casual: (8_000, 12_500)
                }
                bias = range.0 + roll * (range.1 - range.0) / 5_000
            }
            let asking = try perceived.scaled(byBasisPoints: Int64(bias))
            let reservation = min(asking, try sellerBelief.scaled(byBasisPoints: Int64(8_000 - urgency * 20)))
            return MarketplaceListing(id: ListingID("listing-\(seed)-\(index)"), item: item, seller: seller, askingPrice: asking, reservationPrice: reservation, claimedCondition: honesty < 40 ? min(100, condition + 18) : condition, descriptionIntent: starterLesson ? "listing.description.starter" : honesty < 40 ? "listing.description.evasive" : (knowledge < 40 ? "listing.description.uncertain" : "listing.description.careful"), createdAt: now.addingTimeInterval(-TimeInterval(index * 180)))
        }
    }
}
