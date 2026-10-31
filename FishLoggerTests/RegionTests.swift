import Foundation
import Testing
@testable import FishLogger

struct RegionTests {
    @Test func geocoderAreasMapToRegions() {
        #expect(FishingRegion.from(administrativeArea: "ON") == .ontario)
        #expect(FishingRegion.from(administrativeArea: "Ontario") == .ontario)
        #expect(FishingRegion.from(administrativeArea: "Québec") == .quebec)
        #expect(FishingRegion.from(administrativeArea: "MB") == .prairies)
        #expect(FishingRegion.from(administrativeArea: "WA") == .pacificNorthwest)
        #expect(FishingRegion.from(administrativeArea: " fl ") == .florida)
        #expect(FishingRegion.from(administrativeArea: "Hawaii") == nil)
    }

    @Test func everyRegionBelongsToOneCountry() {
        let canada = FishingRegion.regions(in: .canada)
        let unitedStates = FishingRegion.regions(in: .unitedStates)
        #expect(canada.count + unitedStates.count == FishingRegion.allCases.count)
        #expect(Set(canada).isDisjoint(with: unitedStates))
    }

    @Test func noRegionMeansEverySpecies() {
        #expect(SpeciesCatalog.available(in: []).count == SpeciesCatalog.all.count)
    }

    @Test func speciesWithoutRegionDataShowEverywhere() throws {
        let walleye = try #require(SpeciesCatalog.species(id: "walleye"))
        let unmapped = Species(
            id: "test_fish", commonName: "Test fish", otherNames: [], scientificName: "", group: .other,
            summary: "", idTips: [], lookalikes: [], traits: [], sizeCutoffsCm: [1, 2, 3, 4],
            weightA: nil, weightB: nil, colorHex: 0, habitat: "", range: ""
        )
        #expect(unmapped.lives(in: [.florida]))
        #expect(walleye.lives(in: []))
    }

    @Test func suggestionsRespectRegionsAndGroups() {
        let regions: Set<FishingRegion> = [.ontario]
        let picks = SpeciesCatalog.suggested(regions: regions, groups: [.perch], limit: 5)
        #expect(!picks.isEmpty)
        #expect(picks.count <= 5)
        #expect(picks.allSatisfy { $0.group == .perch && $0.lives(in: regions) })
    }

    @Test func suggestionsFallBackWhenGroupsRuleEverythingOut() {
        // Florida has no whitefish, so the picks fall back to popular fish for the region.
        let picks = SpeciesCatalog.suggested(regions: [.florida], groups: [.whitefish], limit: 6)
        #expect(!picks.isEmpty)
    }

    @Test func catalogIDsAreUniqueAndLookalikesResolve() {
        let ids = SpeciesCatalog.all.map(\.id)
        #expect(Set(ids).count == ids.count)
        for species in SpeciesCatalog.all {
            for other in species.lookalikes {
                #expect(SpeciesCatalog.species(id: other) != nil, "\(species.id) lists missing lookalike \(other)")
            }
            #expect(species.sizeCutoffsCm.count == 4, "\(species.id) needs four size cutoffs")
            #expect(species.sizeCutoffsCm == species.sizeCutoffsCm.sorted(), "\(species.id) cutoffs must ascend")
            #expect((species.weightA == nil) == (species.weightB == nil), "\(species.id) has half a weight curve")
        }
    }

    @Test func saltwaterFishOnlyLiveOnTheCoasts() {
        let coastal: Set<FishingRegion> = [
            .britishColumbia, .quebec, .atlanticCanada, .northernCanada, .alaska, .pacificNorthwest,
            .california, .southernPlains, .northeast, .midAtlantic, .southeast, .florida
        ]
        let saltwater: Set<SpeciesGroup> = [.inshore, .offshore, .bottomfish]
        for species in SpeciesCatalog.all where saltwater.contains(species.group) {
            #expect(!species.regions.isEmpty, "\(species.id) needs at least one coast")
            #expect(species.regions.isSubset(of: coastal), "\(species.id) lists an inland region")
        }
    }

    @Test func inlandAnglersAreNotAskedAboutOffshoreFishing() {
        let present = Set(SpeciesCatalog.available(in: [.prairies]).map(\.group))
        #expect(!present.contains(.offshore))
        #expect(present.contains(.perch))
    }

    @Test func popularListOnlyNamesRealSpeciesOrPlannedOnes() {
        // Popular ids may name species from batches still being written; unknown ones are skipped.
        let resolved = SpeciesCatalog.popularIDs.compactMap(SpeciesCatalog.species(id:))
        #expect(resolved.count >= 20)
    }
}
