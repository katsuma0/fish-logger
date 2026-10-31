import Foundation

// Offshore and reef fish, mostly of the Atlantic and Gulf. Billfish sizes are lower jaw fork length, the rest total length; weights only where a published length-weight relationship is known.
extension SpeciesCatalog {
    static let offshoreSpecies: [Species] = [

        // MARK: Offshore

        Species(
            id: "mahi_mahi",
            commonName: "Mahi-mahi",
            otherNames: ["Dolphinfish", "Dolphin", "Dorado", "Mahi"],
            scientificName: "Coryphaena hippurus",
            group: .offshore,
            summary: "Fast-growing, brightly coloured fish of warm blue water, found under weed lines, logs and other floating cover. Small fish travel in schools, while big bulls often hunt alone or in pairs.",
            idTips: [
                "One long dorsal fin runs from the head almost to the tail.",
                "Blue-green back and gold sides with small dark spots; colour fades fast after death.",
                "Bulls have a tall, blunt forehead; cows have a rounded, sloping head."
            ],
            lookalikes: [],
            traits: [.longDorsalFin, .forkedTail, .darkSpotsLightBody, .goldenColor],
            sizeCutoffsCm: [55, 80, 105, 130],
            weightA: nil,
            weightB: nil,
            colorHex: 0x477A30,
            habitat: "Warm offshore water near the surface, under weed lines, logs and buoys.",
            range: "Warm seas worldwide; north along the Gulf Stream to New England in summer, and across the Gulf.",
            regions: [.southernPlains, .northeast, .midAtlantic, .southeast, .florida]
        ),
        Species(
            id: "yellowfin_tuna",
            commonName: "Yellowfin tuna",
            otherNames: ["Yellowfin", "Ahi", "Allison tuna"],
            scientificName: "Thunnus albacares",
            group: .offshore,
            summary: "Fast, hard-fighting tuna of warm offshore water, often found around oil rigs, weed lines and feeding birds. Big adults grow long yellow fins and can top 90 kg.",
            idTips: [
                "Finlets bright yellow with thin black edges; a blackfin's are dark.",
                "Pectoral fin reaches the second dorsal; a bluefin's is shorter, an albacore's far longer.",
                "Gold side stripe; big adults grow long, sickle-shaped yellow second dorsal and anal fins."
            ],
            lookalikes: ["blackfin_tuna", "atlantic_bluefin_tuna", "pacific_bluefin_tuna", "albacore"],
            traits: [.torpedoBody, .spinyDorsal, .twoSeparateDorsals, .forkedTail, .finlets, .goldenColor],
            sizeCutoffsCm: [70, 100, 125, 150],
            weightA: nil,
            weightB: nil,
            colorHex: 0x856F28,
            habitat: "Warm offshore water near the surface, along temperature breaks, oil rigs and canyon edges.",
            range: "Warm seas worldwide; from the Gulf to the canyons off New England, and off Southern California in warm years.",
            regions: [.california, .southernPlains, .northeast, .midAtlantic, .southeast]
        ),
        Species(
            id: "atlantic_bluefin_tuna",
            commonName: "Atlantic bluefin tuna",
            otherNames: ["Bluefin", "Bluefin tuna", "Giant bluefin", "Thon rouge"],
            scientificName: "Thunnus thynnus",
            group: .offshore,
            summary: "The largest tuna, a warm-bodied giant that follows herring and mackerel north to feed each summer and fall.",
            idTips: [
                "Short pectoral fin that ends well before the second dorsal fin.",
                "Finlets dusky yellow edged in black, with no bright gold side stripe.",
                "Grows far bigger than any other Atlantic tuna, past 400 kg."
            ],
            lookalikes: ["yellowfin_tuna", "blackfin_tuna", "albacore"],
            traits: [.torpedoBody, .spinyDorsal, .twoSeparateDorsals, .forkedTail, .finlets],
            sizeCutoffsCm: [70, 125, 160, 215],
            weightA: nil,
            weightB: nil,
            colorHex: 0x535F8A,
            habitat: "Open coastal and offshore water, from deep basins to shallow banks close to shore.",
            range: "North Atlantic and Mediterranean; here, anglers fish it from North Carolina to the Gulf of St. Lawrence.",
            regions: [.atlanticCanada, .northeast, .midAtlantic, .southeast]
        ),
        Species(
            id: "blackfin_tuna",
            commonName: "Blackfin tuna",
            otherNames: ["Blackfin"],
            scientificName: "Thunnus atlanticus",
            group: .offshore,
            summary: "Small, fast tuna of warm water, common around reefs, wrecks, humps and oil rigs. A favourite light-tackle target off Florida and along the Gulf coast.",
            idTips: [
                "Dark finlets with little or no yellow; a yellowfin's are bright yellow.",
                "Second dorsal and anal fins dusky; a yellowfin's are yellow.",
                "Small tuna, rarely over 10 kg; yellowfin and bluefin grow far larger."
            ],
            lookalikes: ["yellowfin_tuna", "atlantic_bluefin_tuna"],
            traits: [.torpedoBody, .spinyDorsal, .twoSeparateDorsals, .forkedTail, .finlets],
            sizeCutoffsCm: [45, 60, 75, 90],
            weightA: nil,
            weightB: nil,
            colorHex: 0x6C6A99,
            habitat: "Warm offshore and nearshore water around reefs, wrecks, humps and oil rigs.",
            range: "Western Atlantic only, most common from the Carolinas to Florida and across the Gulf.",
            regions: [.southernPlains, .southeast, .florida]
        ),
        Species(
            id: "albacore",
            commonName: "Albacore",
            otherNames: ["Albacore tuna", "Longfin tuna", "Longfin", "White tuna", "Tombo"],
            scientificName: "Thunnus alalunga",
            group: .offshore,
            summary: "Long-finned tuna of cooler offshore water on both coasts, prized for its pale meat. A summer target off Oregon and Washington and in the canyons from Virginia to New England.",
            idTips: [
                "Very long pectoral fins reach well past the start of the second dorsal fin.",
                "Thin white edge along the back of the tail.",
                "No gold side stripe; lower sides and belly plain silvery white."
            ],
            lookalikes: ["yellowfin_tuna", "atlantic_bluefin_tuna", "pacific_bluefin_tuna"],
            traits: [.torpedoBody, .spinyDorsal, .twoSeparateDorsals, .forkedTail, .finlets],
            sizeCutoffsCm: [65, 80, 95, 110],
            weightA: nil,
            weightB: nil,
            colorHex: 0x457EA3,
            habitat: "Cool offshore blue water, often along temperature breaks, canyon edges and seamounts.",
            range: "Temperate seas worldwide; off the Pacific coast from California to Washington and in the Atlantic canyons from Virginia to New England.",
            regions: [.pacificNorthwest, .california, .northeast, .midAtlantic]
        ),
        Species(
            id: "wahoo",
            commonName: "Wahoo",
            otherNames: ["Ono", "Hoo"],
            scientificName: "Acanthocybium solandri",
            group: .offshore,
            summary: "Slim, very fast relative of the mackerels that strikes trolled lures hard along offshore ledges, drop-offs and weed lines. Its razor teeth cut light leaders, so many anglers use wire.",
            idTips: [
                "Long, low first dorsal fin starts behind the head, far longer than a king's.",
                "Dark blue tiger bars down the sides; a king mackerel has plain sides.",
                "Snout as long as the rest of the head; a king's is much shorter."
            ],
            lookalikes: ["king_mackerel"],
            traits: [.torpedoBody, .longToothySnout, .spinyDorsal, .longDorsalFin, .forkedTail, .finlets, .verticalBars],
            sizeCutoffsCm: [100, 125, 150, 175],
            weightA: nil,
            weightB: nil,
            colorHex: 0x4E56AD,
            habitat: "Warm offshore water near drop-offs, ledges, seamounts and weed lines.",
            range: "Warm seas worldwide; along the Atlantic coast from Florida to the canyons off Virginia, and across the Gulf.",
            regions: [.southernPlains, .midAtlantic, .southeast, .florida]
        ),
        Species(
            id: "king_mackerel",
            commonName: "King mackerel",
            otherNames: ["Kingfish", "King", "Smoker"],
            scientificName: "Scomberomorus cavalla",
            group: .offshore,
            summary: "Big, toothy mackerel that follows warm water and bait along the coast, caught by trolling, slow-trolling live bait and from ocean piers. The largest fish are called smokers for their long, fast runs.",
            idTips: [
                "Lateral line dips sharply below the second dorsal fin.",
                "First dorsal fin plain grey, with no black patch at the front.",
                "Adults have plain silver sides; small kings may show faint yellow spots."
            ],
            lookalikes: ["spanish_mackerel", "wahoo"],
            traits: [.torpedoBody, .spinyDorsal, .twoSeparateDorsals, .forkedTail, .finlets, .silverColor],
            sizeCutoffsCm: [69, 95, 115, 135],
            weightA: nil,
            weightB: nil,
            colorHex: 0x30666B,
            habitat: "Nearshore and offshore water around reefs, wrecks, oil rigs and schools of bait.",
            range: "Atlantic coast from Virginia to Florida and around the Gulf to Texas.",
            regions: [.southernPlains, .midAtlantic, .southeast, .florida]
        ),
        Species(
            id: "sailfish",
            commonName: "Sailfish",
            otherNames: ["Atlantic sailfish", "Sail"],
            scientificName: "Istiophorus platypterus",
            group: .offshore,
            summary: "Fast, acrobatic billfish that raises its huge sail to herd bait, most often caught on live bait off southeast Florida in winter. Size classes use lower jaw fork length, the measure in billfish rules.",
            idTips: [
                "Huge, sail-like first dorsal fin, much taller than the body is deep.",
                "Very long, thin pelvic fins that reach nearly to the vent.",
                "Slim body, rarely over 45 kg in the Atlantic."
            ],
            lookalikes: ["white_marlin", "blue_marlin"],
            traits: [.billSnout, .longDorsalFin, .forkedTail],
            sizeCutoffsCm: [130, 150, 165, 180],
            weightA: nil,
            weightB: nil,
            colorHex: 0x6B5EB8,
            habitat: "Warm offshore water near the edge of the continental shelf and along current edges.",
            range: "Warm seas worldwide; most catches here come from southeast Florida, the Gulf and off the Carolinas.",
            regions: [.southernPlains, .southeast, .florida]
        ),
        Species(
            id: "blue_marlin",
            commonName: "Blue marlin",
            otherNames: ["Atlantic blue marlin", "Blue"],
            scientificName: "Makaira nigricans",
            group: .offshore,
            summary: "The largest Atlantic billfish, a powerful fish of deep blue water that can top 450 kg. Size classes use lower jaw fork length, the measure in billfish rules.",
            idTips: [
                "Pointed tips on the first dorsal and anal fins; a white marlin's are rounded.",
                "First dorsal fin lower than the body is deep, unlike a sailfish's sail.",
                "Cobalt blue back and pale bars; grows far bigger than a white marlin."
            ],
            lookalikes: ["white_marlin", "sailfish"],
            traits: [.torpedoBody, .billSnout, .forkedTail],
            sizeCutoffsCm: [190, 230, 265, 300],
            weightA: nil,
            weightB: nil,
            colorHex: 0x47619E,
            habitat: "Warm, deep blue water well offshore, often along current edges, canyons and seamounts.",
            range: "Warm seas worldwide; here, from the Gulf and Florida north to the canyons off New Jersey in summer.",
            regions: [.southernPlains, .northeast, .midAtlantic, .southeast, .florida]
        ),
        Species(
            id: "white_marlin",
            commonName: "White marlin",
            otherNames: ["Atlantic white marlin", "White"],
            scientificName: "Kajikia albida",
            group: .offshore,
            summary: "Smaller Atlantic marlin, quick and acrobatic, that gathers along the canyons and the shelf edge in summer. Size classes use lower jaw fork length, the measure in billfish rules.",
            idTips: [
                "Rounded tips on the first dorsal and anal fins; a blue marlin's are pointed.",
                "First dorsal fin far lower than a sailfish's tall sail.",
                "Usually 20 to 35 kg, much smaller than most blue marlin."
            ],
            lookalikes: ["blue_marlin", "sailfish"],
            traits: [.torpedoBody, .billSnout, .forkedTail],
            sizeCutoffsCm: [140, 160, 175, 190],
            weightA: nil,
            weightB: nil,
            colorHex: 0x6A7399,
            habitat: "Warm offshore water along the edge of the continental shelf, canyons and current edges.",
            range: "Atlantic only; here, from the Gulf and Florida north to the canyons off New England in summer.",
            regions: [.southernPlains, .northeast, .midAtlantic, .southeast, .florida]
        ),
        Species(
            id: "swordfish",
            commonName: "Swordfish",
            otherNames: ["Broadbill", "Broadbill swordfish", "Sword"],
            scientificName: "Xiphias gladius",
            group: .offshore,
            summary: "Big, deep-water billfish that hunts squid near the bottom by day and rises toward the surface at night. Size classes use lower jaw fork length, the measure in swordfish rules.",
            idTips: [
                "Long, flat, wide sword, not a round spear like a marlin or sailfish.",
                "Tall, stiff first dorsal fin that does not fold down.",
                "No scales or pelvic fins; one large keel on each side of the tail."
            ],
            lookalikes: ["blue_marlin", "white_marlin", "sailfish"],
            traits: [.torpedoBody, .billSnout, .forkedTail, .smoothSkin],
            sizeCutoffsCm: [120, 150, 180, 215],
            weightA: nil,
            weightB: nil,
            colorHex: 0x6E5475,
            habitat: "Deep offshore water, near the bottom by day and closer to the surface at night.",
            range: "Temperate and tropical seas worldwide; most catches here come from south Florida, the Gulf and the Atlantic canyons.",
            regions: [.northeast, .midAtlantic, .southeast, .florida]
        ),

        // MARK: Bottomfish

        Species(
            id: "greater_amberjack",
            commonName: "Greater amberjack",
            otherNames: ["Amberjack", "AJ", "Reef donkey"],
            scientificName: "Seriola dumerili",
            group: .bottomfish,
            summary: "Big, powerful jack that hangs over wrecks, reefs and oil rigs and pulls hard for the bottom when hooked. Known to many anglers as the reef donkey.",
            idTips: [
                "Dark band runs from the nose through the eye to the first dorsal fin.",
                "Amber side stripe and no hard scutes near the tail; a crevalle has them.",
                "Second dorsal fin low in front; an almaco jack's is tall and sickle shaped."
            ],
            lookalikes: ["jack_crevalle"],
            traits: [.torpedoBody, .spinyDorsal, .twoSeparateDorsals, .forkedTail, .goldenColor],
            sizeCutoffsCm: [80, 100, 120, 140],
            weightA: nil,
            weightB: nil,
            colorHex: 0x9E7164,
            habitat: "Deep reefs, wrecks, ledges and oil rigs, usually 20 to 70 m deep.",
            range: "Warm seas worldwide; along the Atlantic coast from Virginia to Florida and across the Gulf.",
            regions: [.southernPlains, .midAtlantic, .southeast, .florida]
        ),
        Species(
            id: "red_snapper",
            commonName: "Red snapper",
            otherNames: ["Northern red snapper", "American red snapper"],
            scientificName: "Lutjanus campechanus",
            group: .bottomfish,
            summary: "Prized reef fish of the Gulf and the southeastern Atlantic, caught on bait over reefs, wrecks and oil rigs. Seasons and limits change often, so check current rules.",
            idTips: [
                "Plain rosy red with a red eye and no blue or yellow side lines.",
                "Long, sloping face with big canine teeth; a vermilion's lower jaw juts out.",
                "Pointed anal fin, and a deeper body than a vermilion snapper."
            ],
            lookalikes: ["vermilion_snapper", "gray_snapper"],
            traits: [.deepFlatBody, .spinyDorsal, .forkedTail],
            sizeCutoffsCm: [40, 55, 70, 85],
            weightA: -5.076,
            weightB: 3.076,
            colorHex: 0xB8484B,
            habitat: "Reefs, wrecks, ledges and oil rigs, usually 20 to 100 m deep.",
            range: "Gulf of Mexico and the Atlantic coast from North Carolina to Florida.",
            regions: [.southernPlains, .southeast, .florida]
        ),
        Species(
            id: "gag_grouper",
            commonName: "Gag grouper",
            otherNames: ["Gag", "Gray grouper"],
            scientificName: "Mycteroperca microlepis",
            group: .bottomfish,
            summary: "Big, hard-pulling grouper of rocky ledges and reefs; young fish grow up in seagrass beds close to shore. A hooked gag dives straight for cover.",
            idTips: [
                "Grey to brownish with darker, worm-like squiggles, not white blotches.",
                "Spiny dorsal edge notched between the spines; a red grouper's is straight.",
                "Body longer and slimmer than a red grouper's."
            ],
            lookalikes: ["red_grouper"],
            traits: [.largeMouth, .spinyDorsal, .squareTail, .darkMottling],
            sizeCutoffsCm: [50, 61, 80, 100],
            weightA: nil,
            weightB: nil,
            colorHex: 0x8A6C67,
            habitat: "Rocky ledges, reefs and wrecks offshore; young fish live in seagrass beds and bays.",
            range: "Atlantic coast from North Carolina to Florida and across the eastern Gulf.",
            regions: [.southeast, .florida]
        ),
        Species(
            id: "red_grouper",
            commonName: "Red grouper",
            otherNames: [],
            scientificName: "Epinephelus morio",
            group: .bottomfish,
            summary: "Stout grouper of the limestone bottom of the eastern Gulf, where it digs pits in the sea floor. A staple of the Florida bottom fishery.",
            idTips: [
                "Brick red to brown with pale blotches and scattered small white spots.",
                "Spiny dorsal edge straight, not notched between the spines like a gag's.",
                "Stout, deep body; a gag is longer and slimmer."
            ],
            lookalikes: ["gag_grouper"],
            traits: [.largeMouth, .spinyDorsal, .squareTail, .lightSpotsDarkBody],
            sizeCutoffsCm: [40, 51, 65, 80],
            weightA: -5.398,
            weightB: 3.220,
            colorHex: 0x9E4C42,
            habitat: "Limestone and rocky bottom, ledges and reefs, usually 20 to 120 m deep.",
            range: "Mainly the eastern Gulf off Florida, and the Atlantic coast from North Carolina to Florida.",
            regions: [.southeast, .florida]
        ),
        Species(
            id: "vermilion_snapper",
            commonName: "Vermilion snapper",
            otherNames: ["B-liner", "Beeliner", "Mingo"],
            scientificName: "Rhomboplites aurorubens",
            group: .bottomfish,
            summary: "Small, schooling snapper of offshore reefs, often caught on small hooks while fishing for bigger reef fish. Good eating and a common fill-in for the cooler.",
            idTips: [
                "Rows of short blue lines and spots on the red upper sides.",
                "Lower jaw juts past the upper, and no big canine teeth.",
                "Slimmer than a red snapper, with a deeply forked tail."
            ],
            lookalikes: ["red_snapper"],
            traits: [.spinyDorsal, .forkedTail, .lightSpotsDarkBody],
            sizeCutoffsCm: [25, 30, 38, 46],
            weightA: -4.764,
            weightB: 2.946,
            colorHex: 0xC7614E,
            habitat: "Offshore reefs, ledges and rocky bottom, usually 25 to 100 m deep.",
            range: "Atlantic coast from North Carolina to Florida and across the Gulf to Texas.",
            regions: [.southernPlains, .southeast, .florida]
        ),
    ]
}
