import Foundation

enum ItemFactKey: String, Codable, CaseIterable, Sendable {
    case cosmeticScore, shutterCount, batteryHealth, optics, sensor, autofocus, aperture, stabilization
    case region, completeness, packaging, originalParts, authenticity, edition

    var requiredLevel: Int {
        switch self {
        case .cosmeticScore, .completeness, .packaging, .edition: 0
        case .batteryHealth, .originalParts: 1
        case .shutterCount, .autofocus, .region: 2
        case .optics, .sensor, .aperture, .stabilization, .authenticity: 3
        }
    }
    var requiresTools: Bool { requiredLevel > 0 }
    var associatedDefects: [Defect] {
        switch self {
        case .shutterCount: [.shutterWear]
        case .batteryHealth: [.batteryWear, .cameraBatteryWear]
        case .optics: [.lensScratch, .lensFungus]
        case .sensor: [.sensorDamage]
        case .autofocus: [.autofocusFault]
        case .aperture: [.apertureStuck]
        case .stabilization: [.stabilizationFault]
        case .region: [.regionMismatch]
        case .completeness: [.missingManual, .incompleteSet]
        case .packaging: [.boxWear]
        case .originalParts: [.replacementParts]
        case .authenticity: [.counterfeitBoard]
        case .cosmeticScore, .edition: []
        }
    }
}

enum ItemFactTerm: String, Codable, CaseIterable, Sendable {
    case passed, failed, clear, scratched, fungus, scratchedAndFungus
    case regionA, regionB, regionFree, complete, missingManual, missingPieces, missingManualAndPieces
    case originalBox, wornOriginalBox, originalParts, replacedParts, authentic, reproduction, standardEdition
}

enum ItemFactValue: Codable, Equatable, Sendable {
    case number(Int)
    case term(ItemFactTerm)
}

struct ItemFact: Codable, Equatable, Identifiable, Sendable {
    let key: ItemFactKey
    let value: ItemFactValue
    var id: ItemFactKey { key }
}

/// Generated once using a separate stream; introducing clues cannot reroll prices, sellers or defects.
struct ItemFacts: Codable, Equatable, Sendable {
    let version: Int
    let category: ItemCategory
    let values: [ItemFact]

    static func generate(for item: ItemInstance, definition: ItemDefinition) -> Self {
        var random = SeededRandom(seed: SeededRandom.seed(for: "facts-v1-\(item.id.rawValue)-\(definition.id)"))
        let defects = Set(item.hiddenDefects)
        var values = [ItemFact(key: .cosmeticScore, value: .number(item.condition))]
        func term(_ key: ItemFactKey, _ value: ItemFactTerm) { values.append(ItemFact(key: key, value: .term(value))) }
        func test(_ key: ItemFactKey, _ defect: Defect) {
            if definition.possibleDefects.contains(defect) { term(key, defects.contains(defect) ? .failed : .passed) }
        }
        switch definition.category {
        case .gaming:
            if definition.possibleDefects.contains(.batteryWear) {
                values.append(ItemFact(key: .batteryHealth, value: .number(random.integer(in: defects.contains(.batteryWear) ? 35...65 : 75...100))))
            }
        case .cameras:
            // Lens definitions have no body-specific defect pool, so never get body measurements.
            let isBody = definition.possibleDefects.contains { [.sensorDamage, .shutterWear, .cameraBatteryWear].contains($0) }
            if isBody {
                values.append(ItemFact(key: .shutterCount, value: .number(random.integer(in: defects.contains(.shutterWear) ? 120_000...240_000 : 1_000...85_000))))
                values.append(ItemFact(key: .batteryHealth, value: .number(random.integer(in: defects.contains(.cameraBatteryWear) ? 35...65 : 75...100))))
            }
            if definition.possibleDefects.contains(.lensScratch) || definition.possibleDefects.contains(.lensFungus) {
                let scratch = defects.contains(.lensScratch), fungus = defects.contains(.lensFungus)
                term(.optics, scratch && fungus ? .scratchedAndFungus : scratch ? .scratched : fungus ? .fungus : .clear)
            }
            test(.sensor, .sensorDamage)
            test(.autofocus, .autofocusFault)
            test(.aperture, .apertureStuck)
            test(.stabilization, .stabilizationFault)
        case .retro:
            term(.region, defects.contains(.regionMismatch) ? .regionB : random.integer(in: 0...2) == 0 ? .regionFree : .regionA)
            let manual = defects.contains(.missingManual), pieces = defects.contains(.incompleteSet)
            term(.completeness, manual && pieces ? .missingManualAndPieces : manual ? .missingManual : pieces ? .missingPieces : .complete)
            term(.packaging, defects.contains(.boxWear) ? .wornOriginalBox : .originalBox)
            term(.originalParts, defects.contains(.replacementParts) || defects.contains(.counterfeitBoard) ? .replacedParts : .originalParts)
            term(.authenticity, defects.contains(.counterfeitBoard) ? .reproduction : .authentic)
            // Rare editions are introduced by the later variant system, not randomly asserted here.
            term(.edition, .standardEdition)
        }
        return Self(version: 1, category: definition.category, values: values)
    }

