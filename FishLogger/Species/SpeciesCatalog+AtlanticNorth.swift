import Foundation

// Saltwater fish of the North Atlantic coast, Newfoundland to Virginia. Weights only where a published length-weight relationship is known.
extension SpeciesCatalog {
    static let northAtlanticSpecies: [Species] = [

        // MARK: Inshore

        Species(
            id: "bluefish",
            commonName: "Bluefish",
            otherNames: ["Snapper blue", "Chopper"],
            scientificName: "Pomatomus saltatrix",
            group: .inshore,
            summary: "Fast, toothy schooling predator that chases bait through the surf, inlets and bays from spring to fall. Young fish under about 30 cm are called snappers.",
            idTips: [
                "Plain blue-green back and silver sides, with no spots or bars.",
                "Black blotch at the base of each pectoral fin.",
                "No finlets before the tail; a Spanish mackerel has a row of them."
            ],
            lookalikes: ["spanish_mackerel", "weakfish"],
            traits: [.torpedoBody, .spinyDorsal, .twoSeparateDorsals, .silverColor, .forkedTail],
            sizeCutoffsCm: [30, 50, 70, 85],
            weightA: nil,
            weightB: nil,
            colorHex: 0x3385A3,
            habitat: "Surf, inlets, bays and nearshore ocean, chasing schools of bait near the surface.",
            range: "Atlantic coast from Maine to Florida and into the northern Gulf of Mexico; strays to Nova Scotia in warm summers.",
            regions: [.northeast, .midAtlantic, .southeast, .florida]
        ),
        Species(
            id: "weakfish",
            commonName: "Weakfish",
            otherNames: ["Squeteague", "Gray trout", "Sea trout", "Tiderunner"],
            scientificName: "Cynoscion regalis",
            group: .inshore,
            summary: "Slim, speckled drum of bays and sounds, named for a soft mouth that tears free of a hook. Stocks are depleted, so limits are tight.",
            idTips: [
                "Small dark speckles in wavy, slanting rows, not big round spots.",
                "Dorsal fins and tail unspotted; a spotted seatrout's are spotted.",
                "Purple, green and gold sheen on the back; yellow pelvic and anal fins."
            ],
            lookalikes: ["spotted_seatrout"],
            traits: [.torpedoBody, .spinyDorsal, .squareTail, .darkSpotsLightBody, .silverColor],
            sizeCutoffsCm: [30, 45, 60, 75],
            weightA: -5.057,
            weightB: 3.000,
            colorHex: 0x7C5394,
            habitat: "Bays, sounds and estuaries over sand or mud, often along channel edges.",
            range: "Atlantic coast from Nova Scotia to southeastern Florida; most common from New York to North Carolina.",
            regions: [.northeast, .midAtlantic, .southeast, .florida]
        ),
        Species(
            id: "summer_flounder",
            commonName: "Summer flounder",
            otherNames: ["Fluke", "Doormat"],
            scientificName: "Paralichthys dentatus",
            group: .inshore,
            summary: "Big-mouthed, toothy flatfish that ambushes bait from the bottom of bays, inlets and nearshore ocean. A top summer target from New York to Virginia.",
            idTips: [
                "Eyes on the left side; a winter flounder's are on the right.",
                "Five ringed eyespots set like the five on a die; southern flounder lack them.",
                "Large, toothy mouth reaching past the eye; a winter flounder's is tiny."
            ],
            lookalikes: ["southern_flounder", "winter_flounder"],
            traits: [.eyesOnOneSide, .deepFlatBody, .largeMouth, .longDorsalFin, .darkSpotsLightBody],
            sizeCutoffsCm: [38, 46, 58, 70],
            weightA: -5.380,
            weightB: 3.160,
            colorHex: 0x8A6642,
            habitat: "Sand and mud bottoms of bays, inlets and nearshore ocean; moves offshore in winter.",
            range: "Atlantic coast from Cape Cod to the Carolinas, rarer north to Nova Scotia and south to Florida.",
            regions: [.northeast, .midAtlantic, .southeast]
        ),
        Species(
            id: "winter_flounder",
            commonName: "Winter flounder",
            otherNames: ["Blackback", "Lemon sole", "Plie rouge"],
            scientificName: "Pseudopleuronectes americanus",
            group: .inshore,
            summary: "Small-mouthed flatfish of cold inshore water, a classic early spring catch on worms and clams. Stocks in southern New England are low, so limits there are tight.",
            idTips: [
                "Eyes on the right side; a summer flounder's are on the left.",
                "Small mouth with thick lips, ending well before the eye.",
                "Nearly straight lateral line; a halibut's arches high over the pectoral fin."
            ],
            lookalikes: ["summer_flounder", "atlantic_halibut"],
            traits: [.eyesOnOneSide, .deepFlatBody, .smallMouth, .longDorsalFin],
            sizeCutoffsCm: [25, 30, 38, 46],
            weightA: nil,
            weightB: nil,
            colorHex: 0xAD6F63,
            habitat: "Shallow bays, harbours and estuaries over mud or sand, deeper in the heat of summer.",
            range: "Atlantic coast from Labrador to Georgia; most common from the Gulf of St. Lawrence to New Jersey.",
            regions: [.quebec, .atlanticCanada, .northeast]
        ),
        Species(
            id: "atlantic_mackerel",
            commonName: "Atlantic mackerel",
            otherNames: ["Mackerel", "Boston mackerel", "Maquereau bleu"],
            scientificName: "Scomber scombrus",
            group: .inshore,
            summary: "Small, fast schooling fish that crowds into harbours in summer and bites strings of jigs from wharves and boats. Stocks are low, so check current limits before you keep any.",
            idTips: [
                "Wavy black bars across a blue-green back, over a plain silver belly.",
                "Two dorsal fins set far apart; a Spanish mackerel's nearly touch.",
                "No yellow or gold spots on the sides."
            ],
            lookalikes: ["spanish_mackerel"],
            traits: [.torpedoBody, .spinyDorsal, .twoSeparateDorsals, .finlets, .verticalBars, .forkedTail],
            sizeCutoffsCm: [22, 28, 34, 40],
            weightA: nil,
            weightB: nil,
            colorHex: 0x216B4C,
            habitat: "Open coastal water near the surface; comes into bays, harbours and around wharves in summer.",
            range: "Labrador to North Carolina; inshore in summer from the Gulf of St. Lawrence to Cape Cod.",
            regions: [.quebec, .atlanticCanada, .northeast]
        ),

        // MARK: Bottomfish

        Species(
            id: "tautog",
            commonName: "Tautog",
            otherNames: ["Blackfish", "Tog"],
            scientificName: "Tautoga onitis",
            group: .bottomfish,
            summary: "Stocky, hard-pulling wrasse of rocks, wrecks and jetties, caught on crabs fished tight to the bottom. Slow growing, so seasons and limits are strict.",
            idTips: [
                "Blunt, rounded head with thick lips and stout, conical front teeth.",
                "Blotchy grey to black body; big males have a white chin.",
                "Small mouth well short of the eye; a sea bass's reaches below it."
            ],
            lookalikes: ["black_sea_bass"],
            traits: [.smallMouth, .spinyDorsal, .longDorsalFin, .darkMottling],
            sizeCutoffsCm: [30, 41, 50, 60],
            weightA: nil,
            weightB: nil,
            colorHex: 0x756B3D,
            habitat: "Rocky shores, jetties, wrecks, reefs and mussel beds, rarely far from cover.",
            range: "Atlantic coast from Nova Scotia to Georgia; most common from Cape Cod to the Chesapeake Bay.",
            regions: [.northeast, .midAtlantic]
        ),
        Species(
            id: "black_sea_bass",
            commonName: "Black sea bass",
            otherNames: ["Sea bass", "Humpback", "Knothead"],
            scientificName: "Centropristis striata",
            group: .bottomfish,
            summary: "Common bottom fish of reefs and wrecks, and one of the best-eating catches on a party boat. Many start life as females and later turn male; spawning males grow a blue hump behind the head.",
            idTips: [
                "Long, thread-like tip on the top lobe of the tail.",
                "Pale-centred scales form thin light stripes along the dark sides.",
                "Big mouth reaching below the eye; a tautog's mouth is small."
            ],
            lookalikes: ["tautog", "gag_grouper"],
            traits: [.spinyDorsal, .longDorsalFin, .roundedTail, .lightSpotsDarkBody],
            sizeCutoffsCm: [25, 32, 41, 51],
            weightA: -4.980,
            weightB: 3.040,
            colorHex: 0x584C8F,
            habitat: "Reefs, wrecks, rock piles and jetties; inshore in summer, out on the shelf in winter.",
            range: "Atlantic coast from Maine to Florida and the eastern Gulf of Mexico; most abundant from Cape Cod to North Carolina.",
            regions: [.northeast, .midAtlantic, .southeast, .florida]
        ),
        Species(
            id: "scup",
            commonName: "Scup",
            otherNames: ["Porgy", "Northern porgy"],
            scientificName: "Stenotomus chrysops",
            group: .bottomfish,
            summary: "Small, deep-bodied porgy that schools over hard bottom and bites readily on clam and squid. An easy summer catch from piers and boats, and good eating.",
            idTips: [
                "Dull silver with pale blue flecks; any bars are faint, not bold black.",
                "Narrow front teeth; a sheepshead has broad, human-like front teeth.",
                "Steep forehead above a small mouth; usually 20 to 35 cm long."
            ],
            lookalikes: ["sheepshead"],
            traits: [.deepFlatBody, .smallMouth, .spinyDorsal, .silverColor, .forkedTail],
            sizeCutoffsCm: [20, 25, 32, 38],
            weightA: nil,
            weightB: nil,
            colorHex: 0x9E727B,
            habitat: "Hard and sandy bottoms near rocks, mussel beds, piers and wrecks in bays and nearshore water.",
            range: "Atlantic coast from Cape Cod to the Carolinas, most common from Massachusetts to New Jersey; rare north to Nova Scotia.",
            regions: [.northeast, .midAtlantic]
        ),
        Species(
            id: "atlantic_cod",
            commonName: "Atlantic cod",
            otherNames: ["Cod", "Codfish", "Morue franche"],
            scientificName: "Gadus morhua",
            group: .bottomfish,
            summary: "Big, heavy-bodied groundfish that built the fisheries of Atlantic Canada and New England. Most stocks are still low, so seasons and limits are tight and change often.",
            idTips: [
                "Pale lateral line on a spotted olive to reddish-brown body.",
                "Upper jaw overhangs the lower; a pollock's lower jaw sticks out.",
                "Long chin barbel and a square tail; a tomcod's tail is rounded."
            ],
            lookalikes: ["haddock", "pollock", "atlantic_tomcod"],
            traits: [.torpedoBody, .twoSeparateDorsals, .squareTail, .barbels, .darkSpotsLightBody],
            sizeCutoffsCm: [45, 60, 80, 100],
            weightA: -5.143,
            weightB: 3.052,
            colorHex: 0x606137,
            habitat: "Cool water over rock, gravel and ledges, from shallow coves to deep offshore banks.",
            range: "Labrador and Newfoundland south to Cape Hatteras; most common north of Cape Cod and on the offshore banks.",
            regions: [.quebec, .atlanticCanada, .northeast]
        ),
        Species(
            id: "haddock",
            commonName: "Haddock",
            otherNames: ["Aiglefin", "Églefin"],
            scientificName: "Melanogrammus aeglefinus",
            group: .bottomfish,
            summary: "Smaller cousin of the cod and a favourite party boat catch on offshore banks and ledges. Bites clams and squid fished on the bottom.",
            idTips: [
                "Black lateral line; a cod's or pollock's is pale.",
                "Dark thumbprint blotch above the pectoral fin.",
                "Tall, pointed first dorsal fin and a short chin barbel."
            ],
            lookalikes: ["atlantic_cod", "pollock"],
            traits: [.torpedoBody, .smallMouth, .twoSeparateDorsals, .barbels, .darkLateralLine],
            sizeCutoffsCm: [35, 43, 55, 65],
            weightA: -5.260,
            weightB: 3.080,
            colorHex: 0x8A76A8,
            habitat: "Cool, fairly deep water over sand, gravel and shell on banks and ledges.",
            range: "Newfoundland and the Scotian Shelf to Georges Bank and the Gulf of Maine, rarer south to Cape Hatteras.",
            regions: [.atlanticCanada, .northeast]
        ),
        Species(
            id: "pollock",
            commonName: "Pollock",
            otherNames: ["Saithe", "Boston bluefish", "Coalfish", "Goberge"],
            scientificName: "Pollachius virens",
            group: .bottomfish,
            summary: "Strong, fast relative of the cod that hunts in schools over ledges and rocky shores. Small pollock fill harbours in summer, and big ones hit jigs on offshore grounds.",
            idTips: [
                "Lower jaw slightly longer than the upper; cod and haddock have overhanging snouts.",
                "Plain olive-green back with no spots, and a pale lateral line.",
                "Forked tail and a tiny or missing chin barbel."
            ],
            lookalikes: ["atlantic_cod", "haddock"],
            traits: [.torpedoBody, .twoSeparateDorsals, .forkedTail],
            sizeCutoffsCm: [35, 50, 70, 90],
            weightA: -5.250,
            weightB: 3.070,
            colorHex: 0x568552,
            habitat: "Rocky shores, ledges and offshore banks; young fish school in harbours and around wharves.",
            range: "Labrador and the Gulf of St. Lawrence to Cape Cod, rarer south to North Carolina.",
            regions: [.atlanticCanada, .northeast]
        ),
        Species(
            id: "atlantic_halibut",
            commonName: "Atlantic halibut",
            otherNames: ["Halibut", "Flétan atlantique"],
            scientificName: "Hippoglossus hippoglossus",
            group: .bottomfish,
            summary: "The largest flatfish in the Atlantic, known to reach well over 2 m. Rules on keeping one are strict and differ by area, so check them before you fish.",
            idTips: [
                "Concave tail edge and a lateral line arching high over the pectoral fin.",
                "Eyes on the right and a big mouth reaching below the eye.",
                "Atlantic only; a Pacific halibut looks almost the same."
            ],
            lookalikes: ["pacific_halibut", "winter_flounder", "summer_flounder"],
            traits: [.eyesOnOneSide, .deepFlatBody, .longDorsalFin],
            sizeCutoffsCm: [80, 105, 130, 160],
            weightA: nil,
            weightB: nil,
            colorHex: 0x5B6B43,
            habitat: "Cold, deep water over sand, gravel or mud along banks, slopes and deep channels.",
            range: "Labrador and Greenland to the Gulf of Maine, rarely south to Virginia.",
            regions: [.atlanticCanada, .northeast]
        ),
    ]
}
