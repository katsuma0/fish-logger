import Foundation

// Freshwater game fish still missing: the ruddy bowfin, shadow bass, skipjack herring, northern and Bear Lake whitefish, roundtail chub and three Florida exotics. No weights, as no length-weight relationship could be confirmed for this batch.
extension SpeciesCatalog {
    static let freshwaterGapSpecies: [Species] = [

        // MARK: Bowfin

        Species(
            id: "ruddy_bowfin",
            commonName: "Ruddy bowfin",
            otherNames: ["Bowfin", "Mudfish", "Grinnel"],
            scientificName: "Amia calva",
            group: .ancient,
            summary: "Air-breathing bowfin of the Atlantic and eastern Gulf coastal plain, split from the inland eyetail bowfin in 2022. Hits lures and cut bait hard in swamps and blackwater rivers.",
            idTips: [
                "Short anal fin; a snakehead's is long, nearly matching its dorsal.",
                "Only bowfin in Gulf rivers east of the Pearl and Atlantic rivers from Virginia south.",
                "Reddish brown with a weak tail eyespot; an eyetail bowfin's is bold."
            ],
            lookalikes: ["bowfin", "bullseye_snakehead", "northern_snakehead"],
            traits: [.torpedoBody, .largeMouth, .longDorsalFin, .darkMottling, .roundedTail],
            sizeCutoffsCm: [40, 50, 60, 70],
            weightA: nil,
            weightB: nil,
            colorHex: 0x884014,
            habitat: "Swamps, blackwater rivers, oxbows and weedy lakes, often in warm, low-oxygen water.",
            range: "Atlantic coastal plain from Virginia to Florida, and Gulf drainages from the Pearl River east.",
            regions: [.midAtlantic, .southeast, .florida]
        ),

        // MARK: Sunfish

        Species(
            id: "shadow_bass",
            commonName: "Shadow bass",
            otherNames: ["Goggle-eye", "Red eye"],
            scientificName: "Ambloplites ariommus",
            group: .sunfish,
            summary: "Mottled cousin of the rock bass in clear, rocky streams of the Gulf states and southern Ozarks. Bites readily on small jigs, spinners and crayfish baits.",
            idTips: [
                "Irregular dark blotches and marbling; a rock bass has spots in neat rows.",
                "Six or seven anal spines; a warmouth has three.",
                "Large blotches, not the small, scattered freckles of an Ozark bass."
            ],
            lookalikes: ["rock_bass", "ozark_bass", "warmouth"],
            traits: [.deepFlatBody, .spinyDorsal, .darkMottling, .forkedTail],
            sizeCutoffsCm: [12, 16, 20, 24],
            weightA: nil,
            weightB: nil,
            colorHex: 0x8A4A6A,
            habitat: "Rocky pools, root wads and undercut banks of clear, flowing streams and small rivers.",
            range: "Gulf drainages from the Apalachicola west to Louisiana, and Ozark streams of southern Missouri and northern Arkansas.",
            regions: [.ohioValley, .southeast, .florida]
        ),

        // MARK: Whitefish

        Species(
            id: "bonneville_cisco",
            commonName: "Bonneville cisco",
            otherNames: ["Cisco"],
            scientificName: "Prosopium gemmifer",
            group: .whitefish,
            summary: "Small whitefish found only in Bear Lake on the Utah and Idaho border, and key food for its trout. Anglers dip-net spawning schools along rocky shores in January.",
            idTips: [
                "Found only in Bear Lake, where no true cisco lives.",
                "Small, usually under 20 cm; mountain whitefish grow much larger.",
                "Plain silver sides and a pale green back, with no spots."
            ],
            lookalikes: ["mountain_whitefish", "cisco"],
            traits: [.adiposeFin, .torpedoBody, .smallMouth, .silverColor, .forkedTail],
            sizeCutoffsCm: [13, 16, 18, 20],
            weightA: nil,
            weightB: nil,
            colorHex: 0x64946C,
            habitat: "Open water of a deep, cold lake; spawns over rocky shoals near shore in winter.",
            range: "Bear Lake on the Utah and Idaho border, and nowhere else.",
            regions: [.pacificNorthwest, .mountainWest]
        ),
        Species(
            id: "humpback_whitefish",
            commonName: "Humpback whitefish",
            otherNames: ["Humpback", "Alaska whitefish"],
            scientificName: "Coregonus pidschian",
            group: .whitefish,
            summary: "Hump-backed whitefish of Alaska and northwestern Canada, important in northern subsistence fisheries. Takes small flies and jigs, both in open water and through the ice.",
            idTips: [
                "Small mouth under an overhanging snout; inconnu and cisco jaws reach the snout tip.",
                "Longer snout and longer gill rakers than a broad whitefish.",
                "About 19 to 25 gill rakers; a lake whitefish usually has more."
            ],
            lookalikes: ["lake_whitefish", "broad_whitefish", "inconnu", "cisco"],
            traits: [.adiposeFin, .smallMouth, .silverColor, .forkedTail],
            sizeCutoffsCm: [28, 35, 42, 48],
            weightA: nil,
            weightB: nil,
            colorHex: 0x7C78B8,
            habitat: "Large rivers, lakes and brackish coastal lagoons; many run upriver to spawn in fall.",
            range: "Rivers, lakes and coasts of Alaska and northwestern Canada east to the Mackenzie River.",
            regions: [.northernCanada, .alaska]
        ),
        Species(
            id: "broad_whitefish",
            commonName: "Broad whitefish",
            otherNames: ["Broad", "Corégone tschir"],
            scientificName: "Coregonus nasus",
            group: .whitefish,
            summary: "Large, deep-bodied whitefish of Arctic rivers and coastal lakes, prized as food across the North. Feeds on the bottom and is caught more often in nets than on hook and line.",
            idTips: [
                "Short, blunt snout and deep head; humpback and lake whitefish have longer snouts.",
                "Shorter gill rakers and a bigger, deeper body than a humpback whitefish.",
                "Tiny, slightly down-turned mouth, not the big, jutting lower jaw of an inconnu."
            ],
            lookalikes: ["humpback_whitefish", "lake_whitefish", "inconnu"],
            traits: [.adiposeFin, .deepFlatBody, .smallMouth, .silverColor, .forkedTail],
            sizeCutoffsCm: [38, 48, 56, 64],
            weightA: nil,
            weightB: nil,
            colorHex: 0x48541C,
            habitat: "Slow rivers, delta lakes and brackish coastal waters, moving between them with the seasons.",
            range: "Arctic and Bering Sea drainages from Alaska east through the Yukon and Northwest Territories to western Nunavut.",
            regions: [.northernCanada, .alaska]
        ),

        // MARK: Everything else

        Species(
            id: "skipjack_herring",
            commonName: "Skipjack herring",
            otherNames: ["Skipjack", "Skipjack shad", "Blue herring"],
            scientificName: "Alosa chrysochloris",
            group: .other,
            summary: "Slender, leaping herring of big rivers that schools below dams to chase minnows and shad. Fights hard on light tackle and is a favourite cut bait for catfish and stripers.",
            idTips: [
                "Lower jaw juts far past the tip of the snout.",
                "Saw-edged belly; goldeye and mooneye have a smooth, fleshy keel.",
                "Gulf and Mississippi basin fish; hickory shad live only on the Atlantic coast."
            ],
            lookalikes: ["goldeye", "mooneye", "hickory_shad"],
            traits: [.torpedoBody, .silverColor, .forkedTail],
            sizeCutoffsCm: [25, 32, 38, 44],
            weightA: nil,
            weightB: nil,
            colorHex: 0x128E9E,
            habitat: "Swift tailwaters below dams and open water of large rivers and reservoirs.",
            range: "Mississippi, Ohio and lower Missouri rivers, and Gulf drainages from the Florida panhandle to central Texas.",
            regions: [.southernPlains, .ohioValley, .midAtlantic, .southeast, .florida]
        ),
        Species(
            id: "roundtail_chub",
            commonName: "Roundtail chub",
            otherNames: ["Roundtail", "Verde trout"],
            scientificName: "Gila robusta",
            group: .other,
            summary: "Sleek native minnow of the Colorado River basin that hits flies, spinners and small lures in fast water. Check local rules before keeping one.",
            idTips: [
                "Smaller head and mouth than the long, pike-like head of a Colorado pikeminnow.",
                "Thicker tail stem than the pencil-thin one of a bonytail.",
                "No hump behind the head, unlike a humpback chub."
            ],
            lookalikes: [],
            traits: [.torpedoBody, .silverColor, .forkedTail],
            sizeCutoffsCm: [20, 28, 35, 42],
            weightA: nil,
            weightB: nil,
            colorHex: 0x107C60,
            habitat: "Pools, runs and eddies of warm to cool rivers and large streams, often near boulders or cover.",
            range: "Colorado River basin streams of Wyoming, Colorado, Utah, New Mexico and Arizona.",
            regions: [.mountainWest, .southwest]
        ),

        // MARK: Warm-water exotics

        Species(
            id: "oscar",
            commonName: "Oscar",
            otherNames: ["Velvet cichlid", "Marble cichlid"],
            scientificName: "Astronotus ocellatus",
            group: .other,
            summary: "Big-headed South American cichlid from the aquarium trade, now common in South Florida canals. Hits small lures and live bait, and is good eating.",
            idTips: [
                "Velvety dark body blotched with orange, not the bars of a Mayan cichlid.",
                "Back fin has no deep notch; a peacock bass's is deeply notched.",
                "Orange-ringed black eyespot on the tail; spotted tilapia have none."
            ],
            lookalikes: ["mayan_cichlid", "peacock_bass", "spotted_tilapia"],
            traits: [.deepFlatBody, .spinyDorsal, .roundedTail, .darkMottling, .tailSpot],
            sizeCutoffsCm: [18, 23, 28, 33],
            weightA: nil,
            weightB: nil,
            colorHex: 0xBC3C30,
            habitat: "Warm canals, ponds and marsh edges with plants, rocks or other cover.",
            range: "South Florida, mostly from Lake Okeechobee south; native to South America.",
            regions: [.florida]
        ),
        Species(
            id: "clown_knifefish",
            commonName: "Clown knifefish",
            otherNames: ["Clown featherback", "Featherback", "Knifefish"],
            scientificName: "Chitala ornata",
            group: .other,
            summary: "Big Southeast Asian featherback from the aquarium trade, established in lakes and canals around Palm Beach County. Feeds mostly at night, so anglers do best with live bait after dark.",
            idTips: [
                "Long belly fin runs back and merges with a small tail.",
                "Row of white-ringed black spots along the rear of the body.",
                "Tiny, feather-like back fin and a steep hump behind the head."
            ],
            lookalikes: [],
            traits: [.deepFlatBody, .largeMouth, .darkSpotsLightBody, .silverColor],
            sizeCutoffsCm: [40, 55, 70, 85],
            weightA: nil,
            weightB: nil,
            colorHex: 0xA078BC,
            habitat: "Lakes and canals with docks, fallen trees and thick weeds; hides by day and hunts at night.",
            range: "Mainly Palm Beach County, Florida, with newer reports from Broward and Miami-Dade; native to Southeast Asia.",
            regions: [.florida]
        ),
        Species(
            id: "spotted_tilapia",
            commonName: "Spotted tilapia",
            otherNames: ["Tilapia", "Black mangrove cichlid"],
            scientificName: "Pelmatolapia mariae",
            group: .other,
            summary: "West African cichlid that is now the most common cichlid in many South Florida canals. Takes worms and small baits, and is good eating.",
            idTips: [
                "Four to six big dark blotches along the side; blue tilapia are plain.",
                "No eyespot at the tail base, unlike a Mayan cichlid or oscar.",
                "Dark stripe slants through the eye, plainest on young fish."
            ],
            lookalikes: ["blue_tilapia", "mayan_cichlid", "oscar"],
            traits: [.deepFlatBody, .spinyDorsal, .smallMouth, .darkSpotsLightBody],
            sizeCutoffsCm: [12, 17, 22, 27],
            weightA: nil,
            weightB: nil,
            colorHex: 0x586404,
            habitat: "Canals, ditches, ponds and slow rivers, usually near rocks, roots or other cover.",
            range: "South Florida canals and rivers north to the Caloosahatchee and Indian River; native to West Africa.",
            regions: [.florida]
        ),
    ]
}