    func validate() throws {
        guard version == 1, Set(values.map(\.key)).count == values.count,
              values.contains(where: { $0.key == .cosmeticScore }) else { throw SaveError.invalidSave }
        let allowed: Set<ItemFactKey> = switch category {
        case .gaming: [.cosmeticScore, .batteryHealth]
        case .cameras: [.cosmeticScore, .shutterCount, .batteryHealth, .optics, .sensor, .autofocus, .aperture, .stabilization]
        case .retro: [.cosmeticScore, .region, .completeness, .packaging, .originalParts, .authenticity, .edition]
        }
        for fact in values {
            guard allowed.contains(fact.key) else { throw SaveError.invalidSave }
            let valid: Bool
            switch (fact.key, fact.value) {
            case (.cosmeticScore, .number(let n)), (.batteryHealth, .number(let n)): valid = (0...100).contains(n)
            case (.shutterCount, .number(let n)): valid = (0...1_000_000).contains(n)
            case (.optics, .term(let term)): valid = [.clear, .scratched, .fungus, .scratchedAndFungus].contains(term)
            case (.sensor, .term(let term)), (.autofocus, .term(let term)), (.aperture, .term(let term)), (.stabilization, .term(let term)): valid = [.passed, .failed].contains(term)
            case (.region, .term(let term)): valid = [.regionA, .regionB, .regionFree].contains(term)
            case (.completeness, .term(let term)): valid = [.complete, .missingManual, .missingPieces, .missingManualAndPieces].contains(term)
            case (.packaging, .term(let term)): valid = [.originalBox, .wornOriginalBox].contains(term)
            case (.originalParts, .term(let term)): valid = [.originalParts, .replacedParts].contains(term)
            case (.authenticity, .term(let term)): valid = [.authentic, .reproduction].contains(term)
            case (.edition, .term(let term)): valid = term == .standardEdition
            default: valid = false
            }
            guard valid else { throw SaveError.invalidSave }
        }
    }
}

extension ItemInstance {
    var knownFactKeys: Set<ItemFactKey> { revealedFactKeys ?? [] }

    mutating func revealFacts(knowledge: InspectionKnowledge, professionally: Bool) {
        guard let facts else { return }
        let visible = facts.values.filter { fact in
            professionally || (knowledge.level(in: facts.category) >= fact.key.requiredLevel && (!fact.key.requiresTools || knowledge.tools.contains(facts.category)))
        }
        revealedFactKeys = knownFactKeys.union(visible.map(\.key))
        // A conclusive measurement cannot contradict the defect summary or valuation estimate.
        let established = Set(visible.flatMap { $0.key.associatedDefects })
        revealedDefects += hiddenDefects.filter { established.contains($0) && !revealedDefects.contains($0) }
    }

    func validateFacts() throws {
        guard Set(repairedDefects ?? []).count == (repairedDefects ?? []).count,
              Set(repairedDefects ?? []).isSubset(of: Set(revealedDefects)),
              Set(repairedDefects ?? []).isSubset(of: Set(hiddenDefects)) else { throw SaveError.invalidSave }
        try facts?.validate()
        guard knownFactKeys.isSubset(of: Set(facts?.values.map(\.key) ?? [])) else { throw SaveError.invalidSave }
    }
}
