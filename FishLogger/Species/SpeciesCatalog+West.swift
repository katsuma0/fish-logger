import Foundation

// Western trout and salmon, and sea-run fish of both coasts. Weights are nil where no published Ws equation is known.
extension SpeciesCatalog {
    static let westernSpecies: [Species] = [
        Species(
            id: "golden_trout",
            commonName: "Golden trout",
            otherNames: ["California golden trout"],
            scientificName: "Oncorhynchus mykiss aguabonita",
            group: .troutChar,
            summary: "California's state fish, a small and brightly coloured trout of the high Sierra Nevada. Also stocked in alpine lakes across the West, most of them reached only on foot.",
            idTips: [
                "Bright gold sides with a red-orange stripe and a red belly.",
                "About ten dark oval parr marks along each side, even on adults.",
                "Black spots mostly on the dorsal fin, tail, and rear of the back."
            ],
            lookalikes: ["rainbow_trout", "cutthroat_trout"],
            traits: [.adiposeFin, .torpedoBody, .darkSpotsLightBody, .pinkOrRedStripe, .goldenColor],
            sizeCutoffsCm: [18, 25, 33, 40],
            weightA: nil,
            weightB: nil,
            colorHex: 0xA27230,
            habitat: "Cold, clear alpine lakes and small, high meadow streams.",
            range: "Native to the upper Kern River basin in California; stocked in alpine lakes of Wyoming, Montana, Idaho, and Washington.",
            regions: [.pacificNorthwest, .california, .mountainWest]
        ),
        Species(
            id: "apache_trout",
            commonName: "Apache trout",
            otherNames: ["Arizona trout"],
            scientificName: "Oncorhynchus apache",
            group: .troutChar,
            summary: "Arizona's state fish, a native trout of the White Mountains brought back from near extinction. Many of its waters are on White Mountain Apache tribal land, which needs a tribal permit.",
            idTips: [
                "Dark spot in front of and behind the pupil, like a band through the eye.",
                "Yellow-gold body with even, medium dark spots and no pink side stripe.",
                "Dorsal, pelvic, and anal fins tipped white or pale yellow."
            ],
            lookalikes: ["gila_trout", "rainbow_trout"],
            traits: [.adiposeFin, .torpedoBody, .darkSpotsLightBody, .goldenColor],
            sizeCutoffsCm: [15, 23, 30, 38],
            weightA: nil,
            weightB: nil,
            colorHex: 0x847842,
            habitat: "Cold, clear headwater streams and small lakes in high conifer forest.",
            range: "Only the White Mountains of east-central Arizona, in the upper Salt and Little Colorado river basins.",
            regions: [.southwest]
        ),
        Species(
            id: "gila_trout",
            commonName: "Gila trout",
            otherNames: [],
            scientificName: "Oncorhynchus gilae",
            group: .troutChar,
            summary: "Rare native trout of mountain streams in southwestern New Mexico and Arizona, brought back from near extinction. Open to fishing in some waters under special rules.",
            idTips: [
                "Small, dense black spots, finer than an Apache trout's, mostly above the lateral line.",
                "Brassy gold sides that turn copper on the gill cover.",
                "Faint yellow mark under the jaw; fins tipped white or pale yellow."
            ],
            lookalikes: ["apache_trout", "rainbow_trout"],
            traits: [.adiposeFin, .torpedoBody, .darkSpotsLightBody, .goldenColor],
            sizeCutoffsCm: [13, 20, 26, 33],
            weightA: nil,
            weightB: nil,
            colorHex: 0xA8604C,
            habitat: "Small, cold headwater streams in pine and fir forest, often in steep canyons.",
            range: "Headwaters of the Gila and San Francisco rivers in southwestern New Mexico, with restored populations in a few Arizona streams.",
            regions: [.southwest]
        ),
        Species(
            id: "tiger_trout",
            commonName: "Tiger trout",
            otherNames: [],
            scientificName: "Salmo trutta × Salvelinus fontinalis",
            group: .troutChar,
            summary: "Sterile cross of a brown trout and a brook trout, nearly always from a hatchery. Aggressive and fish-eating, it is stocked in many lakes for sport and to help control unwanted small fish.",
            idTips: [
                "Wavy, maze-like marks over the whole body, not just the back.",
                "Few or no round spots, unlike its brown and brook trout parents.",
                "Tail square or barely forked; a splake's is clearly forked."
            ],
            lookalikes: ["brook_trout", "brown_trout", "splake"],
            traits: [.adiposeFin, .torpedoBody, .darkMottling, .goldenColor, .squareTail],
            sizeCutoffsCm: [25, 35, 45, 55],
            weightA: nil,
            weightB: nil,
            colorHex: 0x9C5A24,
            habitat: "Stocked lakes, reservoirs, and some streams, often hunting small fish along shorelines.",
            range: "Stocked in Utah, Washington, and other states in the West and Northeast; rare wild fish turn up where brown and brook trout spawn together.",
            regions: [.pacificNorthwest, .mountainWest, .northeast]
        ),
        Species(
            id: "chum_salmon",
            commonName: "Chum salmon",
            otherNames: ["Chum", "Dog salmon", "Keta", "Calico salmon", "Saumon kéta"],
            scientificName: "Oncorhynchus keta",
            group: .salmon,
            summary: "Big, hard-pulling Pacific salmon that runs coastal rivers in late summer and fall. Spawning males grow large, dog-like teeth and bold purple calico bars.",
            idTips: [
                "No large black spots on the back or tail.",
                "Spawning fish show purple and olive calico bars down the sides.",
                "White tips on the anal and pelvic fins, clearest on spawning fish."
            ],
            lookalikes: ["coho_salmon", "sockeye_salmon", "chinook_salmon"],
            traits: [.adiposeFin, .torpedoBody, .verticalBars, .silverColor, .forkedTail],
            sizeCutoffsCm: [55, 65, 75, 85],
            weightA: nil,
            weightB: nil,
            colorHex: 0x9A5A8C,
            habitat: "Ocean and coastal waters; spawns in lower rivers and side channels, often close to the sea.",
            range: "Pacific coast rivers from Oregon through BC to western and northern Alaska.",
            regions: [.britishColumbia, .alaska, .pacificNorthwest]
        ),
        Species(
            id: "green_sturgeon",
            commonName: "Green sturgeon",
            otherNames: ["Sturgeon", "Esturgeon vert"],
            scientificName: "Acipenser medirostris",
            group: .ancient,
            summary: "Rare, mostly sea-going sturgeon that spawns in only a few Pacific coast rivers. No retention is allowed, so release any you catch right away.",
            idTips: [
                "Only 23 to 30 plates along each side; a white sturgeon has 38 or more.",
                "Barbels sit closer to the mouth than to the tip of the snout.",
                "Olive to dark green colour; a white sturgeon is grey to brown."
            ],
            lookalikes: ["white_sturgeon"],
            traits: [.torpedoBody, .barbels, .bonyPlates, .forkedTail],
            sizeCutoffsCm: [90, 130, 165, 200],
            weightA: nil,
            weightB: nil,
            colorHex: 0x788460,
            habitat: "Coastal ocean, bays, and estuaries; adults enter large rivers only to spawn.",
            range: "Coastal waters from California to Washington, rarer north to Alaska; spawns mainly in the Sacramento, Klamath, and Rogue rivers.",
            regions: [.pacificNorthwest, .california]
        ),
        Species(
            id: "sacramento_perch",
            commonName: "Sacramento perch",
            otherNames: [],
            scientificName: "Archoplites interruptus",
            group: .sunfish,
            summary: "The only sunfish native west of the Rockies, now nearly gone from its home rivers in California. Most fish caught today come from lakes where it was introduced.",
            idTips: [
                "12 to 14 dorsal spines; a crappie has 5 to 8.",
                "Six or seven uneven dark bars on silvery brown to greenish sides.",
                "Dark spot near the back edge of the gill cover."
            ],
            lookalikes: ["black_crappie", "white_crappie", "rock_bass"],
            traits: [.deepFlatBody, .spinyDorsal, .verticalBars],
            sizeCutoffsCm: [15, 20, 25, 30],
            weightA: nil,
            weightB: nil,
            colorHex: 0x368472,
            habitat: "Lakes, reservoirs, and sloughs with weed beds; handles warm, alkaline water well.",
            range: "Native to California's Central Valley and nearby coastal rivers; now survives mostly in introduced western lakes and reservoirs.",
            regions: [.california]
        ),
        Species(
            id: "round_whitefish",
            commonName: "Round whitefish",
            otherNames: ["Menominee", "Ménomini rond"],
            scientificName: "Prosopium cylindraceum",
            group: .whitefish,
            summary: "Slim, small-mouthed whitefish of cold northern lakes and rivers. Feeds on the bottom and takes small baits and nymphs.",
            idTips: [
                "Slim, nearly round body, much narrower than a lake whitefish.",
                "Small mouth under a short, pointed snout, and no hump behind the head.",
                "Bronze to olive back over plain silver sides; young fish have dark spots."
            ],
            lookalikes: ["lake_whitefish", "mountain_whitefish", "cisco"],
            traits: [.adiposeFin, .torpedoBody, .smallMouth, .silverColor, .forkedTail],
            sizeCutoffsCm: [20, 26, 32, 40],
            weightA: nil,
            weightB: nil,
            colorHex: 0x846C5A,
            habitat: "Cold, clear lakes and rivers, usually over gravel or rocky bottoms.",
            range: "Across northern Canada and Alaska, south to the Great Lakes; rare in New York and New England.",
            regions: [.britishColumbia, .prairies, .ontario, .quebec, .atlanticCanada, .northernCanada, .alaska, .upperMidwest]
        ),
        Species(
            id: "northern_pikeminnow",
            commonName: "Northern pikeminnow",
            otherNames: ["Pikeminnow"],
            scientificName: "Ptychocheilus oregonensis",
            group: .other,
            summary: "Big native minnow of the Northwest that eats young salmon and steelhead. On the Columbia and Snake rivers, a sport reward fishery pays registered anglers for each one 23 cm (9 in) or longer.",
            idTips: [
                "Big mouth reaching back to below the eye, with no teeth in the jaws.",
                "One soft dorsal fin and no adipose fin; a trout has one.",
                "Dark olive back over silver sides and a deeply forked tail."
            ],
            lookalikes: [],
            traits: [.torpedoBody, .silverColor, .forkedTail],
            sizeCutoffsCm: [23, 30, 38, 48],
            weightA: nil,
            weightB: nil,
            colorHex: 0x847E60,
            habitat: "Large rivers, reservoirs, and lakes; big fish gather below dams and near salmon release sites.",
            range: "Native to the Columbia and Fraser basins and nearby coastal rivers, from Oregon, Idaho, and western Montana north through much of BC.",
            regions: [.britishColumbia, .pacificNorthwest, .mountainWest]
        ),
        Species(
            id: "american_shad",
            commonName: "American shad",
            otherNames: ["Shad", "White shad", "Alose savoureuse"],
            scientificName: "Alosa sapidissima",
            group: .other,
            summary: "Big sea-run herring that crowds into coastal rivers in late winter and spring to spawn. Hits small darts and flies and fights hard, with long runs and jumps.",
            idTips: [
                "Lower jaw fits inside the upper; a hickory shad's juts out past it.",
                "Dark spot behind the gill cover, often trailed by a row of fainter spots.",
                "Thin, deep, bright silver body with a sharp, saw-edged belly."
            ],
            lookalikes: ["hickory_shad", "mooneye"],
            traits: [.deepFlatBody, .darkSpotsLightBody, .silverColor, .forkedTail],
            sizeCutoffsCm: [35, 42, 50, 58],
            weightA: nil,
            weightB: nil,
            colorHex: 0x3084B4,
            habitat: "Coastal ocean; enters large rivers to spawn in open, flowing water.",
            range: "Atlantic rivers from the Maritimes to Florida's St. Johns; introduced on the Pacific coast, with big runs in the Columbia and Sacramento.",
            regions: [.atlanticCanada, .pacificNorthwest, .california, .northeast, .midAtlantic, .southeast, .florida]
        ),
        Species(
            id: "hickory_shad",
            commonName: "Hickory shad",
            otherNames: ["Hickory", "Shad"],
            scientificName: "Alosa mediocris",
            group: .other,
            summary: "Smaller, more predatory cousin of the American shad that runs Atlantic coast rivers in late winter and early spring. Strikes small darts and flies hard and jumps often.",
            idTips: [
                "Lower jaw juts well past the upper; an American shad's does not.",
                "Few, short gill rakers; an American shad's are many, long, and fine.",
                "Usually 30 to 45 cm, smaller than most American shad."
            ],
            lookalikes: ["american_shad"],
            traits: [.deepFlatBody, .darkSpotsLightBody, .silverColor, .forkedTail],
            sizeCutoffsCm: [28, 34, 40, 46],
            weightA: nil,
            weightB: nil,
            colorHex: 0x427878,
            habitat: "Coastal waters and bays; spawns in tidal and lower freshwater reaches of rivers.",
            range: "Atlantic coast from New England to northeastern Florida; most spawning runs are from the Chesapeake Bay south.",
            regions: [.midAtlantic, .southeast, .florida]
        ),
    ]
}
