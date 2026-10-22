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
        let before = ItemAppearance.advertised(listing)
        var inspected = listing.item
        inspected.inspected = true
        let after = ItemAppearance.owned(inspected)
        #expect(ProductPhoto.scene(family: "controller", identity: before.identity) == ProductPhoto.scene(family: "controller", identity: after.identity))
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

extension ItemAppearanceTests {
    @Test func photographyComesFromSellerNotHiddenTruth() throws {
        let listing = try GameSnapshot.fresh(definitions: SeedContent.load().items).market[0]
        #expect(ItemAppearance.advertised(listing).photoStyle == .casual)
        var item = listing.item
        item.inspected = true
        item.revealedDefects = [.damagedPort]
        #expect(ItemAppearance.owned(item).photoStyle == .inspection)
        #expect(ItemAppearance.owned(item).visibleFindings == [.damagedPort])
    }
}
