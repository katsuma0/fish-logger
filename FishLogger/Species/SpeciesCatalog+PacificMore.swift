import Foundation

// More saltwater fish of the Pacific coast, Alaska to southern California. Thresher sizes are fork length, the rest total length; no weights, as no length-weight relationship could be confirmed for this batch.
extension SpeciesCatalog {
    static let pacificMoreSpecies: [Species] = [

        // MARK: Bottomfish

        Species(
            id: "copper_rockfish",
            commonName: "Copper rockfish",
            otherNames: ["Copper", "Whitebelly rockfish", "Sébaste cuivré"],
            scientificName: "Sebastes caurinus",
            group: .bottomfish,
            summary: "Common nearshore rockfish of shallow reefs and kelp, caught on jigs, swimbaits and bait from Alaska to Baja California. Like all rockfish, it is closed to retention in Puget Sound.",
            idTips: [
                "Pale or white stripe along the rear two-thirds of the lateral line.",
                "No dense orange-brown spots on the head; a quillback has them.",
                "No pinkish white blotches on the back; a gopher rockfish has them."
            ],
            lookalikes: ["quillback_rockfish", "gopher_rockfish"],
            traits: [.spinyDorsal, .darkMottling, .goldenColor],
            sizeCutoffsCm: [25, 33, 40, 48],
            weightA: nil,
            weightB: nil,
            colorHex: 0xB87050,
            habitat: "Shallow rocky reefs, kelp beds and rock piles, mostly shallower than 50 m.",
            range: "Gulf of Alaska to central Baja California, common in nearshore water along most of the coast.",
            regions: [.britishColumbia, .alaska, .pacificNorthwest, .california]
        ),
        Species(
            id: "quillback_rockfish",
            commonName: "Quillback rockfish",
            otherNames: ["Quillback", "Sébaste à dos épineux"],
            scientificName: "Sebastes maliger",
            group: .bottomfish,
            summary: "Slow-growing rockfish of rocky reefs, named for its tall, spiky dorsal fin. Like all rockfish, it is closed to retention in Puget Sound.",
            idTips: [
                "Tall, deeply notched spiny dorsal fin with a pale yellow to orange front.",
                "Small orange-brown spots on the pale head and front of the body.",
                "No pale stripe along the rear lateral line; a copper rockfish has one."
            ],
            lookalikes: ["copper_rockfish"],
            traits: [.spinyDorsal, .darkSpotsLightBody, .darkMottling],
            sizeCutoffsCm: [25, 32, 38, 45],
            weightA: nil,
            weightB: nil,
            colorHex: 0x785820,
            habitat: "Rocky reefs, boulder fields and ledges, often close to crevices and sponge beds.",
            range: "Gulf of Alaska to California, most common from southeast Alaska to northern California.",
            regions: [.britishColumbia, .alaska, .pacificNorthwest, .california]
        ),
        Species(
            id: "dusky_rockfish",
            commonName: "Dusky rockfish",
            otherNames: ["Dusky", "Light dusky rockfish"],
            scientificName: "Sebastes variabilis",
            group: .bottomfish,
            summary: "Schooling rockfish of offshore banks in Alaska, often caught on jigs along with black rockfish. The darker nearshore form was split off as the dark rockfish in 2004.",
            idTips: [
                "Greenish brown body; a black rockfish is dark grey to black above.",
                "Fins tinged pink or orange; a black rockfish's fins are dark.",
                "Whitish belly; a dark rockfish is blue-black all over."
            ],
            lookalikes: ["black_rockfish"],
            traits: [.spinyDorsal, .squareTail, .darkMottling],
            sizeCutoffsCm: [30, 38, 45, 52],
            weightA: nil,
            weightB: nil,
            colorHex: 0x744C3C,
            habitat: "Rocky banks and gravel bottoms toward the edge of the shelf, often schooling well off the bottom.",
            range: "Bering Sea and the Aleutian Islands through the Gulf of Alaska, and rarely south to BC.",
            regions: [.alaska]
        ),
        Species(
            id: "yellowtail_rockfish",
            commonName: "Yellowtail rockfish",
            otherNames: ["Yellowtail", "Sébaste à queue jaune"],
            scientificName: "Sebastes flavidus",
            group: .bottomfish,
            summary: "Schooling rockfish that feeds in mid-water over reefs and pinnacles, and a mainstay of jig and fly fishing from northern California to Alaska.",
            idTips: [
                "Yellow-green tail and fins; a black rockfish's are dark grey.",
                "Row of pale blotches under the dorsal fin on an olive-brown back.",
                "Reddish-brown flecks on the side scales; a black rockfish has none."
            ],
            lookalikes: ["black_rockfish"],
            traits: [.torpedoBody, .spinyDorsal, .lightSpotsDarkBody],
            sizeCutoffsCm: [30, 38, 46, 54],
            weightA: nil,
            weightB: nil,
            colorHex: 0x708C4C,
            habitat: "Mid-water over rocky reefs and pinnacles, often in large schools near the surface or well off the bottom.",
            range: "Aleutian Islands to southern California, most common from northern California to BC.",
            regions: [.britishColumbia, .alaska, .pacificNorthwest, .california]
        ),
        Species(
            id: "canary_rockfish",
            commonName: "Canary rockfish",
            otherNames: ["Canary", "Sébaste canari"],
            scientificName: "Sebastes pinniger",
            group: .bottomfish,
            summary: "Bright orange rockfish of deeper reefs that often schools well off the bottom. Once overfished, the US coastal stock was declared rebuilt in 2015.",
            idTips: [
                "Smooth underside of the lower jaw; a vermilion's is rough and scaly.",
                "Three orange stripes across the head and a grey zone along the lateral line.",
                "No raspy ridges on top of the head; a yelloweye has them."
            ],
            lookalikes: ["vermilion_rockfish", "yelloweye_rockfish"],
            traits: [.spinyDorsal, .squareTail, .darkMottling],
            sizeCutoffsCm: [33, 42, 50, 60],
            weightA: nil,
            weightB: nil,
            colorHex: 0xB87834,
            habitat: "Rocky reefs and boulder fields, mostly 50 to 250 m deep; young fish live shallower.",
            range: "Gulf of Alaska to northern Baja California, most common from central California to BC.",
            regions: [.britishColumbia, .pacificNorthwest, .california]
        ),
        Species(
            id: "blue_rockfish",
            commonName: "Blue rockfish",
            otherNames: ["Blue", "Priestfish"],
            scientificName: "Sebastes mystinus",
            group: .bottomfish,
            summary: "Small-mouthed, schooling rockfish of kelp beds and shallow reefs that feeds on plankton and jellies. In 2015 the deacon rockfish, common from northern California north, was split from it as a separate species.",
            idTips: [
                "Small mouth, the jaw ending below mid-eye; a black rockfish's reaches the rear of the eye.",
                "Plain spiny dorsal fin; a black rockfish's has dark spots.",
                "Blotchy blue-grey mottling on the sides; a deacon's sides are more even."
            ],
            lookalikes: ["black_rockfish"],
            traits: [.spinyDorsal, .squareTail, .darkMottling],
            sizeCutoffsCm: [23, 28, 34, 40],
            weightA: nil,
            weightB: nil,
            colorHex: 0x345C84,
            habitat: "Kelp beds and shallow rocky reefs, often schooling in mid-water from near the surface to about 90 m.",
            range: "Northern Baja California to Oregon, most common in central California.",
            regions: [.pacificNorthwest, .california]
        ),
        Species(
            id: "gopher_rockfish",
            commonName: "Gopher rockfish",
            otherNames: ["Gopher"],
            scientificName: "Sebastes carnatus",
            group: .bottomfish,
            summary: "Small, territorial rockfish of shallow reefs and kelp, and a staple of light-tackle reef fishing in central California.",
            idTips: [
                "Olive brown to dark brown with pinkish white blotches on the back and sides.",
                "Black-and-yellow rockfish share its shape but are black with yellow blotches.",
                "No pale stripe along the rear lateral line; a copper rockfish has one."
            ],
            lookalikes: ["copper_rockfish"],
            traits: [.spinyDorsal, .lightSpotsDarkBody, .darkMottling],
            sizeCutoffsCm: [20, 25, 30, 35],
            weightA: nil,
            weightB: nil,
            colorHex: 0x58583C,
            habitat: "Shallow rocky reefs and kelp beds, usually on the bottom among rocks and crevices shallower than 40 m.",
            range: "Southern Oregon to central Baja California, most common in central California.",
            regions: [.california]
        ),
        Species(
            id: "bocaccio",
            commonName: "Bocaccio",
            otherNames: ["Salmon grouper", "Rock salmon"],
            scientificName: "Sebastes paucispinis",
            group: .bottomfish,
            summary: "Big-mouthed rockfish of deep reefs that recovered off California after years of overfishing. The Puget Sound population is listed as endangered under the US Endangered Species Act.",
            idTips: [
                "Huge mouth reaching past the eye, with a jutting lower jaw.",
                "Long, slim body; most rockfish are deeper and stockier.",
                "Young fish are light bronze with small brown spots on the sides."
            ],
            lookalikes: [],
            traits: [.torpedoBody, .largeMouth, .spinyDorsal],
            sizeCutoffsCm: [40, 52, 65, 78],
            weightA: nil,
            weightB: nil,
            colorHex: 0x884030,
            habitat: "Rocky reefs and nearby mud and sand, mostly 50 to 250 m deep; young fish live in kelp and on shallow reefs.",
            range: "Gulf of Alaska to central Baja California, most common from Oregon to southern California.",
            regions: [.pacificNorthwest, .california]
        ),
        Species(
            id: "sablefish",
            commonName: "Sablefish",
            otherNames: ["Black cod", "Butterfish", "Morue charbonnière"],
            scientificName: "Anoplopoma fimbria",
            group: .bottomfish,
            summary: "Deep-water fish prized for its rich white flesh, sold as black cod though it is not a cod. Anglers reach it with heavy gear on long drops; young fish also come into shallow bays and inlets.",
            idTips: [
                "Two widely separated dorsal fins and no chin whisker.",
                "Slate black to greenish grey back over a paler grey belly.",
                "Pacific cod have three dorsal fins; lingcod have one long, notched fin."
            ],
            lookalikes: ["pacific_cod", "lingcod"],
            traits: [.torpedoBody, .twoSeparateDorsals, .forkedTail],
            sizeCutoffsCm: [45, 58, 72, 88],
            weightA: nil,
            weightB: nil,
            colorHex: 0x385C58,
            habitat: "Mud and other soft bottoms of the continental slope, mostly 300 to 1,000 m deep; young fish use shallow bays and inlets.",
            range: "Baja California to the Bering Sea and across to Japan, most common from Oregon to Alaska.",
            regions: [.britishColumbia, .alaska, .pacificNorthwest, .california]
        ),
        Species(
            id: "ocean_whitefish",
            commonName: "Ocean whitefish",
            otherNames: ["Whitefish"],
            scientificName: "Caulolatilus princeps",
            group: .bottomfish,
            summary: "Tilefish of rocky reefs and kelp in southern California, often caught alongside rockfish and sheephead. Not related to freshwater whitefish.",
            idTips: [
                "One long, unnotched dorsal fin and a long anal fin.",
                "Small mouth and a long, slim body with a rounded head.",
                "Plain tan to yellowish brown, with no bars or spots."
            ],
            lookalikes: [],
            traits: [.torpedoBody, .smallMouth, .longDorsalFin],
            sizeCutoffsCm: [30, 38, 46, 56],
            weightA: nil,
            weightB: nil,
            colorHex: 0xAC785C,
            habitat: "Rocky reefs, kelp edges and nearby sand, from shallow water to about 120 m.",
            range: "Central California to Peru, but common only from southern California south.",
            regions: [.california]
        ),

        // MARK: Inshore

        Species(
            id: "starry_flounder",
            commonName: "Starry flounder",
            otherNames: ["Starry", "Flet étoilé"],
            scientificName: "Platichthys stellatus",
            group: .inshore,
            summary: "Flounder of bays, estuaries and river mouths that often moves well up into fresh water, caught from piers, docks and boats. Its eyes can be on either side.",
            idTips: [
                "Bold black and white to orange bars on the dorsal, anal and tail fins.",
                "Rough, star-shaped scales scattered over the eyed side.",
                "Small mouth; halibut have large mouths with sharp teeth."
            ],
            lookalikes: ["california_halibut", "pacific_halibut"],
            traits: [.eyesOnOneSide, .smallMouth, .verticalBars],
            sizeCutoffsCm: [28, 36, 46, 58],
            weightA: nil,
            weightB: nil,
            colorHex: 0x704C50,
            habitat: "Sand and mud bottoms of bays, estuaries, sloughs and river mouths, often moving into fresh water.",
            range: "Southern California to the Arctic and across to Japan and Korea, most common from central California north.",
            regions: [.britishColumbia, .alaska, .pacificNorthwest, .california]
        ),
        Species(
            id: "redtail_surfperch",
            commonName: "Redtail surfperch",
            otherNames: ["Redtail", "Redtail perch", "Surfperch"],
            scientificName: "Amphistichus rhodoterus",
            group: .inshore,
            summary: "Popular surf fish of sandy beaches from central California to Vancouver Island, caught on sand shrimp, clams and small grubs. Like all surfperch, it gives birth to live young.",
            idTips: [
                "Pink to red tail, anal and pelvic fins.",
                "Brassy or reddish bars on silver sides, with no spots between them.",
                "Most common north of Monterey; barred surfperch are most common farther south."
            ],
            lookalikes: ["barred_surfperch"],
            traits: [.deepFlatBody, .smallMouth, .forkedTail, .verticalBars],
            sizeCutoffsCm: [20, 26, 31, 36],
            weightA: nil,
            weightB: nil,
            colorHex: 0xA04C54,
            habitat: "Sandy surf zones of open beaches, near jetties and in the lower parts of bays.",
            range: "Vancouver Island to central California, most common from northern California north.",
            regions: [.pacificNorthwest, .california]
        ),
        Species(
            id: "striped_seaperch",
            commonName: "Striped seaperch",
            otherNames: ["Striped perch", "Striped surfperch"],
            scientificName: "Embiotoca lateralis",
            group: .inshore,
            summary: "Colourful seaperch of rocky shores, kelp and pilings, often caught from jetties, docks and piers on small baits. Like all surfperch, it gives birth to live young.",
            idTips: [
                "Bright blue and copper-orange stripes along the sides.",
                "Blue spots and wavy lines on the head and gill cover.",
                "No dark bar on mid-side or tall dorsal point, unlike a pile perch."
            ],
            lookalikes: ["pile_perch"],
            traits: [.deepFlatBody, .smallMouth, .forkedTail, .pinkOrRedStripe],
            sizeCutoffsCm: [18, 23, 28, 33],
            weightA: nil,
            weightB: nil,
            colorHex: 0x287C84,
            habitat: "Rocky shores, kelp beds, eelgrass, jetties and pilings, usually shallower than 20 m.",
            range: "Southeast Alaska to northern Baja California, most common from central California to BC.",
            regions: [.britishColumbia, .pacificNorthwest, .california]
        ),
        Species(
            id: "pile_perch",
            commonName: "Pile perch",
            otherNames: ["Pile surfperch"],
            scientificName: "Phanerodon vacca",
            group: .inshore,
            summary: "Large, silvery seaperch of piers, pilings and rocky reefs that crushes mussels and crabs with strong teeth in its throat. Like all surfperch, it gives birth to live young.",
            idTips: [
                "Dark bar on the middle of the side, below the soft dorsal fin.",
                "Soft dorsal fin rises to a tall point at the front.",
                "Plain silver to grey sides; a striped seaperch has blue and orange stripes."
            ],
            lookalikes: ["striped_seaperch"],
            traits: [.deepFlatBody, .smallMouth, .forkedTail, .silverColor],
            sizeCutoffsCm: [18, 24, 30, 36],
            weightA: nil,
            weightB: nil,
            colorHex: 0xA07898,
            habitat: "Piers, pilings, breakwaters, kelp and rocky reefs, in bays and along the open coast.",
            range: "Southeast Alaska to Baja California, most common from central California to BC.",
            regions: [.britishColumbia, .pacificNorthwest, .california]
        ),
        Species(
            id: "pacific_chub_mackerel",
            commonName: "Pacific chub mackerel",
            otherNames: ["Pacific mackerel", "Chub mackerel"],
            scientificName: "Scomber japonicus",
            group: .inshore,
            summary: "Fast, schooling mackerel that crowds piers, harbours and bait schools in southern California, and good live bait for bigger fish.",
            idTips: [
                "Wavy dark lines across a green to blue back.",
                "Dorsal fins set well apart; a bonito's are close together.",
                "No bony scutes along the side; a jack mackerel has them."
            ],
            lookalikes: ["pacific_bonito"],
            traits: [.torpedoBody, .twoSeparateDorsals, .forkedTail, .finlets],
            sizeCutoffsCm: [22, 30, 37, 45],
            weightA: nil,
            weightB: nil,
            colorHex: 0x3C786C,
            habitat: "Open coastal water near the surface, often around piers, harbours, kelp beds and bait schools.",
            range: "Mostly southern California and Mexico, moving north to Oregon and beyond in warm years.",
            regions: [.california]
        ),
        Species(
            id: "pacific_barracuda",
            commonName: "Pacific barracuda",
            otherNames: ["California barracuda", "Barracuda"],
            scientificName: "Sphyraena argentea",
            group: .inshore,
            summary: "Slim, toothy predator of southern California's kelp beds and open coast, caught on jigs, trolled lures and live bait, mostly in spring and summer.",
            idTips: [
                "Long, slim body with a pointed, jutting lower jaw and fang-like teeth.",
                "No dark bars or black blotches; a great barracuda has both.",
                "Brownish to blue-grey back over bright silver sides."
            ],
            lookalikes: ["great_barracuda"],
            traits: [.torpedoBody, .longToothySnout, .twoSeparateDorsals, .forkedTail, .silverColor],
            sizeCutoffsCm: [71, 80, 90, 100],
            weightA: nil,
            weightB: nil,
            colorHex: 0x28708C,
            habitat: "Open coastal water near the surface, along kelp beds, reefs and sandy shores.",
            range: "Southern California to southern Baja California, rarely north of Point Conception except in warm years.",
            regions: [.california]
        ),
        Species(
            id: "california_corbina",
            commonName: "California corbina",
            otherNames: ["Corbina", "Corvina"],
            scientificName: "Menticirrhus undulatus",
            group: .inshore,
            summary: "Prized surf fish that roots for sand crabs in the wash of sandy beaches, often in very shallow water. Wary and hard to hook, it is best known from southern California.",
            idTips: [
                "One short, fleshy barbel at the tip of the lower jaw.",
                "Grey with faint wavy lines at most; no yellow fins or black pectoral spot.",
                "Long, round body with an underslung mouth below a blunt snout."
            ],
            lookalikes: [],
            traits: [.torpedoBody, .spinyDorsal, .barbels],
            sizeCutoffsCm: [33, 41, 50, 60],
            weightA: nil,
            weightB: nil,
            colorHex: 0x887898,
            habitat: "Sandy beaches and the surf zone, feeding in the wash; also shallow bays.",
            range: "Point Conception to the Gulf of California, most common in southern California.",
            regions: [.california]
        ),
        Species(
            id: "spotted_bay_bass",
            commonName: "Spotted sand bass",
            otherNames: ["Spotted bay bass", "Bay bass", "Spotty"],
            scientificName: "Paralabrax maculatofasciatus",
            group: .inshore,
            summary: "Bass of eelgrass beds, docks and channels in southern California's bays and harbours, popular with kayak and light-tackle anglers.",
            idTips: [
                "Small dark spots cover the head, body and fins.",
                "No pale checkerboard on the back; a kelp bass has one.",
                "Lives mostly in bays and harbours, often over eelgrass."
            ],
            lookalikes: ["kelp_bass", "barred_sand_bass"],
            traits: [.spinyDorsal, .squareTail, .darkSpotsLightBody],
            sizeCutoffsCm: [30, 36, 42, 48],
            weightA: nil,
            weightB: nil,
            colorHex: 0x5C5824,
            habitat: "Eelgrass beds, docks, rock jetties and channels in shallow bays and harbours.",
            range: "Southern California to Mexico, most common in bays from Long Beach to San Diego.",
            regions: [.california]
        ),
        Species(
            id: "leopard_shark",
            commonName: "Leopard shark",
            otherNames: ["Leopard"],
            scientificName: "Triakis semifasciata",
            group: .inshore,
            summary: "Slim, boldly marked shark of shallow bays, sloughs and beaches, often caught from shore and piers in California. Harmless to people, and slow to mature.",
            idTips: [
                "Bold black saddles across the back and black spots on the sides.",
                "Smoothhound sharks are plain grey or brown, with no saddles or spots.",
                "No spine in front of the dorsal fins; a spiny dogfish has one."
            ],
            lookalikes: [],
            traits: [.torpedoBody, .twoSeparateDorsals, .verticalBars, .darkSpotsLightBody],
            sizeCutoffsCm: [90, 110, 130, 150],
            weightA: nil,
            weightB: nil,
            colorHex: 0xA07C78,
            habitat: "Shallow bays, estuaries, sloughs and sandy beaches, mostly in water less than 20 m deep.",
            range: "Oregon to the Gulf of California, most common in California.",
            regions: [.california]
        ),

        // MARK: Offshore

        Species(
            id: "common_thresher_shark",
            commonName: "Common thresher shark",
            otherNames: ["Thresher", "Thresher shark", "Fox shark"],
            scientificName: "Alopias vulpinus",
            group: .offshore,
            summary: "Big shark that stuns small fish with sweeps of its huge tail, and is often hooked in the tail on trolled baits. Size classes use fork length.",
            idTips: [
                "Upper tail lobe nearly as long as the rest of the shark.",
                "White of the belly reaches up over the pectoral fin base.",
                "Modest eyes; a bigeye thresher's are huge and reach the top of the head."
            ],
            lookalikes: [],
            traits: [.torpedoBody, .twoSeparateDorsals, .forkedTail],
            sizeCutoffsCm: [120, 150, 180, 210],
            weightA: nil,
            weightB: nil,
            colorHex: 0x785884,
            habitat: "Open ocean and coastal water over the shelf, often close to shore when chasing bait in summer.",
            range: "Temperate and warm seas worldwide, including southern California and the Atlantic coast from New England to Virginia.",
            regions: [.california, .northeast, .midAtlantic]
        ),
        Species(
            id: "salmon_shark",
            commonName: "Salmon shark",
            otherNames: ["Requin-saumon"],
            scientificName: "Lamna ditropis",
            group: .offshore,
            summary: "Stocky, warm-bodied relative of the white shark and porbeagle that hunts salmon in cold northern water, and a summer sport target in Alaska.",
            idTips: [
                "Dark blotches scattered on the white belly; a white shark's belly is plain.",
                "Short, cone-shaped snout and a crescent tail with keels at its base.",
                "Stocky and heavy; a blue shark is slim, with long pectoral fins."
            ],
            lookalikes: ["blue_shark"],
            traits: [.torpedoBody, .twoSeparateDorsals, .forkedTail, .darkMottling],
            sizeCutoffsCm: [170, 200, 230, 260],
            weightA: nil,
            weightB: nil,
            colorHex: 0x205C78,
            habitat: "Cold open water and coastal sounds, often near salmon runs in summer.",
            range: "North Pacific from Japan to Alaska and south to Baja California, most common in the Gulf of Alaska.",
            regions: [.alaska]
        ),
    ]
}
