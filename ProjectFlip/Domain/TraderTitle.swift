/// Stable installation title IDs keep existing career selections valid.
/// Recognition is cosmetic; pricing and simulation never read these titles.
struct TraderTitle: Identifiable, Equatable {
    let id: Int
    let key: String
    var clientID: String?

    static func earned(in state: GameSnapshot) -> [Self] {
        let career = state.career.tier(knowledge: state.inspectionKnowledge)
        return CareerTier.allCases.filter { $0.rawValue <= career.rawValue }.map {
            Self(id: $0.rawValue, key: $0.key)
        } + ClientDefinition.all.filter { state.clients.completed[$0.id, default: 0] >= $0.requests.count }.map {
            Self(id: $0.titleID, key: $0.honorKey, clientID: $0.id)
        }
    }
}
