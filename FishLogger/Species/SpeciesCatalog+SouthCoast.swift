import Foundation

// Inshore saltwater fish of the Carolinas, Florida and the Gulf coast to Texas. Weights only where a published length-weight relationship is known.
extension SpeciesCatalog {
    static let southCoastSpecies: [Species] = [

        // MARK: Inshore

        Species(
            id: "red_drum",
            commonName: "Red drum",
            otherNames: ["Redfish", "Red", "Channel bass", "Puppy drum", "Bull red", "Spottail bass"],
            scientificName: "Sciaenops ocellatus",
            group: .inshore,
            summary: "Copper-coloured drum of marshes, flats and surf, often seen tailing in water barely deep enough to cover it. Big breeding fish, called bull reds, school along beaches and passes in late summer and fall.",
            idTips: [
                "One or more black spots near the base of the tail.",
                "No chin whiskers; a black drum has many short ones.",
                "Copper to bronze back and sides fading to a white belly."
            ],
            lookalikes: ["black_drum"],
            traits: [.torpedoBody, .spinyDorsal, .squareTail, .tailSpot, .goldenColor],
            sizeCutoffsCm: [45, 60, 75, 100],
            weightA: -5.276,
            weightB: 3.110,
            colorHex: 0xC0663C,
            habitat: "Marsh creeks, grass flats, oyster bars and surf; big spawning fish also use passes and nearshore water.",
            range: "Atlantic coast from the Chesapeake Bay to Florida and around the Gulf to Texas and Mexico.",
            regions: [.midAtlantic, .southeast, .florida, .southernPlains]
        ),
        Species(
            id: "black_drum",
            commonName: "Black drum",
            otherNames: ["Drum", "Sea drum"],
            scientificName: "Pogonias cromis",
            group: .inshore,
            summary: "Heavy, deep-bodied drum that crushes oysters, clams and crabs with its throat teeth and can top 40 kg. Small ones are good eating; big ones are coarse and often wormy.",
            idTips: [
                "Many short whiskers under the chin; red drum and sheepshead have none.",
                "No black tail spot; young fish have four or five broad dark bars.",
                "Tall, arched back; big fish turn grey to black and lose the bars."
            ],
            lookalikes: ["red_drum", "sheepshead", "freshwater_drum"],
            traits: [.deepFlatBody, .spinyDorsal, .squareTail, .barbels, .verticalBars],
            sizeCutoffsCm: [35, 50, 70, 100],
            weightA: nil,
            weightB: nil,
            colorHex: 0x726C7E,
            habitat: "Bays, oyster reefs, channels, piers and surf over mud, sand or shell.",
            range: "Common from Delaware Bay to Florida and around the Gulf to Texas and Mexico.",
            regions: [.northeast, .midAtlantic, .southeast, .florida, .southernPlains]
        ),
        Species(
            id: "spotted_seatrout",
            commonName: "Spotted seatrout",
            otherNames: ["Speckled trout", "Speck", "Trout", "Spotted weakfish", "Gator trout"],
            scientificName: "Cynoscion nebulosus",
            group: .inshore,
            summary: "Spotted drum of grass flats, bays and marshes, and a top inshore target from Virginia to Texas. Not a true trout; the biggest ones are called gator trout.",
            idTips: [
                "Bold, round black spots on the back, second dorsal fin and tail.",
                "A weakfish has small speckles in slanting rows and unspotted fins.",
                "Sand and silver seatrouts are plain, with no clear spots."
            ],
            lookalikes: ["weakfish"],
            traits: [.torpedoBody, .spinyDorsal, .squareTail, .darkSpotsLightBody, .silverColor],
            sizeCutoffsCm: [36, 46, 56, 68],
            weightA: -5.130,
            weightB: 3.050,
            colorHex: 0x547884,
            habitat: "Seagrass flats, shallow bays, marsh edges and tidal creeks, moving to deeper channels in cold weather.",
            range: "Atlantic coast from the Chesapeake Bay to Florida and around the Gulf to Texas and Mexico.",
            regions: [.midAtlantic, .southeast, .florida, .southernPlains]
        ),
        Species(
            id: "common_snook",
            commonName: "Common snook",
            otherNames: ["Snook", "Linesider", "Robalo"],
            scientificName: "Centropomus undecimalis",
            group: .inshore,
            summary: "Hard-fighting ambush predator of mangroves, docks, passes and beaches, and the signature inshore fish of South Florida. Very sensitive to cold; hard freezes can kill many.",
            idTips: [
                "Bold black lateral line from the gill cover to the end of the tail.",
                "Sloping forehead and a jutting lower jaw on a long, silver body.",
                "Two separate dorsal fins; grows far bigger than Florida's other snook."
            ],
            lookalikes: [],
            traits: [.torpedoBody, .spinyDorsal, .twoSeparateDorsals, .darkLateralLine, .forkedTail, .silverColor],
            sizeCutoffsCm: [50, 71, 84, 100],
            weightA: -5.150,
            weightB: 3.020,
            colorHex: 0x849060,
            habitat: "Mangrove shorelines, docks, bridges, inlets, beaches and tidal rivers, often well into fresh water.",
            range: "Central and South Florida and the lower Texas coast, south through the Caribbean to Brazil.",
            regions: [.florida, .southernPlains]
        ),
        Species(
            id: "tarpon",
            commonName: "Tarpon",
            otherNames: ["Silver king", "Poon", "Sábalo"],
            scientificName: "Megalops atlanticus",
            group: .inshore,
            summary: "Huge, high-jumping fish called the silver king, able to gulp air at the surface to live in low-oxygen water. In Florida it is catch and release only, except with a tarpon tag for a record attempt.",
            idTips: [
                "Last ray of the dorsal fin trails as a long, thin thread.",
                "Huge, plate-like silver scales; a ladyfish's scales are tiny.",
                "Big upturned mouth with the lower jaw jutting past the upper."
            ],
            lookalikes: ["ladyfish"],
            traits: [.largeMouth, .silverColor, .forkedTail],
            sizeCutoffsCm: [60, 110, 160, 200],
            weightA: nil,
            weightB: nil,
            colorHex: 0x6C84A8,
            habitat: "Passes, bridges, beaches, bays and backcountry creeks; young fish live in marsh ponds and canals.",
            range: "Year round in South Florida; summer runs reach the Texas coast and the Carolinas.",
            regions: [.southeast, .florida, .southernPlains]
        ),
        Species(
            id: "bonefish",
            commonName: "Bonefish",
            otherNames: ["Bones", "Grey ghost", "Gray ghost"],
            scientificName: "Albula vulpes",
            group: .inshore,
            summary: "Fast, wary fish of shallow tropical flats, prized for long, blistering runs on fly and light spinning gear. Catch and release only in Florida.",
            idTips: [
                "Cone-shaped snout overhanging a small mouth set underneath.",
                "Faint dark streaks along the upper sides between the scale rows.",
                "Makes long runs but rarely jumps; a ladyfish leaps again and again."
            ],
            lookalikes: ["ladyfish"],
            traits: [.torpedoBody, .smallMouth, .silverColor, .forkedTail],
            sizeCutoffsCm: [45, 58, 70, 80],
            weightA: nil,
            weightB: nil,
            colorHex: 0x668A9C,
            habitat: "Shallow sand, mud and grass flats, where they tail while feeding, and the channels beside them.",
            range: "In the US mostly Biscayne Bay and the Florida Keys; also the Bahamas and Caribbean.",
            regions: [.florida]
        ),
        Species(
            id: "permit",
            commonName: "Permit",
            otherNames: [],
            scientificName: "Trachinotus falcatus",
            group: .inshore,
            summary: "Big, deep-bodied relative of the pompano, famous as one of the hardest flats fish to fool on a fly. Also caught on wrecks and reefs, often on live crabs.",
            idTips: [
                "17 to 21 soft dorsal rays; a pompano has 22 to 27.",
                "Very deep, almost diamond-shaped body; a pompano is slimmer.",
                "Adults often weigh 9 kg or more; a pompano rarely tops 3 kg."
            ],
            lookalikes: ["florida_pompano"],
            traits: [.deepFlatBody, .silverColor, .forkedTail],
            sizeCutoffsCm: [45, 65, 85, 105],
            weightA: nil,
            weightB: nil,
            colorHex: 0x426678,
            habitat: "Shallow flats, channel edges, and nearshore wrecks and reefs.",
            range: "In the US mostly South Florida and the Keys; also the Bahamas and Caribbean.",
            regions: [.florida]
        ),
        Species(
            id: "sheepshead",
            commonName: "Sheepshead",
            otherNames: ["Convict fish", "Sheepshead porgy", "Sheepie"],
            scientificName: "Archosargus probatocephalus",
            group: .inshore,
            summary: "Barred saltwater porgy that crunches barnacles, oysters and crabs off pilings and rocks, and a famous bait thief. Not the freshwater drum that shares the name in the Midwest.",
            idTips: [
                "Five to seven bold black bars on silver-grey sides.",
                "Human-like front teeth and no chin whiskers, unlike a black drum.",
                "Strong dorsal spines; a scup is smaller and has no bold bars."
            ],
            lookalikes: ["black_drum", "scup", "freshwater_drum"],
            traits: [.deepFlatBody, .smallMouth, .spinyDorsal, .verticalBars, .forkedTail],
            sizeCutoffsCm: [28, 36, 45, 55],
            weightA: -4.660,
            weightB: 2.980,
            colorHex: 0x48666C,
            habitat: "Pilings, jetties, bridges, docks, oyster bars and nearshore reefs; gathers offshore to spawn in late winter.",
            range: "Atlantic coast from the Chesapeake Bay to Florida and around the Gulf to Texas; strays north to Nova Scotia.",
            regions: [.midAtlantic, .southeast, .florida, .southernPlains]
        ),
        Species(
            id: "southern_flounder",
            commonName: "Southern flounder",
            otherNames: ["Flounder", "Doormat"],
            scientificName: "Paralichthys lethostigma",
            group: .inshore,
            summary: "Big-mouthed flatfish that ambushes shrimp and baitfish from the bottom of bays, marshes and tidal rivers, often well up into fresh water. Runs out through the passes to spawn in fall.",
            idTips: [
                "No ringed eyespots, only faint dark and pale blotches.",
                "A summer flounder has five eyespots; a Gulf flounder has three.",
                "Eyes on the left side and a big, toothy mouth reaching past the eye."
            ],
            lookalikes: ["summer_flounder"],
            traits: [.eyesOnOneSide, .deepFlatBody, .largeMouth, .longDorsalFin, .darkMottling],
            sizeCutoffsCm: [35, 43, 53, 64],
            weightA: nil,
            weightB: nil,
            colorHex: 0x6C543C,
            habitat: "Soft mud and sand in bays, marshes, tidal creeks and rivers, moving to passes and nearshore water in fall.",
            range: "Atlantic coast from North Carolina to northern Florida, and the Gulf coast from southwest Florida to Texas.",
            regions: [.southeast, .florida, .southernPlains]
        ),
        Species(
            id: "florida_pompano",
            commonName: "Florida pompano",
            otherNames: ["Pompano", "Common pompano"],
            scientificName: "Trachinotus carolinus",
            group: .inshore,
            summary: "Small, fast silver jack of the surf, prized as one of the best eating fish on the coast. Caught from beaches and piers on sand fleas, shrimp and small jigs.",
            idTips: [
                "22 to 27 soft dorsal rays; a permit has 17 to 21.",
                "Yellow throat and belly, with yellowish pelvic and anal fins.",
                "Slimmer than a permit, and rarely over 3 kg."
            ],
            lookalikes: ["permit"],
            traits: [.deepFlatBody, .silverColor, .forkedTail],
            sizeCutoffsCm: [25, 32, 40, 48],
            weightA: nil,
            weightB: nil,
            colorHex: 0xAE8436,
            habitat: "Sandy surf zones, inlets and passes, and nearby grass flats, moving with the water temperature.",
            range: "Atlantic coast from Virginia to Florida and around the Gulf to Texas; most common in Florida.",
            regions: [.southeast, .florida, .southernPlains]
        ),
        Species(
            id: "jack_crevalle",
            commonName: "Crevalle jack",
            otherNames: ["Jack crevalle", "Jack", "Common jack"],
            scientificName: "Caranx hippos",
            group: .inshore,
            summary: "Powerful, bulldogging jack that crashes bait in big schools and fights all the way to the boat. Strong tasting, so most are released.",
            idTips: [
                "Black spot on the gill cover edge and another low on the pectoral fin.",
                "Steep, blunt forehead and a row of hard scutes before the tail.",
                "No dark band through the eye; an amberjack has one."
            ],
            lookalikes: ["greater_amberjack", "permit"],
            traits: [.deepFlatBody, .spinyDorsal, .twoSeparateDorsals, .forkedTail, .goldenColor],
            sizeCutoffsCm: [35, 55, 75, 95],
            weightA: nil,
            weightB: nil,
            colorHex: 0xA27842,
            habitat: "Bays, passes, inlets, beaches, bridges and canals; big adults also roam nearshore reefs.",
            range: "Atlantic coast from the Carolinas to Florida and around the Gulf to Texas; young fish stray north in summer.",
            regions: [.southeast, .florida, .southernPlains]
        ),
        Species(
            id: "ladyfish",
            commonName: "Ladyfish",
            otherNames: ["Skipjack", "Poor man's tarpon", "Tenpounder"],
            scientificName: "Elops saurus",
            group: .inshore,
            summary: "Slim, silver relative of the tarpon that jumps wildly and often throws the hook. Common in bays and passes, and widely used as cut bait.",
            idTips: [
                "Slim, round silver body with tiny scales; a tarpon's scales are huge.",
                "Mouth at the tip of the snout, not tucked under like a bonefish's.",
                "No long thread on the dorsal fin, unlike a tarpon."
            ],
            lookalikes: ["tarpon", "bonefish"],
            traits: [.torpedoBody, .largeMouth, .silverColor, .forkedTail],
            sizeCutoffsCm: [30, 40, 50, 60],
            weightA: nil,
            weightB: nil,
            colorHex: 0x54908A,
            habitat: "Bays, lagoons, passes and surf, often in big schools under lights at night.",
            range: "Atlantic coast from the Carolinas to Florida and around the Gulf to Texas; strays north in summer.",
            regions: [.southeast, .florida, .southernPlains]
        ),
        Species(
            id: "cobia",
            commonName: "Cobia",
            otherNames: ["Ling", "Lemonfish", "Crab eater", "Black kingfish"],
            scientificName: "Rachycentron canadum",
            group: .inshore,
            summary: "Big, curious, shark-like fish that cruises near buoys, wrecks, rays and turtles, and is often caught by sight casting. A prized table fish that can grow past 50 kg.",
            idTips: [
                "Row of short, separate spines in front of the dorsal fin.",
                "Wide, flat head with a jutting lower jaw.",
                "Dark stripe from snout to tail between two pale stripes."
            ],
            lookalikes: [],
            traits: [.torpedoBody, .spinyDorsal, .darkLateralLine, .forkedTail],
            sizeCutoffsCm: [76, 100, 122, 145],
            weightA: nil,
            weightB: nil,
            colorHex: 0x6C5A54,
            habitat: "Nearshore and inshore water around buoys, piers, wrecks, channel markers and big bays.",
            range: "Atlantic coast from the Chesapeake Bay to Florida and around the Gulf to Texas; spring runs follow the coast north.",
            regions: [.midAtlantic, .southeast, .florida, .southernPlains]
        ),
        Species(
            id: "spanish_mackerel",
            commonName: "Spanish mackerel",
            otherNames: ["Spanish", "Spanish mack"],
            scientificName: "Scomberomorus maculatus",
            group: .inshore,
            summary: "Fast, toothy mackerel that tears through bait schools along beaches, piers and inlets from spring to fall. Good eating when fresh.",
            idTips: [
                "Gold oval spots on silver sides; an Atlantic mackerel has wavy dark bars.",
                "Front of the first dorsal fin is black; a king's is plain grey.",
                "Lateral line slopes down gently; a king's dips sharply under the second dorsal."
            ],
            lookalikes: ["king_mackerel", "atlantic_mackerel", "bluefish"],
            traits: [.torpedoBody, .spinyDorsal, .twoSeparateDorsals, .finlets, .forkedTail, .silverColor],
            sizeCutoffsCm: [35, 48, 60, 72],
            weightA: nil,
            weightB: nil,
            colorHex: 0x3672A8,
            habitat: "Beaches, piers, inlets and nearshore water, chasing schools of small bait near the surface.",
            range: "Atlantic coast from the Chesapeake Bay to Florida and around the Gulf to Texas, moving north in summer.",
            regions: [.midAtlantic, .southeast, .florida, .southernPlains]
        ),
        Species(
            id: "tripletail",
            commonName: "Tripletail",
            otherNames: ["Blackfish", "Atlantic tripletail"],
            scientificName: "Lobotes surinamensis",
            group: .inshore,
            summary: "Odd, deep-bodied fish that floats on its side under buoys, trap floats and weed lines, looking like a drifting leaf. Sight casting to them is a summer favourite, and they are excellent eating.",
            idTips: [
                "Rounded soft dorsal and anal fins sit back by the tail, like three tails.",
                "Mottled brown, yellow or nearly black, and often floats on its side.",
                "Deep, flat body with a concave head and a saw-edged gill cover."
            ],
            lookalikes: [],
            traits: [.deepFlatBody, .spinyDorsal, .roundedTail, .darkMottling],
            sizeCutoffsCm: [35, 46, 60, 75],
            weightA: nil,
            weightB: nil,
            colorHex: 0xAE784E,
            habitat: "Floating cover in bays, sounds and nearshore water, such as buoys, trap floats, pilings and weed lines.",
            range: "Atlantic coast from the Carolinas to Florida and around the Gulf to Texas; a few reach the Chesapeake Bay in summer.",
            regions: [.southeast, .florida, .southernPlains]
        ),
        Species(
            id: "gray_snapper",
            commonName: "Gray snapper",
            otherNames: ["Mangrove snapper", "Mango", "Grey snapper"],
            scientificName: "Lutjanus griseus",
            group: .inshore,
            summary: "Wary, sharp-toothed snapper of mangroves, docks and bridges, and the snapper most often caught inshore. Big adults move out to nearshore reefs and wrecks.",
            idTips: [
                "Grey to coppery body; a red snapper is rosy pink to red all over.",
                "No black spot on the side, unlike lane, mutton and young red snapper.",
                "Dark band from the snout through the eye, clearest on young fish."
            ],
            lookalikes: ["red_snapper"],
            traits: [.spinyDorsal, .longDorsalFin, .squareTail],
            sizeCutoffsCm: [25, 33, 43, 55],
            weightA: nil,
            weightB: nil,
            colorHex: 0x965A4E,
            habitat: "Mangrove shorelines, docks, bridges, seawalls and oyster bars; bigger fish on nearshore reefs and wrecks.",
            range: "Florida and the Gulf coast to Texas, and less often north along the Atlantic coast to the Carolinas.",
            regions: [.southeast, .florida, .southernPlains]
        ),
    ]
}
