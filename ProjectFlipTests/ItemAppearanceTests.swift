import Testing
@testable import ProjectFlip

struct ItemAppearanceTests {
    @Test func photosDependOnClaimsAndIdentityNotHiddenConditionOrFaults() throws {
        let state = try GameSnapshot.fresh(definitions: SeedContent.load().items)
        let listing = state.market[0]
        let differentTruth = ItemInstance(id: listing.item.id, definitionID: listing.item.definitionID, condition: 10, hiddenDefects: [.batteryWear, .damagedPort])
        let other = MarketplaceListing(id: listing.id, item: differentTruth, seller: listing.seller, askingPrice: listing.askingPrice, reservationPrice: listing.reservationPrice, claimedCondition: listing.claimedCondition, descriptionIntent: listing.descriptionIntent, createdAt: listing.createdAt)
        #expect(ItemAppearance.advertised(listing) == .advertised(other))
        #expect(ItemAppearance.advertised(listing).visibleFindings.isEmpty)
    }

    @Test func wearAndVisibleFaultsFollowEarnedEvidenceAndRepair() {
        var item = ItemInstance(id: ItemID("photo"), definitionID: "cameras-0", condition: 40, hiddenDefects: [.lensFungus, .cameraBatteryWear], revealedDefects: [.lensFungus, .cameraBatteryWear])
        #expect(ItemAppearance.owned(item).wear == .unverified)
        #expect(ItemAppearance.owned(item).visibleFindings.isEmpty)
        item.inspected = true
        #expect(ItemAppearance.owned(item).wear == .poor)
        #expect(ItemAppearance.owned(item).visibleFindings == [.lensFungus])
        #expect(ItemAppearance.owned(item, showFindings: false).visibleFindings.isEmpty)
        item.repairedDefects = [.lensFungus]
        #expect(ItemAppearance.owned(item).visibleFindings.isEmpty)
    }
}
