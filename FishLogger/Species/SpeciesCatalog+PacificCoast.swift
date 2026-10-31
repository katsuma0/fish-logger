import Foundation

// Saltwater fish of the Pacific coast, Alaska to southern California. Billfish sizes are lower jaw fork length, the rest total length; weights only where a published length-weight relationship is known.
extension SpeciesCatalog {
    static let pacificCoastSpecies: [Species] = [

        // MARK: Bottomfish

        Species(
            id: "pacific_halibut",
            commonName: "Pacific halibut",
            otherNames: ["Halibut", "Barn door", "Chicken", "Flétan du Pacifique"],
            scientificName: "Hippoglossus stenolepis",
            group: .bottomfish,
            summary: "Huge right-eyed flatfish and the top bottom fish target from Oregon to Alaska, able to top 200 kg. Big fish are called barn doors; small eating-size ones are chickens.",
            idTips: [
                "Jaw stops below the eye; a California halibut's reaches well past it.",
                "Eyes nearly always on the right side, and a slightly crescent-shaped tail.",
                "Lateral line arches high over the pectoral fin; an arrowtooth flounder's is nearly straight."
            ],
            lookalikes: ["california_halibut"],
            traits: [.eyesOnOneSide, .smoothSkin, .darkMottling],
            sizeCutoffsCm: [70, 90, 120, 150],
            weightA: -5.618,
            weightB: 3.240,
            colorHex: 0x80693D,
            habitat: "Sand, gravel and mud bottoms, from shallow bays out to deep offshore banks.",
            range: "Northern California to the Bering Sea, most common from BC through the Gulf of Alaska.",
            regions: [.california, .pacificNorthwest, .britishColumbia, .alaska]
        ),
        Species(
            id: "lingcod",
            commonName: "Lingcod",
            otherNames: ["Ling", "Ling cod", "Morue-lingue"],
            scientificName: "Ophiodon elongatus",
            group: .bottomfish,
            summary: "Big-mouthed, toothy ambush predator of rocky reefs and kelp, and the largest of the greenlings rather than a true cod. Often grabs a hooked rockfish on the way up.",
            idTips: [
                "Huge mouth past the eye with fang-like teeth; a kelp greenling's is small.",
                "Long, slim body; a cabezon is stout and scaleless, with flaps over the eyes.",
                "No chin whisker; a Pacific cod has one and three separate dorsal fins."
            ],
            lookalikes: ["kelp_greenling", "cabezon", "pacific_cod"],
            traits: [.torpedoBody, .largeMouth, .spinyDorsal, .longDorsalFin, .darkMottling],
            sizeCutoffsCm: [56, 70, 85, 100],
            weightA: nil,
            weightB: nil,
            colorHex: 0x658060,
            habitat: "Rocky reefs, kelp beds and rock piles, from shallow water to well over 100 m deep.",
            range: "Gulf of Alaska to Baja California, most common from northern California to BC.",
            regions: [.california, .pacificNorthwest, .britishColumbia, .alaska]
        ),
        Species(
            id: "black_rockfish",
            commonName: "Black rockfish",
            otherNames: ["Black snapper", "Black sea bass", "Sébaste noir"],
            scientificName: "Sebastes melanops",
            group: .bottomfish,
            summary: "Schooling rockfish that feeds in mid-water over shallow reefs, often right up to the surface. A staple of nearshore trips from northern California to Alaska, and good sport on light jigs and flies.",
            idTips: [
                "Jaw reaches the rear of the eye or beyond; a blue rockfish's stops at mid-eye.",
                "Dark spots on the spiny dorsal fin; a blue rockfish's dorsal is plain.",
                "Grey-black back over paler, mottled grey sides and a white belly."
            ],
            lookalikes: [],
            traits: [.largeMouth, .spinyDorsal, .squareTail, .darkMottling],
            sizeCutoffsCm: [28, 36, 44, 52],
            weightA: nil,
            weightB: nil,
            colorHex: 0x5C667A,
            habitat: "Shallow rocky reefs and kelp beds, often schooling well off the bottom.",
            range: "Southern California to the Aleutian Islands, rare south of Point Conception and most common from northern California to BC.",
            regions: [.california, .pacificNorthwest, .britishColumbia, .alaska]
        ),
        Species(
            id: "yelloweye_rockfish",
            commonName: "Yelloweye rockfish",
            otherNames: ["Yelloweye", "Red snapper", "Sébaste aux yeux jaunes"],
            scientificName: "Sebastes ruberrimus",
            group: .bottomfish,
            summary: "Large, slow-growing rockfish of deep rocky reefs that can live more than 100 years. Closed to retention in many areas, and any you release should go back down on a descending device.",
            idTips: [
                "Bright yellow eye on an orange-red to orange-yellow body.",
                "Rough, raspy ridges on top of the head; a vermilion has none.",
                "Black-tipped fins and a rounded tail; young fish have white side stripes."
            ],
            lookalikes: ["vermilion_rockfish"],
            traits: [.largeMouth, .spinyDorsal, .roundedTail],
            sizeCutoffsCm: [35, 45, 55, 65],
            weightA: nil,
            weightB: nil,
            colorHex: 0xB25B3B,
            habitat: "Rocky reefs, boulder fields and ledges, mostly deeper than 50 m.",
            range: "Northern Baja California to the Aleutian Islands, most common from Oregon to southeast Alaska.",
            regions: [.california, .pacificNorthwest, .britishColumbia, .alaska]
        ),
        Species(
            id: "vermilion_rockfish",
            commonName: "Vermilion rockfish",
            otherNames: ["Vermilion", "Red snapper", "Rasher"],
            scientificName: "Sebastes miniatus",
            group: .bottomfish,
            summary: "Heavy-bodied, deep red rockfish of rocky reefs and a prized eating fish in California, where it is often called red snapper. A near-identical deep-water fish, the sunset rockfish, is now treated as a separate species.",
            idTips: [
                "Rough, scaly underside of the lower jaw; a canary rockfish's is smooth.",
                "No raspy ridges on top of the head; a yelloweye has them.",
                "Deep red sides mottled with grey, and no bright yellow eye."
            ],
            lookalikes: ["yelloweye_rockfish"],
            traits: [.spinyDorsal, .squareTail, .darkMottling],
            sizeCutoffsCm: [30, 40, 50, 60],
            weightA: nil,
            weightB: nil,
            colorHex: 0xAD3949,
            habitat: "Rocky reefs and high-relief rock, mostly 50 to 150 m deep; young fish live shallower.",
            range: "Baja California to Washington and rarely BC, most common in California.",
            regions: [.california, .pacificNorthwest]
        ),
        Species(
            id: "cabezon",
            commonName: "Cabezon",
            otherNames: ["Marbled sculpin"],
            scientificName: "Scorpaenichthys marmoratus",
            group: .bottomfish,
            summary: "Big, scaleless sculpin of rocky shores and kelp, caught from jetties and rocks as well as boats. The flesh is good eating, but the roe is poisonous.",
            idTips: [
                "No scales; the skin is smooth and leathery.",
                "Branched fleshy flap above each eye and a flap on the snout.",
                "Huge, wide head and big fan-like pectoral fins; a lingcod is long and slim."
            ],
            lookalikes: ["lingcod", "kelp_greenling"],
            traits: [.spinyDorsal, .smoothSkin, .darkMottling],
            sizeCutoffsCm: [38, 46, 56, 66],
            weightA: nil,
            weightB: nil,
            colorHex: 0x946E54,
            habitat: "Rocky reefs, kelp beds, jetties and tide pools, mostly in shallow water.",
            range: "Southeast Alaska to Baja California, most common from central California to BC.",
            regions: [.california, .pacificNorthwest, .britishColumbia]
        ),
        Species(
            id: "kelp_greenling",
            commonName: "Kelp greenling",
            otherNames: ["Greenling", "Sea trout"],
            scientificName: "Hexagrammos decagrammus",
            group: .bottomfish,
            summary: "Colourful, mid-sized fish of shallow rocky reefs and kelp, often caught from jetties and rocky shores. Males and females are coloured so differently they look like two kinds of fish.",
            idTips: [
                "Small mouth; a lingcod's is huge, reaching past the eye.",
                "Males: blue patches on the front half, each ringed by small rusty spots.",
                "Females: covered in small red-brown or gold spots, with yellow-orange fins."
            ],
            lookalikes: ["lingcod", "cabezon"],
            traits: [.smallMouth, .longDorsalFin, .darkSpotsLightBody, .lightSpotsDarkBody],
            sizeCutoffsCm: [25, 32, 38, 45],
            weightA: nil,
            weightB: nil,
            colorHex: 0x3A8294,
            habitat: "Shallow rocky reefs, kelp beds and jetties, usually less than 20 m deep.",
            range: "Aleutian Islands to southern California, uncommon south of Point Conception.",
            regions: [.california, .pacificNorthwest, .britishColumbia, .alaska]
        ),
        Species(
            id: "pacific_cod",
            commonName: "Pacific cod",
            otherNames: ["Cod", "Grey cod", "True cod", "Morue du Pacifique"],
            scientificName: "Gadus macrocephalus",
            group: .bottomfish,
            summary: "Heavy-headed cod of the North Pacific, often caught while jigging for halibut and rockfish, especially in Alaska. Mild, white flesh makes it a favourite for fish and chips.",
            idTips: [
                "Three separate dorsal fins and two anal fins; a lingcod has one long dorsal.",
                "Long chin whisker; a walleye pollock's is tiny or missing.",
                "Brown to grey back with many dark spots and a pale lateral line."
            ],
            lookalikes: ["lingcod"],
            traits: [.barbels, .squareTail, .darkSpotsLightBody],
            sizeCutoffsCm: [45, 60, 75, 90],
            weightA: nil,
            weightB: nil,
            colorHex: 0x8F7C63,
            habitat: "Sand, mud and gravel bottoms near reefs and drop-offs, from nearshore water to the edge of the shelf.",
            range: "Oregon to the Bering Sea and across to Asia, most common in BC and Alaska.",
            regions: [.pacificNorthwest, .britishColumbia, .alaska]
        ),
        Species(
            id: "california_sheephead",
            commonName: "California sheephead",
            otherNames: ["Sheephead"],
            scientificName: "Bodianus pulcher",
            group: .bottomfish,
            summary: "Large wrasse of kelp forests and rocky reefs in southern California that crushes urchins, crabs and snails with big canine teeth. All start life as females, and many of the largest later become males with a black head and tail.",
            idTips: [
                "Males have a black head and tail, a red middle and a white chin.",
                "Females are an even pinkish red to brownish orange, with a white chin.",
                "Big, jutting canine teeth; large males grow a fleshy hump on the forehead."
            ],
            lookalikes: [],
            traits: [.smallMouth, .spinyDorsal, .longDorsalFin],
            sizeCutoffsCm: [30, 40, 50, 60],
            weightA: nil,
            weightB: nil,
            colorHex: 0xA85168,
            habitat: "Kelp forests and rocky reefs, from the shallows to about 50 m deep.",
            range: "Monterey Bay to Baja California and the Gulf of California, most common south of Point Conception.",
            regions: [.california]
        ),

        // MARK: Inshore

        Species(
            id: "kelp_bass",
            commonName: "Kelp bass",
            otherNames: ["Calico bass", "Calico", "Bull bass"],
            scientificName: "Paralabrax clathratus",
            group: .inshore,
            summary: "Classic kelp forest sport fish of southern California, caught on swimbaits, plastics and live bait along kelp edges and reefs. Slow-growing, so many anglers release the big ones.",
            idTips: [
                "Third to fifth dorsal spines about equal; a sand bass's third spine is longest.",
                "Pale, squarish blotches on a dark olive-brown back, like a checkerboard.",
                "No small dark spots all over; a spotted sand bass is covered in them."
            ],
            lookalikes: ["barred_sand_bass"],
            traits: [.spinyDorsal, .squareTail, .lightSpotsDarkBody],
            sizeCutoffsCm: [36, 42, 48, 55],
            weightA: nil,
            weightB: nil,
            colorHex: 0x627A42,
            habitat: "Kelp beds and rocky reefs from the surface to about 30 m deep.",
            range: "Southern California and Baja California; uncommon north of Point Conception.",
            regions: [.california]
        ),
        Species(
            id: "barred_sand_bass",
            commonName: "Barred sand bass",
            otherNames: ["Sand bass", "Sandy"],
            scientificName: "Paralabrax nebulifer",
            group: .inshore,
            summary: "Bass of sand flats near reefs in southern California, best known for big summer spawning schools. Its numbers have fallen in recent decades, so limits are now tighter.",
            idTips: [
                "Very long third dorsal spine, much taller than the fourth and fifth.",
                "Dark bars on grey-brown sides; no pale checkerboard on the back.",
                "No dark spots all over; a spotted sand bass is covered in them."
            ],
            lookalikes: ["kelp_bass"],
            traits: [.spinyDorsal, .squareTail, .verticalBars],
            sizeCutoffsCm: [36, 42, 48, 54],
            weightA: nil,
            weightB: nil,
            colorHex: 0x7F804C,
            habitat: "Sand flats near reefs, kelp and breakwaters, usually 5 to 30 m deep.",
            range: "Central California to Baja California, most common south of Point Conception.",
            regions: [.california]
        ),
        Species(
            id: "california_halibut",
            commonName: "California halibut",
            otherNames: ["Halibut", "Flattie"],
            scientificName: "Paralichthys californicus",
            group: .inshore,
            summary: "Large flatfish of sandy bays, harbours and beaches, caught from the surf, piers and drifting boats. Not a true halibut but a large-tooth flounder, and an aggressive hunter of small fish.",
            idTips: [
                "Big mouth with sharp teeth; the jaw reaches past the rear of the eye.",
                "Eyes on either side; a Pacific halibut's are nearly always on the right.",
                "Lateral line arches high over the pectoral fin; a sanddab's is nearly straight."
            ],
            lookalikes: ["pacific_halibut"],
            traits: [.eyesOnOneSide, .largeMouth, .darkMottling],
            sizeCutoffsCm: [56, 68, 82, 100],
            weightA: nil,
            weightB: nil,
            colorHex: 0x7A5A3B,
            habitat: "Sandy bottoms of bays, harbours, estuaries and open beaches, usually shallower than 30 m.",
            range: "Washington to southern Baja California, common from San Francisco Bay south.",
            regions: [.california]
        ),
        Species(
            id: "white_seabass",
            commonName: "White seabass",
            otherNames: ["Seabass", "Sea trout"],
            scientificName: "Atractoscion nobilis",
            group: .inshore,
            summary: "Big croaker of kelp beds and nearshore water in southern California, prized for its fight and its eating. Not a true sea bass; it is the largest croaker on the California coast.",
            idTips: [
                "Raised ridge along the belly, from the pelvic fins back to the vent.",
                "Dark blotch at the base of the pectoral fin.",
                "Young fish have three to six broad dark bars that fade with age."
            ],
            lookalikes: [],
            traits: [.torpedoBody, .spinyDorsal, .silverColor],
            sizeCutoffsCm: [71, 90, 110, 130],
            weightA: nil,
            weightB: nil,
            colorHex: 0x516A8F,
            habitat: "Kelp beds, rocky reefs and sandy flats near kelp, often hunting squid at night.",
            range: "Mostly southern California and Baja California; warm years bring fish north to San Francisco and beyond.",
            regions: [.california]
        ),
        Species(
            id: "barred_surfperch",
            commonName: "Barred surfperch",
            otherNames: ["Surfperch", "Surf perch", "Barred perch"],
            scientificName: "Amphistichus argenteus",
            group: .inshore,
            summary: "The most common surf fish on sandy California beaches, caught from shore on sand crabs, grubs and small lures. Like all surfperch, it gives birth to live young.",
            idTips: [
                "Bronze to yellow-brown bars and spots on silver sides.",
                "No red on the fins or tail; a redtail surfperch has red fins.",
                "Deep, oval body with a small mouth and a forked tail."
            ],
            lookalikes: [],
            traits: [.deepFlatBody, .smallMouth, .forkedTail, .verticalBars],
            sizeCutoffsCm: [20, 25, 30, 35],
            weightA: nil,
            weightB: nil,
            colorHex: 0x807D3D,
            habitat: "Sandy surf zones of open beaches, feeding in troughs and holes close to shore.",
            range: "Bodega Bay to central Baja California, most common in central and southern California.",
            regions: [.california]
        ),

        // MARK: Offshore

        Species(
            id: "california_yellowtail",
            commonName: "California yellowtail",
            otherNames: ["Yellowtail", "Yellowtail amberjack", "Mossback", "Firecracker"],
            scientificName: "Seriola dorsalis",
            group: .offshore,
            summary: "Hard-pulling jack of southern California's islands, kelp paddies and banks, and a summer favourite on day boats. Dives for rocks and kelp when hooked.",
            idTips: [
                "Brassy yellow stripe from the snout to a bright yellow tail.",
                "No dark band slanting up through the eye; an amberjack has one.",
                "No finlets before the tail; tunas and bonito have a row of them."
            ],
            lookalikes: ["greater_amberjack"],
            traits: [.torpedoBody, .spinyDorsal, .twoSeparateDorsals, .forkedTail],
            sizeCutoffsCm: [60, 75, 90, 105],
            weightA: nil,
            weightB: nil,
            colorHex: 0x8F6D2F,
            habitat: "Open water around islands, kelp beds, offshore banks and floating kelp paddies.",
            range: "Southern California and Mexico, moving north past Point Conception in warm years.",
            regions: [.california]
        ),
        Species(
            id: "pacific_bonito",
            commonName: "Pacific bonito",
            otherNames: ["Bonito", "Bonehead", "California bonito"],
            scientificName: "Sarda lineolata",
            group: .offshore,
            summary: "Fast, schooling relative of the tunas that hits jigs, flies and live bait near the surface along the southern California coast. In warm years it crowds harbours, piers and jetties as well as open water.",
            idTips: [
                "Dark stripes slant up and back across the upper back and sides.",
                "Plain silver belly; a skipjack tuna has dark stripes on its belly.",
                "Strong, pointed teeth in both jaws; a tuna's teeth are small."
            ],
            lookalikes: ["pacific_bluefin_tuna"],
            traits: [.torpedoBody, .spinyDorsal, .forkedTail, .finlets],
            sizeCutoffsCm: [45, 55, 65, 75],
            weightA: nil,
            weightB: nil,
            colorHex: 0x595F94,
            habitat: "Nearshore and open water, often around kelp beds, harbour mouths, piers and bait schools.",
            range: "Gulf of Alaska to Baja California, but common only south of Point Conception except in warm years.",
            regions: [.california]
        ),
        Species(
            id: "pacific_bluefin_tuna",
            commonName: "Pacific bluefin tuna",
            otherNames: ["Bluefin", "Bluefin tuna"],
            scientificName: "Thunnus orientalis",
            group: .offshore,
            summary: "Huge, powerful tuna that spawns near Japan and crosses the Pacific to feed off southern California and Baja California. Recent seasons have produced fish over 100 kg.",
            idTips: [
                "Very short pectoral fin that ends before the gap between the dorsal fins.",
                "Dusky second dorsal fin; a yellowfin's is bright yellow and often long.",
                "Deep, heavy body; grows far bigger than an albacore or bonito."
            ],
            lookalikes: ["yellowfin_tuna", "albacore", "pacific_bonito"],
            traits: [.torpedoBody, .spinyDorsal, .twoSeparateDorsals, .forkedTail, .finlets],
            sizeCutoffsCm: [80, 110, 140, 170],
            weightA: nil,
            weightB: nil,
            colorHex: 0x5D70A3,
            habitat: "Open ocean, often over banks, around islands and along temperature breaks.",
            range: "Spawns in the western Pacific; many cross to feed off southern California and Baja California, mostly from late spring to fall.",
            regions: [.california]
        ),
        Species(
            id: "striped_marlin",
            commonName: "Striped marlin",
            otherNames: ["Marlin", "Stripey"],
            scientificName: "Kajikia audax",
            group: .offshore,
            summary: "The marlin of southern California, showing up in warm summers and fall and often spotted finning at the surface before it is cast to. Most are released; size classes use lower jaw fork length.",
            idTips: [
                "Pointed first dorsal fin about as tall as the body is deep.",
                "Slim, flattened body; a blue marlin is rounder, heavier and has a lower dorsal.",
                "Round bill; a swordfish's is flat, and a sailfish has a tall sail."
            ],
            lookalikes: ["blue_marlin", "sailfish", "swordfish"],
            traits: [.torpedoBody, .billSnout, .forkedTail, .verticalBars],
            sizeCutoffsCm: [160, 180, 200, 220],
            weightA: nil,
            weightB: nil,
            colorHex: 0x3D60B8,
            habitat: "Open ocean, often near offshore banks, temperature breaks and bait schools.",
            range: "Warm and temperate Pacific and Indian oceans; reaches southern California in warm summers and fall.",
            regions: [.california]
        ),
    ]
}
