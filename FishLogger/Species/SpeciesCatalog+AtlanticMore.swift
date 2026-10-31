import Foundation

// More saltwater fish of the Atlantic coast, Newfoundland to Florida, several also on the Gulf coast. Sizes are total length; weights only where a published length-weight relationship is known.
extension SpeciesCatalog {
    static let atlanticMoreSpecies: [Species] = [

        // MARK: Inshore

        Species(
            id: "atlantic_croaker",
            commonName: "Atlantic croaker",
            otherNames: ["Croaker", "Hardhead", "Golden croaker"],
            scientificName: "Micropogonias undulatus",
            group: .inshore,
            summary: "Common drum of bays, sounds, piers and surf, named for the croaking sound it makes when pulled from the water. Bites shrimp, squid and bloodworms fished on the bottom from spring to fall.",
            idTips: [
                "Three to five pairs of tiny whiskers on the chin; spot have none.",
                "Brassy brown speckles form wavy, slanting lines on the back and sides.",
                "Kingfish have a single chin whisker; young black drum have bold dark bars."
            ],
            lookalikes: ["spot", "black_drum", "southern_kingfish"],
            traits: [.spinyDorsal, .barbels, .darkSpotsLightBody, .goldenColor],
            sizeCutoffsCm: [20, 25, 32, 40],
            weightA: -5.160,
            weightB: 3.090,
            colorHex: 0x8C6A1C,
            habitat: "Bays, sounds, tidal rivers, piers and surf over mud or sand; moves to deeper water in winter.",
            range: "Atlantic coast from Cape Cod to Florida and around the Gulf to Mexico; common from New Jersey south.",
            regions: [.southernPlains, .northeast, .midAtlantic, .southeast, .florida]
        ),
        Species(
            id: "spot",
            commonName: "Spot",
            otherNames: ["Spot croaker", "Norfolk spot", "Yellowbelly", "Lafayette"],
            scientificName: "Leiostomus xanthurus",
            group: .inshore,
            summary: "Small, schooling drum that crowds into bays and tidal rivers in late summer and fall, and a favourite catch from piers. Big fall spot with yellow bellies are prized as food and as bait.",
            idTips: [
                "Dark round spot on the shoulder, just behind the top of the gill cover.",
                "No chin whiskers; a croaker has several pairs and a kingfish has one.",
                "Thin dark slanting bars on the back; a pinfish has blue and yellow stripes."
            ],
            lookalikes: ["atlantic_croaker", "pinfish"],
            traits: [.deepFlatBody, .smallMouth, .spinyDorsal, .verticalBars],
            sizeCutoffsCm: [15, 20, 25, 30],
            weightA: nil,
            weightB: nil,
            colorHex: 0x7E6672,
            habitat: "Bays, tidal creeks, sounds, piers and surf over mud and sand; moves offshore to spawn in winter.",
            range: "Atlantic coast from Cape Cod to Florida and around the Gulf to Mexico; most common from the Chesapeake Bay south.",
            regions: [.southernPlains, .northeast, .midAtlantic, .southeast, .florida]
        ),
        Species(
            id: "northern_kingfish",
            commonName: "Northern kingfish",
            otherNames: ["Kingfish", "King whiting", "Sea mullet", "Northern whiting"],
            scientificName: "Menticirrhus saxatilis",
            group: .inshore,
            summary: "Hard-pulling little drum of the surf and sandy bays, caught on bloodworms, clams and shrimp fished on the bottom. The common kingfish of New Jersey and New York beaches.",
            idTips: [
                "Bold dark slanting bars, and a dark stripe along the lower side to the tail.",
                "One very long spine in the first dorsal fin; other kingfish lack it.",
                "Single short chin whisker; croaker have several pairs and spot have none."
            ],
            lookalikes: ["southern_kingfish", "gulf_kingfish", "atlantic_croaker"],
            traits: [.torpedoBody, .smallMouth, .spinyDorsal, .barbels, .verticalBars],
            sizeCutoffsCm: [20, 28, 35, 42],
            weightA: nil,
            weightB: nil,
            colorHex: 0x765564,
            habitat: "Surf zones, inlets and sandy or muddy bays, often in troughs and along bars close to the beach.",
            range: "Atlantic coast from Massachusetts to Florida and into the Gulf; the most common kingfish from New York to Virginia.",
            regions: [.northeast, .midAtlantic, .southeast, .florida]
        ),
        Species(
            id: "southern_kingfish",
            commonName: "Southern kingfish",
            otherNames: ["Whiting", "Southern whiting", "Sea mullet", "King whiting", "Ground mullet"],
            scientificName: "Menticirrhus americanus",
            group: .inshore,
            summary: "The common whiting of southern beaches, piers and sounds, and a mild, white-fleshed table fish. Caught on shrimp, mole crabs and bloodworms fished on the bottom.",
            idTips: [
                "Faint, blotchy dark bars on the sides; a northern kingfish's bars are bold.",
                "No black tip at the top of the tail, unlike a gulf kingfish.",
                "Single chin whisker; croaker have several pairs and spot have none."
            ],
            lookalikes: ["northern_kingfish", "gulf_kingfish", "atlantic_croaker"],
            traits: [.torpedoBody, .smallMouth, .spinyDorsal, .barbels],
            sizeCutoffsCm: [20, 28, 35, 42],
            weightA: nil,
            weightB: nil,
            colorHex: 0x6E8F92,
            habitat: "Surf, piers, sounds and bays over mud or sandy mud, often in calmer water than a gulf kingfish.",
            range: "Atlantic coast from New York to Florida and around the Gulf to Mexico; most common from the Chesapeake Bay south.",
            regions: [.southernPlains, .midAtlantic, .southeast, .florida]
        ),
        Species(
            id: "gulf_kingfish",
            commonName: "Gulf kingfish",
            otherNames: ["Surf whiting", "Whiting", "Sea mullet", "Surf kingfish"],
            scientificName: "Menticirrhus littoralis",
            group: .inshore,
            summary: "Plain silver kingfish of the open surf, feeding in the wash on mole crabs, coquina clams and shrimp. Often the main whiting caught in the breakers on sandy ocean beaches.",
            idTips: [
                "Black tip at the top of the tail; southern and northern kingfish lack it.",
                "Plain silver sides with no bars or blotches.",
                "Single chin whisker; croaker have several pairs and spot have none."
            ],
            lookalikes: ["southern_kingfish", "northern_kingfish", "atlantic_croaker"],
            traits: [.torpedoBody, .smallMouth, .spinyDorsal, .barbels, .silverColor],
            sizeCutoffsCm: [20, 28, 35, 42],
            weightA: nil,
            weightB: nil,
            colorHex: 0x618EAD,
            habitat: "Open sandy surf, especially the troughs and wash close to the beach.",
            range: "Atlantic coast from the Chesapeake Bay to Florida and around the Gulf to Texas and Mexico.",
            regions: [.southernPlains, .southeast, .florida]
        ),

        // MARK: Offshore

        Species(
            id: "little_tunny",
            commonName: "Little tunny",
            otherNames: ["False albacore", "Albie", "Fat Albert", "Bonito", "Little tuna"],
            scientificName: "Euthynnus alletteratus",
            group: .offshore,
            summary: "Small, very fast tuna that blitzes bait close to shore, and a top fall target for light tackle and fly rods from Cape Cod to the Carolinas. The meat is dark and strong, so most are released.",
            idTips: [
                "Wavy dark lines on the back, behind the middle of the first dorsal.",
                "A few round black spots on the belly below the pectoral fin.",
                "Skipjack have belly stripes and plain backs; bonito have straight, slanting back stripes."
            ],
            lookalikes: ["atlantic_bonito", "skipjack_tuna", "blackfin_tuna"],
            traits: [.torpedoBody, .spinyDorsal, .twoSeparateDorsals, .forkedTail, .finlets, .darkSpotsLightBody],
            sizeCutoffsCm: [45, 60, 72, 85],
            weightA: nil,
            weightB: nil,
            colorHex: 0x167270,
            habitat: "Near the surface, from beaches, inlets and jetties out to offshore shoals and wrecks.",
            range: "Atlantic coast from Cape Cod to Florida and across the Gulf to Texas.",
            regions: [.southernPlains, .northeast, .midAtlantic, .southeast, .florida]
        ),
        Species(
            id: "atlantic_bonito",
            commonName: "Atlantic bonito",
            otherNames: ["Bonito", "Common bonito"],
            scientificName: "Sarda sarda",
            group: .offshore,
            summary: "Toothy, striped relative of the tunas that chases bait along beaches, rips and inlets from summer into fall, often with false albacore. Better eating than its dark-fleshed cousin.",
            idTips: [
                "Straight dark stripes slant forward and down across the back.",
                "Strong, pointed teeth in both jaws; a tuna's teeth are small.",
                "Plain silver belly; little tunny have belly spots and skipjack belly stripes."
            ],
            lookalikes: ["little_tunny", "skipjack_tuna"],
            traits: [.torpedoBody, .spinyDorsal, .forkedTail, .finlets],
            sizeCutoffsCm: [40, 50, 60, 70],
            weightA: nil,
            weightB: nil,
            colorHex: 0x196694,
            habitat: "Coastal and offshore water near the surface, often in tide rips, along beaches and around inlets and shoals.",
            range: "Both sides of the Atlantic; here, most catches come from the Carolinas to Cape Cod, with strays to Nova Scotia.",
            regions: [.northeast, .midAtlantic, .southeast]
        ),
        Species(
            id: "skipjack_tuna",
            commonName: "Skipjack tuna",
            otherNames: ["Skipjack", "Oceanic bonito", "Striped tuna", "Aku"],
            scientificName: "Katsuwonus pelamis",
            group: .offshore,
            summary: "Small, abundant tuna of warm blue water that travels in big, fast surface schools. The main fish in canned light tuna, and a popular bait for marlin and big tuna.",
            idTips: [
                "Four to six dark stripes run along the lower sides and belly.",
                "Plain dark blue back with no stripes, bars or wavy lines.",
                "Little tunny have belly spots, not stripes; bonito have stripes on the back."
            ],
            lookalikes: ["little_tunny", "atlantic_bonito", "pacific_bonito", "blackfin_tuna"],
            traits: [.torpedoBody, .spinyDorsal, .twoSeparateDorsals, .forkedTail, .finlets],
            sizeCutoffsCm: [40, 55, 65, 75],
            weightA: nil,
            weightB: nil,
            colorHex: 0x665F9E,
            habitat: "Warm offshore water near the surface, along current edges, weed lines and temperature breaks.",
            range: "Warm seas worldwide; here, from the Gulf and Florida north to the canyons off New England in summer, and off southern California in warm years.",
            regions: [.california, .southernPlains, .northeast, .midAtlantic, .southeast, .florida]
        ),
        Species(
            id: "bigeye_tuna",
            commonName: "Bigeye tuna",
            otherNames: ["Bigeye", "Big-eyed tuna"],
            scientificName: "Thunnus obesus",
            group: .offshore,
            summary: "Plump, big-eyed tuna that feeds deeper than a yellowfin, often caught at first light along canyon edges. Fine streaks on the underside of the liver, seen when cleaning, tell it from a yellowfin.",
            idTips: [
                "Big eye and a plump, deep body; a yellowfin is slimmer.",
                "Second dorsal and anal fins stay short, even on big fish.",
                "Long pectoral fin reaches the second dorsal; a bluefin's falls well short."
            ],
            lookalikes: ["yellowfin_tuna", "atlantic_bluefin_tuna"],
            traits: [.torpedoBody, .spinyDorsal, .twoSeparateDorsals, .forkedTail, .finlets],
            sizeCutoffsCm: [100, 130, 155, 180],
            weightA: nil,
            weightB: nil,
            colorHex: 0x265EA6,
            habitat: "Deep offshore water along canyon edges and the shelf break, usually deeper than other tunas by day.",
            range: "Warm and temperate seas worldwide; here, mostly in the canyons from North Carolina to southern New England.",
            regions: [.northeast, .midAtlantic, .southeast]
        ),
        Species(
            id: "blue_shark",
            commonName: "Blue shark",
            otherNames: ["Blue dog", "Blue whaler", "Great blue shark", "Requin bleu"],
            scientificName: "Prionace glauca",
            group: .offshore,
            summary: "Slim, long-finned ocean shark and a common catch on offshore shark trips from New Jersey to Nova Scotia. Most are released.",
            idTips: [
                "Bright indigo blue back and sides, sharply white below.",
                "Very long, narrow, sickle-shaped pectoral fins.",
                "Long, pointed snout and big eyes on a slender body; a salmon shark is stout."
            ],
            lookalikes: ["salmon_shark"],
            traits: [.torpedoBody, .twoSeparateDorsals, .smoothSkin],
            sizeCutoffsCm: [150, 190, 230, 270],
            weightA: nil,
            weightB: nil,
            colorHex: 0x3B6BBC,
            habitat: "Open ocean over the outer shelf and beyond, usually near the surface.",
            range: "Oceans worldwide; anglers here meet it offshore from Virginia to Nova Scotia and off California.",
            regions: [.atlanticCanada, .california, .northeast, .midAtlantic]
        ),

        // MARK: Bottomfish

        Species(
            id: "golden_tilefish",
            commonName: "Golden tilefish",
            otherNames: ["Tilefish", "Golden tile", "Great northern tilefish"],
            scientificName: "Lopholatilus chamaeleonticeps",
            group: .bottomfish,
            summary: "Colourful, slow-growing deep-water fish that digs burrows in clay along the edge of the continental shelf. Caught on baits dropped to the bottom in 100 to 300 m of water.",
            idTips: [
                "Fleshy, fin-like crest on top of the head, ahead of the dorsal fin.",
                "Bright yellow spots on the back and dorsal fin.",
                "Blueline tilefish lack the crest and have no yellow spots on the back."
            ],
            lookalikes: ["blueline_tilefish"],
            traits: [.longDorsalFin, .squareTail, .lightSpotsDarkBody],
            sizeCutoffsCm: [50, 65, 80, 95],
            weightA: nil,
            weightB: nil,
            colorHex: 0x98621A,
            habitat: "Burrows in clay and mud along the outer shelf edge and canyon walls, mostly 100 to 300 m deep.",
            range: "Outer shelf from Nova Scotia to Florida and across the Gulf of Mexico.",
            regions: [.northeast, .midAtlantic, .southeast, .florida]
        ),
        Species(
            id: "blueline_tilefish",
            commonName: "Blueline tilefish",
            otherNames: ["Grey tilefish", "Gray tilefish", "Blueline", "Tile"],
            scientificName: "Caulolatilus microps",
            group: .bottomfish,
            summary: "Long-snouted tilefish of the outer shelf, caught on deep-drop rigs along with grouper and golden tilefish. Good eating, and a common catch on deep trips off the Carolinas and Virginia.",
            idTips: [
                "Gold stripe over a broader blue band, from the snout to the eye.",
                "No fleshy crest on top of the head; a golden tilefish has one.",
                "Plain olive-grey back with no yellow spots, and a white belly."
            ],
            lookalikes: ["golden_tilefish"],
            traits: [.smallMouth, .longDorsalFin, .squareTail],
            sizeCutoffsCm: [40, 50, 60, 72],
            weightA: nil,
            weightB: nil,
            colorHex: 0x7A9076,
            habitat: "Sand, mud and rocky bottom along the outer shelf and upper slope, usually deeper than 60 m.",
            range: "Outer shelf from New Jersey to Florida and across the Gulf of Mexico; most common off the Carolinas.",
            regions: [.northeast, .midAtlantic, .southeast, .florida]
        ),
        Species(
            id: "cusk",
            commonName: "Cusk",
            otherNames: ["Tusk", "Torsk", "Brosme"],
            scientificName: "Brosme brosme",
            group: .bottomfish,
            summary: "Slow-growing, eel-like relative of the cod that lives among boulders in deep, cold water. A common side catch on deep Gulf of Maine groundfish trips.",
            idTips: [
                "One long dorsal fin that runs back to the rounded tail.",
                "Dorsal, tail and anal fins have a dark band edged in white.",
                "Single chin whisker; hakes have two dorsal fins and a cod three."
            ],
            lookalikes: ["white_hake", "red_hake"],
            traits: [.longDorsalFin, .roundedTail, .barbels],
            sizeCutoffsCm: [45, 55, 70, 85],
            weightA: nil,
            weightB: nil,
            colorHex: 0x92625E,
            habitat: "Rocky, boulder-strewn bottom in deep, cold water, mostly deeper than 60 m.",
            range: "Newfoundland and the Scotian Shelf to the Gulf of Maine, rarely south to New Jersey.",
            regions: [.northeast]
        ),
        Species(
            id: "white_hake",
            commonName: "White hake",
            otherNames: ["Hake", "Mud hake", "Boston hake", "Merluche blanche"],
            scientificName: "Urophycis tenuis",
            group: .bottomfish,
            summary: "Big, soft-bodied relative of the cod, caught over deep mud and around ledges in cold water. Grows far larger than a red hake, past 1 m.",
            idTips: [
                "Upper jaw reaches the back of the eye; a red hake's ends below the pupil.",
                "Thread-like pelvic fins usually stop short of the vent; a red hake's overlap it.",
                "Two dorsal fins and a small chin whisker; a cusk has one dorsal."
            ],
            lookalikes: ["red_hake", "cusk"],
            traits: [.twoSeparateDorsals, .roundedTail, .barbels],
            sizeCutoffsCm: [45, 60, 75, 90],
            weightA: nil,
            weightB: nil,
            colorHex: 0x8E667A,
            habitat: "Soft mud bottom and ledge edges in cool, deep water; young fish use shallow bays and eelgrass.",
            range: "Newfoundland and the Gulf of St. Lawrence to the Gulf of Maine, rarer south to the Carolinas.",
            regions: [.atlanticCanada, .northeast]
        ),
        Species(
            id: "red_hake",
            commonName: "Red hake",
            otherNames: ["Ling", "Squirrel hake", "Merluche-écureuil"],
            scientificName: "Urophycis chuss",
            group: .bottomfish,
            summary: "Small, soft-bodied hake, rarely over 50 cm, known to New Jersey and New York anglers as ling. Caught on wrecks and mud bottom, mostly in the cold months.",
            idTips: [
                "Upper jaw ends below the pupil; a white hake's reaches the back of the eye.",
                "Thread-like pelvic fins usually reach past the vent.",
                "First dorsal has a thread over twice its height; a white hake's is shorter."
            ],
            lookalikes: ["white_hake", "cusk"],
            traits: [.twoSeparateDorsals, .roundedTail, .barbels, .darkMottling],
            sizeCutoffsCm: [25, 30, 36, 42],
            weightA: nil,
            weightB: nil,
            colorHex: 0x9E5A5C,
            habitat: "Mud and sand bottom, wrecks and rock piles in cool water, moving offshore to deeper water in winter.",
            range: "Gulf of St. Lawrence and Nova Scotia to North Carolina; most common from Georges Bank to New Jersey.",
            regions: [.northeast]
        ),
        Species(
            id: "acadian_redfish",
            commonName: "Acadian redfish",
            otherNames: ["Redfish", "Ocean perch", "Rosefish", "Sébaste acadien"],
            scientificName: "Sebastes fasciatus",
            group: .bottomfish,
            summary: "Bright red, big-eyed rockfish of deep, cold water that grows very slowly and gives birth to live young. Nearly impossible to tell from the deepwater redfish where the two overlap in Canadian waters.",
            idTips: [
                "Bright orange-red all over, with a very large dark eye.",
                "Bony ridges and sharp spines on the head and gill cover.",
                "Bony knob at the tip of the lower jaw, which juts past the upper."
            ],
            lookalikes: [],
            traits: [.largeMouth, .spinyDorsal, .squareTail],
            sizeCutoffsCm: [22, 27, 32, 38],
            weightA: nil,
            weightB: nil,
            colorHex: 0x9C4426,
            habitat: "Rocky and muddy bottom in deep, cold water, usually deeper than 75 m.",
            range: "Newfoundland and the Gulf of St. Lawrence to the Gulf of Maine, rarely south to New Jersey.",
            regions: [.northeast]
        ),
        Species(
            id: "spiny_dogfish",
            commonName: "Spiny dogfish",
            otherNames: ["Dogfish", "Spurdog", "Piked dogfish", "Aiguillat commun"],
            scientificName: "Squalus acanthias",
            group: .bottomfish,
            summary: "Small, slim shark that travels in huge schools and often swarms baits meant for other fish. A sharp spine in front of each dorsal fin can cause a painful wound, so handle it with care.",
            idTips: [
                "Sharp spine at the front of each of its two dorsal fins.",
                "Scattered small white spots on a grey back.",
                "No anal fin; a smooth dogfish has one, and no spines."
            ],
            lookalikes: [],
            traits: [.torpedoBody, .spinyDorsal, .twoSeparateDorsals, .lightSpotsDarkBody],
            sizeCutoffsCm: [55, 70, 85, 100],
            weightA: nil,
            weightB: nil,
            colorHex: 0x5A725C,
            habitat: "Bays, sounds and the continental shelf, near the bottom or in midwater, moving in large schools.",
            range: "Labrador to Florida, most common from Nova Scotia to North Carolina; Pacific dogfish are now a separate species.",
            regions: [.atlanticCanada, .northeast, .midAtlantic, .southeast]
        ),
    ]
}
