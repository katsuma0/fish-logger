import Foundation

// Canadian freshwater sport fish, plus a few common catches an Ontario angler will meet anyway.
// Weight coefficients are published standard weight (Ws) equations. Species without one we trust are
// nil, so the app shows no weight estimate rather than a guessed one.
extension SpeciesCatalog {
    static let canadianSpecies: [Species] = [

        // MARK: Walleye and perch

        Species(
            id: "walleye",
            commonName: "Walleye",
            otherNames: ["Pickerel", "Yellow pickerel", "Walleyed pike", "Doré jaune"],
            scientificName: "Sander vitreus",
            group: .perch,
            summary: "One of the most sought-after table fish in North America. Feeds most at dawn, dusk, and under cloud or chop.",
            idTips: [
                "White patch on the lower tip of the tail; sauger has none.",
                "Dark blotch at the rear of the spiny dorsal fin, no rows of spots.",
                "Big glassy eye and sharp canine teeth; a yellow perch has neither."
            ],
            lookalikes: ["sauger", "saugeye", "yellow_perch"],
            traits: [.torpedoBody, .spinyDorsal, .twoSeparateDorsals, .glassyEye, .whiteTailTip, .goldenColor, .forkedTail],
            sizeCutoffsCm: [30, 40, 55, 70],
            weightA: -5.453,
            weightB: 3.180,
            colorHex: 0x9A7F2E,
            habitat: "Large lakes and rivers, around rocky points, reefs, weed edges, and drop-offs.",
            range: "Native from Quebec to the Northwest Territories and south through the Mississippi basin; stocked across the West and South.",
            regions: [.britishColumbia, .prairies, .ontario, .quebec, .northernCanada, .pacificNorthwest, .california, .mountainWest, .southwest, .northernPlains, .southernPlains, .upperMidwest, .ohioValley, .northeast, .midAtlantic, .southeast]
        ),
        Species(
            id: "sauger",
            commonName: "Sauger",
            otherNames: ["Sand pike", "Doré noir"],
            scientificName: "Sander canadensis",
            group: .perch,
            summary: "Smaller cousin of the walleye that favours murky, flowing water. Eats just as well.",
            idTips: [
                "Rows of distinct black spots on the spiny dorsal fin.",
                "No white patch on the lower tail tip, or only a thin pale edge.",
                "Dark, blotchy saddles along the back and sides."
            ],
            lookalikes: ["walleye", "saugeye"],
            traits: [.torpedoBody, .spinyDorsal, .twoSeparateDorsals, .glassyEye, .darkMottling, .darkSpotsLightBody, .forkedTail],
            sizeCutoffsCm: [25, 33, 40, 48],
            weightA: -5.492,
            weightB: 3.187,
            colorHex: 0x7A6644,
            habitat: "Turbid rivers and large shallow lakes, over sand and gravel, often in current.",
            range: "Native from the St. Lawrence west to Alberta and south through the Mississippi basin to the Gulf states.",
            regions: [.prairies, .ontario, .quebec, .mountainWest, .northernPlains, .southernPlains, .upperMidwest, .ohioValley, .midAtlantic, .southeast]
        ),
        Species(
            id: "yellow_perch",
            commonName: "Yellow perch",
            otherNames: ["Perch", "Lake perch", "Perchaude"],
            scientificName: "Perca flavescens",
            group: .perch,
            summary: "Schooling panfish found almost everywhere walleye are. Good eating and the main ice fishing target on many lakes.",
            idTips: [
                "Six to eight dark vertical bars over a yellow to gold body.",
                "No canine teeth and no glassy eye, unlike a young walleye.",
                "Lower fins often orange, brightest in spring."
            ],
            lookalikes: ["walleye", "white_perch"],
            traits: [.spinyDorsal, .twoSeparateDorsals, .verticalBars, .goldenColor, .forkedTail],
            sizeCutoffsCm: [15, 20, 25, 32],
            weightA: -5.386,
            weightB: 3.230,
            colorHex: 0x7D8B2B,
            habitat: "Weedy bays, flats, and open basins of lakes and slow rivers; schools roam over sand and mud.",
            range: "Native from the Maritimes to the Northwest Territories and south to the Ohio basin and the Carolinas; introduced in the West.",
            regions: [.britishColumbia, .prairies, .ontario, .quebec, .atlanticCanada, .northernCanada, .pacificNorthwest, .mountainWest, .northernPlains, .upperMidwest, .ohioValley, .northeast, .midAtlantic, .southeast]
        ),

        // MARK: Pike and muskie

        Species(
            id: "northern_pike",
            commonName: "Northern pike",
            otherNames: ["Pike", "Jackfish", "Jack", "Grand brochet"],
            scientificName: "Esox lucius",
            group: .pike,
            summary: "Common, aggressive predator in weedy lakes across the North. The teeth cut, so use long pliers or a jaw spreader.",
            idTips: [
                "Rows of pale, bean-shaped spots on a dark green body.",
                "Cheek fully scaled, lower half of the gill cover bare.",
                "Five or fewer pores under each side of the jaw; muskie has six or more."
            ],
            lookalikes: ["muskellunge", "tiger_muskie", "chain_pickerel"],
            traits: [.torpedoBody, .duckbillSnout, .largeMouth, .lightSpotsDarkBody, .forkedTail],
            sizeCutoffsCm: [45, 60, 80, 100],
            weightA: -5.437,
            weightB: 3.096,
            colorHex: 0x3E6E3F,
            habitat: "Weedy bays, shallow flats, and river backwaters; big fish move to cooler, deeper water in summer.",
            range: "Native from Labrador to Alaska and south to the Ohio basin and northern Plains; introduced in parts of the West.",
            regions: [.britishColumbia, .prairies, .ontario, .quebec, .atlanticCanada, .northernCanada, .alaska, .pacificNorthwest, .mountainWest, .southwest, .northernPlains, .upperMidwest, .ohioValley, .northeast]
        ),
        Species(
            id: "muskellunge",
            commonName: "Muskellunge",
            otherNames: ["Muskie", "Musky", "Lunge", "Maskinongé"],
            scientificName: "Esox masquinongy",
            group: .pike,
            summary: "The top predator in the lakes it lives in, slow to catch and nearly always released. Heavy gear and a big net keep fish in good shape.",
            idTips: [
                "Dark marks on a light olive to tan body; a pike is the reverse.",
                "Six or more pores under each side of the lower jaw.",
                "Lower half of both the cheek and the gill cover bare."
            ],
            lookalikes: ["northern_pike", "tiger_muskie", "chain_pickerel"],
            traits: [.torpedoBody, .duckbillSnout, .largeMouth, .darkSpotsLightBody, .verticalBars, .forkedTail],
            sizeCutoffsCm: [70, 90, 110, 125],
            weightA: -6.066,
            weightB: 3.325,
            colorHex: 0x8A7550,
            habitat: "Large, clear lakes and rivers with weed beds, rocky shoals, and deep edges close by.",
            range: "Native to the St. Lawrence, Great Lakes, upper Mississippi, and Ohio basins; stocked elsewhere and spreading in New Brunswick.",
            regions: [.ontario, .quebec, .atlanticCanada, .northernPlains, .upperMidwest, .ohioValley, .northeast, .midAtlantic, .southeast]
        ),
        Species(
            id: "tiger_muskie",
            commonName: "Tiger muskie",
            otherNames: ["Tiger musky", "Tiger muskellunge"],
            scientificName: "Esox masquinongy × E. lucius",
            group: .pike,
            summary: "Cross of muskie and pike, found in the wild where both spawn and raised in some hatcheries. Grows fast and is usually sterile.",
            idTips: [
                "Sharp, broken tiger stripes or wavy bars over a light body.",
                "Tail lobes rounded at the tips; a muskie's are pointed.",
                "Jaw pore count in between, often five to eight per side and uneven."
            ],
            lookalikes: ["muskellunge", "northern_pike"],
            traits: [.torpedoBody, .duckbillSnout, .largeMouth, .verticalBars, .darkMottling, .forkedTail],
            sizeCutoffsCm: [65, 80, 95, 110],
            weightA: -6.126,
            weightB: 3.337,
            colorHex: 0x6A6B35,
            habitat: "Same water as muskie and pike: weedy bays, points, and river edges.",
            range: "Wild crosses turn up where pike and muskie share water; hatchery fish are stocked in many northern and western US lakes.",
            regions: [.ontario, .quebec, .pacificNorthwest, .mountainWest, .southwest, .upperMidwest, .northeast]
        ),
        Species(
            id: "chain_pickerel",
            commonName: "Chain pickerel",
            otherNames: ["Pickerel", "Brochet maillé"],
            scientificName: "Esox niger",
            group: .pike,
            summary: "Small, eager member of the pike family. Fun on light tackle, bony on the plate.",
            idTips: [
                "Dark chain-link pattern over a green to brassy body.",
                "Dark vertical bar below each eye, like a teardrop.",
                "Cheek and gill cover both fully scaled."
            ],
            lookalikes: ["northern_pike", "redfin_pickerel", "grass_pickerel"],
            traits: [.torpedoBody, .duckbillSnout, .largeMouth, .darkMottling, .forkedTail],
            sizeCutoffsCm: [30, 40, 50, 60],
            weightA: -5.824,
            weightB: 3.243,
            colorHex: 0x4C7A5E,
            habitat: "Clear, weedy ponds, lakes, and slow streams with lots of cover.",
            range: "Native in Atlantic and Gulf coast drainages from New Brunswick and southern Quebec to Florida and east Texas; introduced in Nova Scotia.",
            regions: [.quebec, .atlanticCanada, .southernPlains, .northeast, .midAtlantic, .southeast, .florida]
        ),

        // MARK: Bass and sunfish

        Species(
            id: "smallmouth_bass",
            commonName: "Smallmouth bass",
            otherNames: ["Smallmouth", "Bronzeback", "Achigan à petite bouche"],
            scientificName: "Micropterus dolomieu",
            group: .blackBass,
            summary: "Hard-fighting bass of rocky, clear water. Jumps often and pulls harder than its size suggests.",
            idTips: [
                "Bronze to brown with dark vertical bars, not a stripe along the side.",
                "Jaw ends below the middle of the eye; a largemouth's reaches past it.",
                "Spiny and soft dorsal fins joined with only a shallow notch."
            ],
            lookalikes: ["largemouth_bass", "spotted_bass", "rock_bass"],
            traits: [.spinyDorsal, .verticalBars, .goldenColor, .forkedTail],
            sizeCutoffsCm: [25, 33, 43, 50],
            weightA: -5.329,
            weightB: 3.200,
            colorHex: 0x8F6430,
            habitat: "Rocky shoals, points, rubble, and current breaks in clear lakes and rivers.",
            range: "Native to the Great Lakes, St. Lawrence, and Ohio and upper Mississippi basins; introduced across most of the US and southern Canada.",
            regions: [.britishColumbia, .prairies, .ontario, .quebec, .atlanticCanada, .pacificNorthwest, .california, .mountainWest, .southwest, .northernPlains, .southernPlains, .upperMidwest, .ohioValley, .northeast, .midAtlantic, .southeast]
        ),
        Species(
            id: "largemouth_bass",
            commonName: "Largemouth bass",
            otherNames: ["Largemouth", "Bucketmouth", "Achigan à grande bouche"],
            scientificName: "Micropterus nigricans",
            group: .blackBass,
            summary: "Bass of warm, weedy water. Ambushes from cover and takes topwater well on summer evenings.",
            idTips: [
                "Jaw reaches past the back of the eye when the mouth is closed.",
                "Dark, blotchy stripe along the side instead of vertical bars.",
                "Deep notch between the spiny and soft dorsal fins, nearly separate."
            ],
            lookalikes: ["smallmouth_bass", "spotted_bass", "florida_bass"],
            traits: [.spinyDorsal, .largeMouth, .darkMottling, .forkedTail],
            sizeCutoffsCm: [25, 33, 45, 53],
            weightA: -5.528,
            weightB: 3.273,
            colorHex: 0x5B7A33,
            habitat: "Shallow, weedy bays, lily pads, docks, and fallen timber in warm lakes and slow rivers.",
            range: "Native from southern Ontario and Quebec south to the Gulf and the Carolinas; stocked in nearly every US state and southern BC.",
            regions: [.britishColumbia, .ontario, .quebec, .pacificNorthwest, .california, .mountainWest, .southwest, .northernPlains, .southernPlains, .upperMidwest, .ohioValley, .northeast, .midAtlantic, .southeast, .florida]
        ),
        Species(
            id: "rock_bass",
            commonName: "Rock bass",
            otherNames: ["Red eye", "Goggle-eye", "Crapet de roche"],
            scientificName: "Ambloplites rupestris",
            group: .sunfish,
            summary: "Common panfish around rocks and docks. Bites readily, good for kids, decent eating.",
            idTips: [
                "Rows of dark spots along brassy sides, like dotted lines.",
                "Six anal fin spines; a warmouth, pumpkinseed, or bluegill has three.",
                "Bright red eye and a bigger mouth than a pumpkinseed."
            ],
            lookalikes: ["pumpkinseed", "warmouth", "smallmouth_bass"],
            traits: [.deepFlatBody, .spinyDorsal, .darkSpotsLightBody, .goldenColor, .forkedTail],
            sizeCutoffsCm: [13, 17, 21, 25],
            weightA: -4.827,
            weightB: 3.074,
            colorHex: 0x8A4E3A,
            habitat: "Rocky shorelines, docks, and boulders in clear lakes and streams.",
            range: "Native from southern Quebec to Saskatchewan and south through the Great Lakes, Ohio, and Tennessee basins; introduced in Atlantic coast rivers.",
            regions: [.prairies, .ontario, .quebec, .northernPlains, .upperMidwest, .ohioValley, .northeast, .midAtlantic, .southeast]
        ),
        Species(
            id: "black_crappie",
            commonName: "Black crappie",
            otherNames: ["Crappie", "Calico bass", "Speck", "Marigane noire"],
            scientificName: "Pomoxis nigromaculatus",
            group: .sunfish,
            summary: "Schooling panfish that suspends near cover. Light bite, soft mouth, very good eating.",
            idTips: [
                "Seven or eight spines in the dorsal fin; white crappie has five or six.",
                "Black speckles and blotches scattered all over, no clear bars.",
                "Dorsal fin base about as long as the eye-to-dorsal distance."
            ],
            lookalikes: ["white_crappie"],
            traits: [.deepFlatBody, .spinyDorsal, .darkMottling, .darkSpotsLightBody, .forkedTail],
            sizeCutoffsCm: [18, 23, 28, 33],
            weightA: -5.618,
            weightB: 3.345,
            colorHex: 0x4C5866,
            habitat: "Clear, weedy lakes and backwaters; schools hold near brush, docks, and weed edges, often off the bottom.",
            range: "Native across the East from Manitoba and Quebec to Florida and Texas; introduced throughout the West, including southern BC.",
            regions: [.britishColumbia, .prairies, .ontario, .quebec, .pacificNorthwest, .california, .mountainWest, .southwest, .northernPlains, .southernPlains, .upperMidwest, .ohioValley, .northeast, .midAtlantic, .southeast, .florida]
        ),
        Species(
            id: "white_crappie",
            commonName: "White crappie",
            otherNames: ["Crappie", "Marigane blanche"],
            scientificName: "Pomoxis annularis",
            group: .sunfish,
            summary: "Close relative of the black crappie that handles murkier water. Uncommon in Canada.",
            idTips: [
                "Five or six dorsal spines; black crappie has seven or eight.",
                "Faint dark vertical bars instead of scattered speckles.",
                "Dorsal fin base shorter than the eye-to-dorsal distance."
            ],
            lookalikes: ["black_crappie"],
            traits: [.deepFlatBody, .spinyDorsal, .verticalBars, .silverColor, .forkedTail],
            sizeCutoffsCm: [18, 23, 28, 33],
            weightA: -5.642,
            weightB: 3.332,
            colorHex: 0x6E7A86,
            habitat: "Turbid lakes, bays, and slow rivers, around brush and drop-offs.",
            range: "Native from the lower Great Lakes south through the Mississippi basin to the Gulf; stocked on the Atlantic slope and in the West.",
            regions: [.ontario, .california, .southwest, .northernPlains, .southernPlains, .upperMidwest, .ohioValley, .northeast, .midAtlantic, .southeast]
        ),
        Species(
            id: "bluegill",
            commonName: "Bluegill",
            otherNames: ["Sunfish", "Bream", "Crapet arlequin"],
            scientificName: "Lepomis macrochirus",
            group: .sunfish,
            summary: "Classic sunfish of warm, weedy water. Easy to catch on small baits and good eating.",
            idTips: [
                "Solid dark ear flap with no red or orange edge.",
                "Dark smudge at the back of the soft dorsal fin.",
                "Tiny mouth and no wavy blue cheek lines, unlike pumpkinseed or green sunfish."
            ],
            lookalikes: ["pumpkinseed", "redear_sunfish", "green_sunfish"],
            traits: [.deepFlatBody, .spinyDorsal, .earFlap, .smallMouth, .verticalBars, .forkedTail],
            sizeCutoffsCm: [12, 16, 20, 24],
            weightA: -5.374,
            weightB: 3.316,
            colorHex: 0x3D6A8A,
            habitat: "Warm, weedy shallows of lakes, ponds, and slow rivers, around docks and lily pads.",
            range: "Native from southern Ontario and the Great Lakes south to Florida and Texas; stocked in ponds and lakes across the US.",
            regions: [.ontario, .pacificNorthwest, .california, .mountainWest, .southwest, .northernPlains, .southernPlains, .upperMidwest, .ohioValley, .northeast, .midAtlantic, .southeast, .florida]
        ),
        Species(
            id: "pumpkinseed",
            commonName: "Pumpkinseed",
            otherNames: ["Sunfish", "Sunny", "Crapet-soleil"],
            scientificName: "Lepomis gibbosus",
            group: .sunfish,
            summary: "The sunfish under almost every northern dock. Small, colourful, and easy to catch.",
            idTips: [
                "Bright orange or red spot on the tip of the black ear flap.",
                "Wavy blue lines across the cheek.",
                "Orange-gold spots on the sides and an orange belly."
            ],
            lookalikes: ["bluegill", "redear_sunfish", "rock_bass"],
            traits: [.deepFlatBody, .spinyDorsal, .earFlap, .smallMouth, .lightSpotsDarkBody, .goldenColor, .forkedTail],
            sizeCutoffsCm: [11, 14, 18, 21],
            weightA: -5.179,
            weightB: 3.237,
            colorHex: 0xAD5E2A,
            habitat: "Shallow, weedy water near shore in lakes, ponds, and slow streams.",
            range: "Native from the Maritimes to Manitoba and south along the Atlantic coast to the Carolinas; introduced in BC and the Pacific Northwest.",
            regions: [.britishColumbia, .prairies, .ontario, .quebec, .atlanticCanada, .pacificNorthwest, .upperMidwest, .ohioValley, .northeast, .midAtlantic, .southeast]
        ),
        Species(
            id: "white_bass",
            commonName: "White bass",
            otherNames: ["Silver bass", "Sand bass", "Bar blanc"],
            scientificName: "Morone chrysops",
            group: .temperateBass,
            summary: "Schooling relative of the striped bass. Runs up rivers in spring and chases baitfish at the surface in summer.",
            idTips: [
                "Silver sides with thin, faint dark stripes running nose to tail.",
                "Deep body with a humped back; a striped bass is much longer and slimmer.",
                "One tooth patch on the back of the tongue; stripers and hybrids have two."
            ],
            lookalikes: ["white_perch", "striped_bass", "hybrid_striped_bass", "yellow_bass"],
            traits: [.deepFlatBody, .spinyDorsal, .twoSeparateDorsals, .silverColor, .forkedTail],
            sizeCutoffsCm: [22, 28, 34, 40],
            weightA: -5.066,
            weightB: 3.081,
            colorHex: 0x5F7690,
            habitat: "Open water of large lakes and big rivers; spawns over gravel in tributaries.",
            range: "Native from Manitoba and the lower Great Lakes south through the Mississippi basin to the Gulf and Texas; stocked in western reservoirs.",
            regions: [.prairies, .ontario, .california, .mountainWest, .southwest, .northernPlains, .southernPlains, .upperMidwest, .ohioValley, .northeast, .midAtlantic, .southeast]
        ),
        Species(
            id: "white_perch",
            commonName: "White perch",
            otherNames: ["Silver perch", "Bar-perche"],
            scientificName: "Morone americana",
            group: .temperateBass,
            summary: "Small schooling cousin of the white bass. Native in the Maritimes and St. Lawrence, invasive in the Great Lakes.",
            idTips: [
                "Plain silver to olive-grey sides with no stripes on adults.",
                "Spiny and soft dorsal fins joined by a low membrane.",
                "Deep body with an arched back, smaller than a white bass."
            ],
            lookalikes: ["white_bass", "yellow_bass", "striped_bass"],
            traits: [.deepFlatBody, .spinyDorsal, .silverColor, .forkedTail],
            sizeCutoffsCm: [15, 20, 25, 30],
            weightA: -5.122,
            weightB: 3.136,
            colorHex: 0x77806E,
            habitat: "Bays, harbours, and river mouths with soft bottoms; schools move around a lot.",
            range: "Native along the Atlantic coast from Nova Scotia and the St. Lawrence to the Carolinas; invasive in the Great Lakes and some Plains reservoirs.",
            regions: [.ontario, .quebec, .atlanticCanada, .northernPlains, .upperMidwest, .ohioValley, .northeast, .midAtlantic, .southeast]
        ),
        Species(
            id: "striped_bass",
            commonName: "Striped bass",
            otherNames: ["Striper", "Rockfish", "Bar rayé"],
            scientificName: "Morone saxatilis",
            group: .temperateBass,
            summary: "Sea-run bass that enters rivers to spawn, also stocked in big inland reservoirs. In Canada mostly a Maritime and lower St. Lawrence fish.",
            idTips: [
                "Seven or eight bold, unbroken stripes; a hybrid's stripes are broken.",
                "Long, fairly slim body; a white bass is deep and humped.",
                "Two tooth patches on the back of the tongue; white bass has one."
            ],
            lookalikes: ["hybrid_striped_bass", "white_bass", "white_perch"],
            traits: [.torpedoBody, .spinyDorsal, .twoSeparateDorsals, .silverColor, .forkedTail],
            sizeCutoffsCm: [45, 60, 75, 95],
            weightA: -4.924,
            weightB: 3.007,
            colorHex: 0x3F566F,
            habitat: "Estuaries and tidal rivers; follows bait into fresh water in spring and early summer.",
            range: "Native to Atlantic and Gulf coast rivers from the Gulf of St. Lawrence to Louisiana; stocked in California and big inland reservoirs.",
            regions: [.quebec, .atlanticCanada, .california, .mountainWest, .southwest, .northernPlains, .southernPlains, .ohioValley, .northeast, .midAtlantic, .southeast, .florida]
        ),

        // MARK: Trout and char

        Species(
            id: "lake_trout",
            commonName: "Lake trout",
            otherNames: ["Laker", "Grey trout", "Mackinaw", "Togue", "Touladi"],
            scientificName: "Salvelinus namaycush",
            group: .troutChar,
            summary: "Cold-water char of deep, clear lakes. Shallow in spring and fall, deep in summer.",
            idTips: [
                "Deeply forked tail; brook trout and splake tails are square or only slightly forked.",
                "Pale cream spots all over a grey to dark green body, tail included.",
                "No red spots and no blue halos."
            ],
            lookalikes: ["splake", "brook_trout", "arctic_char"],
            traits: [.adiposeFin, .torpedoBody, .largeMouth, .lightSpotsDarkBody, .whiteFinEdges, .forkedTail],
            sizeCutoffsCm: [40, 55, 70, 85],
            weightA: -5.681,
            weightB: 3.246,
            colorHex: 0x55675C,
            habitat: "Deep, cold, clear lakes; near the surface after ice-out, then down near the thermocline.",
            range: "Native from Labrador to Alaska and south to the Great Lakes and New England; introduced in deep western lakes.",
            regions: [.britishColumbia, .prairies, .ontario, .quebec, .atlanticCanada, .northernCanada, .alaska, .pacificNorthwest, .california, .mountainWest, .upperMidwest, .ohioValley, .northeast]
        ),
        Species(
            id: "brook_trout",
            commonName: "Brook trout",
            otherNames: ["Speckled trout", "Speckle", "Brookie", "Omble de fontaine", "Truite mouchetée"],
            scientificName: "Salvelinus fontinalis",
            group: .troutChar,
            summary: "Native char of cold streams and lakes, and the classic wild trout of the East. Needs cold, clean water.",
            idTips: [
                "Wavy, worm-like pale marks on the back and dorsal fin.",
                "Red spots with blue halos among the pale spots on the sides.",
                "Lower fins orange-red with a white front edge and a black line behind it."
            ],
            lookalikes: ["splake", "tiger_trout", "lake_trout", "brown_trout"],
            traits: [.adiposeFin, .torpedoBody, .lightSpotsDarkBody, .darkMottling, .whiteFinEdges, .squareTail],
            sizeCutoffsCm: [18, 25, 35, 45],
            weightA: -5.186,
            weightB: 3.103,
            colorHex: 0x5F6A2E,
            habitat: "Cold, clean streams, spring-fed ponds, and lakes, usually under 20 °C.",
            range: "Native from Labrador and Hudson Bay south through the Great Lakes and the Appalachians to Georgia; introduced in cold waters across the West.",
            regions: [.britishColumbia, .prairies, .ontario, .quebec, .atlanticCanada, .pacificNorthwest, .california, .mountainWest, .southwest, .northernPlains, .upperMidwest, .northeast, .midAtlantic, .southeast]
        ),
        Species(
            id: "brown_trout",
            commonName: "Brown trout",
            otherNames: ["Brown", "German brown", "Truite brune"],
            scientificName: "Salmo trutta",
            group: .troutChar,
            summary: "European trout stocked across North America over a century ago. Wary, and most active at night and in low light.",
            idTips: [
                "Black and red spots, often with pale halos, on a golden brown body.",
                "Few or no spots on the tail; a rainbow's tail is heavily spotted.",
                "No bold white front edges on the lower fins, unlike brook trout and splake."
            ],
            lookalikes: ["brook_trout", "atlantic_salmon", "rainbow_trout"],
            traits: [.adiposeFin, .torpedoBody, .darkSpotsLightBody, .goldenColor, .squareTail],
            sizeCutoffsCm: [25, 35, 50, 65],
            weightA: -4.867,
            weightB: 2.960,
            colorHex: 0x8C6A38,
            habitat: "Cool streams and rivers with undercut banks and wood; also Great Lakes shorelines and tributaries.",
            range: "Introduced from Europe and now wild or stocked in cold water across southern Canada and most of the US.",
            regions: [.britishColumbia, .prairies, .ontario, .quebec, .atlanticCanada, .pacificNorthwest, .california, .mountainWest, .southwest, .northernPlains, .southernPlains, .upperMidwest, .ohioValley, .northeast, .midAtlantic, .southeast]
        ),
        Species(
            id: "rainbow_trout",
            commonName: "Rainbow trout",
            otherNames: ["Rainbow", "Kamloops trout", "Truite arc-en-ciel"],
            scientificName: "Oncorhynchus mykiss",
            group: .troutChar,
            summary: "Native to the Pacific slope and stocked across the continent. Lake-run and sea-run fish, called steelhead, run rivers in spring and fall.",
            idTips: [
                "Pink to red band along the side, faded or missing on fresh steelhead.",
                "Small black spots all over the back, dorsal fin, and tail.",
                "No red or orange slash under the jaw; a cutthroat has one."
            ],
            lookalikes: ["steelhead", "cutthroat_trout", "brown_trout", "coho_salmon"],
            traits: [.adiposeFin, .torpedoBody, .darkSpotsLightBody, .pinkOrRedStripe, .silverColor],
            sizeCutoffsCm: [25, 38, 55, 72],
            weightA: -4.898,
            weightB: 2.990,
            colorHex: 0xA35A72,
            habitat: "Cool streams, rivers, and lakes; steelhead spend summers in the Great Lakes or the ocean.",
            range: "Native to Pacific drainages from Alaska to Mexico and to Alberta's Athabasca River; stocked across the continent.",
            regions: [.britishColumbia, .prairies, .ontario, .quebec, .atlanticCanada, .alaska, .pacificNorthwest, .california, .mountainWest, .southwest, .northernPlains, .southernPlains, .upperMidwest, .ohioValley, .northeast, .midAtlantic, .southeast]
        ),
        Species(
            id: "splake",
            commonName: "Splake",
            otherNames: ["Truite moulac"],
            scientificName: "Salvelinus namaycush × S. fontinalis",
            group: .troutChar,
            summary: "Hatchery cross of lake trout and brook trout, stocked across Canada and the northern US. Grows faster than a brook trout and fishes well through the ice.",
            idTips: [
                "Tail moderately forked, between a brook trout's square tail and a laker's deep fork.",
                "Worm-like marks on the back like a brook trout, but few or no red spots.",
                "Lower fins orange with white front edges."
            ],
            lookalikes: ["brook_trout", "lake_trout", "tiger_trout"],
            traits: [.adiposeFin, .torpedoBody, .lightSpotsDarkBody, .darkMottling, .whiteFinEdges, .forkedTail],
            sizeCutoffsCm: [25, 35, 45, 58],
            weightA: nil,
            weightB: nil,
            colorHex: 0x6E6248,
            habitat: "Stocked lakes, often small and cold; cruises shorelines in spring and under the ice.",
            range: "Stocked in lakes in Ontario, Quebec, the Prairies, the Great Lakes states, the Northeast, and the Rockies.",
            regions: [.prairies, .ontario, .quebec, .mountainWest, .upperMidwest, .northeast]
        ),
        Species(
            id: "cutthroat_trout",
            commonName: "Cutthroat trout",
            otherNames: ["Cutthroat", "Cutty", "Westslope cutthroat", "Coastal cutthroat", "Truite fardée"],
            scientificName: "Oncorhynchus clarkii",
            group: .troutChar,
            summary: "Western trout with a red mark under the jaw. Recent name lists split it into coastal, westslope, Lahontan, and Rocky Mountain species.",
            idTips: [
                "Red or orange slash in the skin folds under the lower jaw.",
                "Spots heavier toward the tail, often fewer on the front half.",
                "Tiny teeth behind the tongue; rainbows lack them."
            ],
            lookalikes: ["rainbow_trout"],
            traits: [.adiposeFin, .torpedoBody, .largeMouth, .darkSpotsLightBody, .goldenColor],
            sizeCutoffsCm: [20, 30, 40, 50],
            weightA: -5.189,
            weightB: 3.099,
            colorHex: 0xA8643A,
            habitat: "Cold, clear mountain streams and lakes; coastal fish also use estuaries.",
            range: "Native to the West from southeast Alaska and Alberta south to northern California, Nevada, and New Mexico.",
            regions: [.britishColumbia, .prairies, .alaska, .pacificNorthwest, .california, .mountainWest, .southwest]
        ),
        Species(
            id: "bull_trout",
            commonName: "Bull trout",
            otherNames: ["Bull char", "Omble à tête plate"],
            scientificName: "Salvelinus confluentus",
            group: .troutChar,
            summary: "Big-headed native char of western mountain rivers. Protected in many waters, so check the rules before keeping one.",
            idTips: [
                "Pale yellow to pink spots, no black spots, and a plain dorsal fin.",
                "Big, broad, flat head; a Dolly Varden's is smaller and rounder.",
                "Inland a char is most likely a bull trout, near the coast a Dolly Varden."
            ],
            lookalikes: ["dolly_varden", "brook_trout", "lake_trout"],
            traits: [.adiposeFin, .torpedoBody, .largeMouth, .lightSpotsDarkBody, .whiteFinEdges, .forkedTail],
            sizeCutoffsCm: [30, 45, 60, 75],
            weightA: -5.327,
            weightB: 3.115,
            colorHex: 0x5E7470,
            habitat: "Cold, clean rivers and lakes fed by snowmelt and glaciers; needs very cold water to spawn.",
            range: "Native from the southern Yukon and Northwest Territories through BC and western Alberta to the Northwest and Montana.",
            regions: [.britishColumbia, .prairies, .northernCanada, .pacificNorthwest, .mountainWest]
        ),
        Species(
            id: "dolly_varden",
            commonName: "Dolly Varden",
            otherNames: ["Dolly", "Dolly char"],
            scientificName: "Salvelinus malma",
            group: .troutChar,
            summary: "Coastal and northern char. Sea-run fish enter rivers bright silver and colour up as they spawn.",
            idTips: [
                "Small pink to red spots on olive or silver sides, and no black spots.",
                "Smaller, rounder head than a bull trout, with a shorter snout.",
                "Near the coast a char is most likely a Dolly Varden, inland a bull trout."
            ],
            lookalikes: ["bull_trout", "arctic_char"],
            traits: [.adiposeFin, .torpedoBody, .lightSpotsDarkBody, .whiteFinEdges, .silverColor, .forkedTail],
            sizeCutoffsCm: [25, 35, 48, 60],
            weightA: nil,
            weightB: nil,
            colorHex: 0x75668A,
            habitat: "Coastal streams, rivers, lakes, and estuaries; some northern fish stay in rivers year round.",
            range: "Coastal and Arctic drainages from Washington north through BC and Alaska and east to the Mackenzie River.",
            regions: [.britishColumbia, .northernCanada, .alaska, .pacificNorthwest]
        ),
        Species(
            id: "arctic_char",
            commonName: "Arctic char",
            otherNames: ["Char", "Omble chevalier"],
            scientificName: "Salvelinus alpinus",
            group: .troutChar,
            summary: "The most northern freshwater fish in North America. Sea-run char are a staple food across the Arctic.",
            idTips: [
                "Pale pink, red, or cream spots on the sides, and no black spots.",
                "Tail only slightly forked; a lake trout's is deeply forked.",
                "No worm-like marks on the back or dorsal fin, unlike a brook trout."
            ],
            lookalikes: ["dolly_varden", "lake_trout", "brook_trout"],
            traits: [.adiposeFin, .torpedoBody, .lightSpotsDarkBody, .whiteFinEdges, .silverColor, .forkedTail],
            sizeCutoffsCm: [35, 50, 65, 80],
            weightA: nil,
            weightB: nil,
            colorHex: 0xA8503C,
            habitat: "Cold Arctic lakes, rivers, and coastal waters; landlocked fish live in some deep lakes farther south.",
            range: "Arctic coasts and islands from Alaska to Nunavik and Labrador, with landlocked fish in a few lakes farther south.",
            regions: [.quebec, .atlanticCanada, .northernCanada, .alaska]
        ),

        // MARK: Salmon

        Species(
            id: "chinook_salmon",
            commonName: "Chinook salmon",
            otherNames: ["Chinook", "King salmon", "Spring salmon", "Tyee", "Saumon chinook", "Saumon quinnat"],
            scientificName: "Oncorhynchus tshawytscha",
            group: .salmon,
            summary: "The biggest Pacific salmon. Native to the Pacific and stocked in the Great Lakes, where fall runs fill the rivers.",
            idTips: [
                "Black gums at the base of the teeth on the lower jaw.",
                "Spots on the back and on both lobes of the tail.",
                "Thick tail wrist that does not narrow much."
            ],
            lookalikes: ["coho_salmon", "pink_salmon"],
            traits: [.adiposeFin, .torpedoBody, .darkSpotsLightBody, .silverColor, .forkedTail],
            sizeCutoffsCm: [50, 70, 90, 105],
            weightA: -4.661,
            weightB: 2.901,
            colorHex: 0x55708C,
            habitat: "Open, cold water of big lakes and the ocean; runs up rivers to spawn in late summer and fall.",
            range: "Native to Pacific rivers from central California to Alaska and the Yukon; stocked in the Great Lakes and a few Missouri River reservoirs.",
            regions: [.britishColumbia, .ontario, .alaska, .pacificNorthwest, .california, .mountainWest, .northernPlains, .upperMidwest, .ohioValley, .northeast]
        ),
        Species(
            id: "coho_salmon",
            commonName: "Coho salmon",
            otherNames: ["Coho", "Silver salmon", "Saumon coho"],
            scientificName: "Oncorhynchus kisutch",
            group: .salmon,
            summary: "Mid-sized Pacific salmon known for acrobatic fights. Native on the BC coast and stocked in the Great Lakes.",
            idTips: [
                "White or grey gums at the base of the lower teeth, dark mouth.",
                "Spots on the back and only the upper lobe of the tail.",
                "Narrow tail wrist compared to a chinook."
            ],
            lookalikes: ["chinook_salmon", "rainbow_trout"],
            traits: [.adiposeFin, .torpedoBody, .darkSpotsLightBody, .silverColor, .forkedTail],
            sizeCutoffsCm: [40, 52, 65, 75],
            weightA: nil,
            weightB: nil,
            colorHex: 0x37707F,
            habitat: "Open water of the ocean and big lakes; spawns in small coastal and tributary streams in the fall.",
            range: "Native to Pacific rivers from central California to Alaska; stocked in the Great Lakes.",
            regions: [.britishColumbia, .ontario, .alaska, .pacificNorthwest, .upperMidwest, .ohioValley, .northeast]
        ),
        Species(
            id: "pink_salmon",
            commonName: "Pink salmon",
            otherNames: ["Pink", "Humpy", "Humpback salmon", "Saumon rose"],
            scientificName: "Oncorhynchus gorbuscha",
            group: .salmon,
            summary: "Smallest and most plentiful Pacific salmon, on a two-year cycle. A small population also lives in the upper Great Lakes.",
            idTips: [
                "Large, oval black spots on the back and both lobes of the tail.",
                "Very small scales, much finer than other salmon.",
                "Spawning males grow a big hump behind the head."
            ],
            lookalikes: ["chinook_salmon", "coho_salmon"],
            traits: [.adiposeFin, .torpedoBody, .darkSpotsLightBody, .silverColor, .forkedTail],
            sizeCutoffsCm: [38, 46, 54, 62],
            weightA: nil,
            weightB: nil,
            colorHex: 0x8A5F80,
            habitat: "Coastal waters; runs into rivers close to the sea to spawn in late summer.",
            range: "Native to Pacific rivers from Washington to Alaska, with big odd-year runs in the south; a small population lives in the upper Great Lakes.",
            regions: [.britishColumbia, .ontario, .alaska, .pacificNorthwest, .upperMidwest]
        ),
        Species(
            id: "sockeye_salmon",
            commonName: "Sockeye salmon",
            otherNames: ["Sockeye", "Red salmon", "Saumon rouge"],
            scientificName: "Oncorhynchus nerka",
            group: .salmon,
            summary: "Pacific salmon that feeds on plankton. Its landlocked form, the kokanee, is a popular lake fish in BC.",
            idTips: [
                "Bright silver with fine specks on the back and no large spots.",
                "Plain tail with no spots; coho and chinook tails are spotted.",
                "Spawning fish turn bright red with a green head."
            ],
            lookalikes: ["kokanee", "chum_salmon", "coho_salmon", "rainbow_trout"],
            traits: [.adiposeFin, .torpedoBody, .silverColor, .forkedTail],
            sizeCutoffsCm: [25, 35, 50, 62],
            weightA: nil,
            weightB: nil,
            colorHex: 0x9E3B4B,
            habitat: "Sea-run fish spawn in rivers tied to lakes; kokanee live in cool, deep lakes and school in open water.",
            range: "Pacific coast rivers and lakes from the Columbia River north through BC to Alaska.",
            regions: [.britishColumbia, .northernCanada, .alaska, .pacificNorthwest]
        ),
        Species(
            id: "atlantic_salmon",
            commonName: "Atlantic salmon",
            otherNames: ["Landlocked salmon", "Ouananiche", "Grilse", "Saumon atlantique"],
            scientificName: "Salmo salar",
            group: .salmon,
            summary: "Sea-run salmon of the Atlantic rivers, with landlocked lake forms called ouananiche. Being restored to Lake Ontario streams.",
            idTips: [
                "Black X-shaped spots mostly above the lateral line, few or none on the tail.",
                "Tail slightly forked; a brown trout's is square.",
                "Upper jaw ends near the back of the eye; a big brown's reaches past it."
            ],
            lookalikes: ["brown_trout", "rainbow_trout"],
            traits: [.adiposeFin, .torpedoBody, .darkSpotsLightBody, .silverColor, .forkedTail],
            sizeCutoffsCm: [40, 55, 70, 85],
            weightA: nil,
            weightB: nil,
            colorHex: 0x3E5674,
            habitat: "Cold, clear rivers with gravel riffles; landlocked fish live in large, cold lakes.",
            range: "Native to Atlantic rivers from northern Quebec and Labrador to New England, with landlocked lake forms; stocked in Lakes Ontario and Huron.",
            regions: [.ontario, .quebec, .atlanticCanada, .upperMidwest, .northeast]
        ),

        // MARK: Whitefish and grayling

        Species(
            id: "arctic_grayling",
            commonName: "Arctic grayling",
            otherNames: ["Grayling", "Ombre arctique"],
            scientificName: "Thymallus arcticus",
            group: .whitefish,
            summary: "Northern fish with a tall, colourful sail for a dorsal fin. Rises to small flies in clear, cold rivers.",
            idTips: [
                "Huge, sail-like dorsal fin edged and spotted with colour.",
                "A few dark spots on the front half of the body, behind the gill cover.",
                "Silver-grey to purple sides with large scales and a small mouth."
            ],
            lookalikes: ["mountain_whitefish"],
            traits: [.adiposeFin, .longDorsalFin, .darkSpotsLightBody, .silverColor, .forkedTail],
            sizeCutoffsCm: [20, 28, 36, 44],
            weightA: -5.241,
            weightB: 3.083,
            colorHex: 0x66598A,
            habitat: "Clear, cold rivers and lakes; holds in runs and pool tails, feeding on drifting insects.",
            range: "Native from Hudson Bay west across the North to Alaska and in the upper Missouri of Montana; stocked in high lakes in the Rockies.",
            regions: [.britishColumbia, .prairies, .northernCanada, .alaska, .mountainWest]
        ),
        Species(
            id: "lake_whitefish",
            commonName: "Lake whitefish",
            otherNames: ["Whitefish", "Common whitefish", "Grand corégone"],
            scientificName: "Coregonus clupeaformis",
            group: .whitefish,
            summary: "Bottom-feeding relative of trout. Good eating, and an ice fishing target on many northern lakes.",
            idTips: [
                "Snout overhangs a small lower jaw; a cisco's lower jaw meets or juts past it.",
                "Hump behind the head in larger fish.",
                "Deep, flat-sided body; round and mountain whitefish are slim and tube-shaped."
            ],
            lookalikes: ["cisco", "round_whitefish", "mountain_whitefish"],
            traits: [.adiposeFin, .smallMouth, .silverColor, .forkedTail],
            sizeCutoffsCm: [30, 40, 50, 60],
            weightA: nil,
            weightB: nil,
            colorHex: 0x6F7C88,
            habitat: "Cold, deep lakes; feeds near bottom on insects, snails, and small clams.",
            range: "Native across most of Canada and Alaska and south to the Great Lakes and northern New England; introduced in parts of the Northwest.",
            regions: [.britishColumbia, .prairies, .ontario, .quebec, .atlanticCanada, .northernCanada, .alaska, .pacificNorthwest, .mountainWest, .upperMidwest, .northeast]
        ),
        Species(
            id: "mountain_whitefish",
            commonName: "Mountain whitefish",
            otherNames: ["Rocky Mountain whitefish", "Ménomini des montagnes"],
            scientificName: "Prosopium williamsoni",
            group: .whitefish,
            summary: "Common native fish of western rivers. Often caught while trout fishing and takes nymphs well.",
            idTips: [
                "Round, cylinder-shaped body, slimmer than a lake whitefish.",
                "Small mouth set under a short, pointed snout.",
                "Normal dorsal fin, not the tall sail of a grayling."
            ],
            lookalikes: ["round_whitefish", "arctic_grayling", "lake_whitefish"],
            traits: [.adiposeFin, .torpedoBody, .smallMouth, .silverColor, .forkedTail],
            sizeCutoffsCm: [20, 28, 36, 44],
            weightA: -5.086,
            weightB: 3.036,
            colorHex: 0x7A7562,
            habitat: "Cold, clear rivers and streams with gravel bottoms; also some mountain lakes.",
            range: "Native to western mountain rivers from northern BC and Alberta south to Nevada, Utah, and Colorado.",
            regions: [.britishColumbia, .prairies, .pacificNorthwest, .california, .mountainWest]
        ),
        Species(
            id: "cisco",
            commonName: "Cisco",
            otherNames: ["Lake herring", "Tullibee", "Cisco de lac"],
            scientificName: "Coregonus artedi",
            group: .whitefish,
            summary: "Open-water whitefish that schools in cold lakes. Key food for lake trout and good sport on light gear through the ice.",
            idTips: [
                "Lower jaw meets or sticks out past the tip of the snout.",
                "Slim, herring-like body with a bluish or greenish back.",
                "Plain silver with no spots, and an adipose fin."
            ],
            lookalikes: ["lake_whitefish"],
            traits: [.adiposeFin, .torpedoBody, .silverColor, .forkedTail],
            sizeCutoffsCm: [20, 27, 34, 42],
            weightA: -5.517,
            weightB: 3.224,
            colorHex: 0x4F7590,
            habitat: "Cool open water of lakes, usually suspended at mid-depth in summer.",
            range: "Native from Quebec west to Alberta and the Northwest Territories and south through the Great Lakes and upper Midwest.",
            regions: [.prairies, .ontario, .quebec, .northernCanada, .upperMidwest]
        ),
        Species(
            id: "inconnu",
            commonName: "Inconnu",
            otherNames: ["Sheefish", "Coney", "Connie"],
            scientificName: "Stenodus nelma",
            group: .whitefish,
            summary: "Big, predatory whitefish of the far northwest. Strong fighter and good eating.",
            idTips: [
                "Large mouth with a jutting lower jaw, reaching back to below the eye.",
                "Much bigger than a cisco, often over 60 cm.",
                "Long, silver body with a pointed head and no spots."
            ],
            lookalikes: ["lake_whitefish", "cisco"],
            traits: [.adiposeFin, .torpedoBody, .largeMouth, .silverColor, .forkedTail],
            sizeCutoffsCm: [45, 60, 75, 90],
            weightA: nil,
            weightB: nil,
            colorHex: 0x5E7A7A,
            habitat: "Large northern rivers and lakes; moves between feeding lakes and spawning rivers.",
            range: "Arctic and Bering Sea rivers of Alaska, the Yukon, and the Northwest Territories, including the Mackenzie River and Great Slave Lake.",
            regions: [.northernCanada, .alaska]
        ),

        // MARK: Catfish and bullheads

        Species(
            id: "channel_catfish",
            commonName: "Channel catfish",
            otherNames: ["Channel cat", "Catfish", "Barbue de rivière"],
            scientificName: "Ictalurus punctatus",
            group: .catfish,
            summary: "Big, hard-pulling catfish of warm rivers. Bites best at night on cut bait and worms.",
            idTips: [
                "Deeply forked tail; bullheads and flatheads have square tails.",
                "Scattered dark spots on grey sides, mostly on younger fish.",
                "Rounded anal fin with 24 to 29 rays; a blue cat's is straight-edged."
            ],
            lookalikes: ["blue_catfish", "white_catfish", "brown_bullhead"],
            traits: [.adiposeFin, .barbels, .smoothSkin, .darkSpotsLightBody, .forkedTail],
            sizeCutoffsCm: [40, 55, 70, 85],
            weightA: -5.800,
            weightB: 3.294,
            colorHex: 0x4E5C6A,
            habitat: "Warm rivers and large lakes over sand, gravel, or rock, holding near logjams and deep holes.",
            range: "Native from southern Manitoba, Ontario, and Quebec south through the central US to the Gulf; stocked across the rest of the US.",
            regions: [.prairies, .ontario, .quebec, .pacificNorthwest, .california, .mountainWest, .southwest, .northernPlains, .southernPlains, .upperMidwest, .ohioValley, .northeast, .midAtlantic, .southeast, .florida]
        ),
        Species(
            id: "brown_bullhead",
            commonName: "Brown bullhead",
            otherNames: ["Bullhead", "Mudcat", "Horned pout", "Barbotte brune"],
            scientificName: "Ameiurus nebulosus",
            group: .catfish,
            summary: "Small catfish of weedy, soft-bottomed water. Bites at night and handles warm, low-oxygen water.",
            idTips: [
                "Mottled brown sides; a black bullhead is plain with a pale bar near the tail.",
                "Dark chin barbels; a yellow bullhead's are white.",
                "Square or slightly notched tail; a channel cat's is deeply forked."
            ],
            lookalikes: ["yellow_bullhead", "black_bullhead", "channel_catfish"],
            traits: [.adiposeFin, .barbels, .smoothSkin, .darkMottling, .squareTail],
            sizeCutoffsCm: [18, 24, 30, 36],
            weightA: -5.076,
            weightB: 3.105,
            colorHex: 0x5E5240,
            habitat: "Warm, weedy ponds, bays, and slow rivers with mud bottoms.",
            range: "Native from Nova Scotia and southern Manitoba south through the Great Lakes and the East to Florida; introduced in BC and the western US.",
            regions: [.britishColumbia, .prairies, .ontario, .quebec, .atlanticCanada, .pacificNorthwest, .california, .upperMidwest, .ohioValley, .northeast, .midAtlantic, .southeast, .florida]
        ),

        // MARK: Everything else

        Species(
            id: "burbot",
            commonName: "Burbot",
            otherNames: ["Ling", "Eelpout", "Lawyer", "Lotte"],
            scientificName: "Lota lota",
            group: .other,
            summary: "Freshwater cod that spawns under the ice in midwinter. Odd looking and very good to eat.",
            idTips: [
                "Single barbel on the chin.",
                "Two dorsal fins, a short first and a long second; a bowfin has one.",
                "Smooth, slimy skin with a brown, marbled pattern."
            ],
            lookalikes: ["bowfin"],
            traits: [.twoSeparateDorsals, .longDorsalFin, .barbels, .smoothSkin, .darkMottling, .roundedTail],
            sizeCutoffsCm: [35, 45, 60, 75],
            weightA: -4.868,
            weightB: 2.898,
            colorHex: 0x6A5E3A,
            habitat: "Cold, deep lakes and large rivers; moves shallow at night and in winter.",
            range: "Native across Canada and Alaska and south into the northern US, from New England to the Great Lakes, the Dakotas, and the Rockies.",
            regions: [.britishColumbia, .prairies, .ontario, .quebec, .atlanticCanada, .northernCanada, .alaska, .pacificNorthwest, .mountainWest, .northernPlains, .upperMidwest, .northeast]
        ),
        Species(
            id: "common_carp",
            commonName: "Common carp",
            otherNames: ["Carp", "Carpe commune"],
            scientificName: "Cyprinus carpio",
            group: .carpSuckers,
            summary: "Large, strong, wary bottom feeder from Europe and Asia. Now common in warm water across southern Canada and the US.",
            idTips: [
                "Two pairs of barbels on the upper jaw; buffalo, suckers, and grass carp have none.",
                "Long dorsal fin with a stout, saw-toothed front spine.",
                "Large bronze to golden scales outlined in dark."
            ],
            lookalikes: ["bigmouth_buffalo", "smallmouth_buffalo", "grass_carp", "white_sucker"],
            traits: [.longDorsalFin, .barbels, .smallMouth, .goldenColor, .forkedTail],
            sizeCutoffsCm: [40, 55, 70, 85],
            weightA: -4.639,
            weightB: 2.920,
            colorHex: 0x9C7A34,
            habitat: "Warm, shallow lakes, bays, marshes, and slow rivers with soft bottoms.",
            range: "Introduced from Europe and Asia and now in warm water across southern Canada and nearly every US state.",
            regions: [.britishColumbia, .prairies, .ontario, .quebec, .pacificNorthwest, .california, .mountainWest, .southwest, .northernPlains, .southernPlains, .upperMidwest, .ohioValley, .northeast, .midAtlantic, .southeast]
        ),
        Species(
            id: "freshwater_drum",
            commonName: "Freshwater drum",
            otherNames: ["Sheepshead", "Drum", "Gaspergou", "Malachigan"],
            scientificName: "Aplodinotus grunniens",
            group: .other,
            summary: "Hard-fighting bottom feeder that crushes snails and mussels. Grunts when you land it.",
            idTips: [
                "Lateral line runs all the way to the end of the rounded tail.",
                "Long dorsal fin, the spiny front part joined to a soft rear part.",
                "High, humped back and a blunt, down-turned snout."
            ],
            lookalikes: ["white_bass", "common_carp"],
            traits: [.deepFlatBody, .spinyDorsal, .longDorsalFin, .silverColor, .roundedTail],
            sizeCutoffsCm: [30, 40, 50, 62],
            weightA: -5.419,
            weightB: 3.204,
            colorHex: 0x7A8088,
            habitat: "Large lakes and rivers with soft bottoms, often in murky water.",
            range: "Native from Manitoba and the St. Lawrence south through the Great Lakes and Mississippi basin to the Gulf and Texas.",
            regions: [.prairies, .ontario, .quebec, .northernPlains, .southernPlains, .upperMidwest, .ohioValley, .northeast, .midAtlantic, .southeast]
        ),
        Species(
            id: "bowfin",
            commonName: "Bowfin",
            otherNames: ["Eyetail bowfin", "Dogfish", "Mudfish", "Poisson-castor"],
            scientificName: "Amia ocellicauda",
            group: .ancient,
            summary: "Ancient, air-breathing fish of warm, weedy water. Fights hard and is tough to unhook.",
            idTips: [
                "One long, soft dorsal fin running over half the back.",
                "Short anal fin; a snakehead's is long, nearly matching its dorsal.",
                "Black eyespot at the base of the tail, ringed in orange on males."
            ],
            lookalikes: ["ruddy_bowfin", "northern_snakehead", "burbot"],
            traits: [.torpedoBody, .largeMouth, .longDorsalFin, .darkMottling, .roundedTail],
            sizeCutoffsCm: [40, 50, 60, 70],
            weightA: nil,
            weightB: nil,
            colorHex: 0x4E5A36,
            habitat: "Warm, heavily weeded bays, marshes, and backwaters, often low in oxygen.",
            range: "Native to the St. Lawrence, Great Lakes, and Mississippi basin south to the Gulf; southeastern coastal fish are the separate ruddy bowfin.",
            regions: [.ontario, .quebec, .southernPlains, .upperMidwest, .ohioValley, .northeast, .southeast]
        ),
        Species(
            id: "longnose_gar",
            commonName: "Longnose gar",
            otherNames: ["Gar", "Garpike", "Lépisosté osseux"],
            scientificName: "Lepisosteus osseus",
            group: .ancient,
            summary: "Long, armoured fish that basks near the surface in summer. Hard to hook in its bony beak.",
            idTips: [
                "Long, narrow beak more than twice the length of the rest of the head.",
                "Hard, diamond-shaped scales like armour.",
                "Dark spots on the rear fins and tail."
            ],
            lookalikes: ["spotted_gar", "shortnose_gar", "alligator_gar"],
            traits: [.torpedoBody, .longToothySnout, .bonyPlates, .darkSpotsLightBody, .roundedTail],
            sizeCutoffsCm: [50, 70, 90, 110],
            weightA: -6.811,
            weightB: 3.449,
            colorHex: 0x6F7448,
            habitat: "Warm, weedy shallows of lakes and slow rivers; often lies just under the surface.",
            range: "Native from southern Quebec and the Great Lakes south through the Mississippi basin and Atlantic and Gulf coasts to Florida and Texas.",
            regions: [.ontario, .quebec, .northernPlains, .southernPlains, .upperMidwest, .ohioValley, .northeast, .midAtlantic, .southeast, .florida]
        ),
        Species(
            id: "lake_sturgeon",
            commonName: "Lake sturgeon",
            otherNames: ["Rock sturgeon", "Sturgeon", "Esturgeon jaune"],
            scientificName: "Acipenser fulvescens",
            group: .ancient,
            summary: "Long-lived bottom feeder that can pass 100 years and 2 m. Protected in much of its range, so check the rules and handle it gently.",
            idTips: [
                "Rounded, cone-shaped snout with four smooth barbels; a shovelnose's is flat.",
                "Rows of bony plates along the back and sides, smoothing with age.",
                "Toothless mouth under the head that pushes out to suck up food."
            ],
            lookalikes: ["shovelnose_sturgeon", "white_sturgeon"],
            traits: [.torpedoBody, .barbels, .bonyPlates, .forkedTail],
            sizeCutoffsCm: [80, 110, 140, 165],
            weightA: nil,
            weightB: nil,
            colorHex: 0x6E6250,
            habitat: "Large lakes and rivers, over sand, gravel, and mud in deep runs and holes.",
            range: "Native to the St. Lawrence, Great Lakes, Hudson Bay, and upper Mississippi drainages from Quebec to Alberta; rare and protected in most of the US.",
            regions: [.prairies, .ontario, .quebec, .upperMidwest]
        ),
        Species(
            id: "white_sturgeon",
            commonName: "White sturgeon",
            otherNames: ["Pacific sturgeon", "Sturgeon", "Esturgeon blanc"],
            scientificName: "Acipenser transmontanus",
            group: .ancient,
            summary: "The largest freshwater fish in North America; fish over 3 m still turn up in the Fraser River. Catch and release only in BC.",
            idTips: [
                "Barbels nearer the snout tip than the mouth; a green sturgeon's are the reverse.",
                "Plain grey to brown with a pale belly, no olive tint or side stripe.",
                "38 or more plates along each side; a green sturgeon has about 30 or fewer."
            ],
            lookalikes: ["green_sturgeon", "lake_sturgeon"],
            traits: [.torpedoBody, .barbels, .bonyPlates, .forkedTail],
            sizeCutoffsCm: [100, 140, 180, 220],
            weightA: nil,
            weightB: nil,
            colorHex: 0x5E6670,
            habitat: "Large rivers and their estuaries, holding in deep holes and back eddies.",
            range: "Pacific coast rivers and estuaries from BC to California, mainly the Fraser, Columbia, Snake, and Sacramento systems.",
            regions: [.britishColumbia, .pacificNorthwest, .california]
        ),
        Species(
            id: "goldeye",
            commonName: "Goldeye",
            otherNames: ["Winnipeg goldeye", "Laquaiche aux yeux d'or"],
            scientificName: "Hiodon alosoides",
            group: .other,
            summary: "Thin, silver, insect-eating fish that rises readily to flies. Smoked, it is the well-known Winnipeg goldeye.",
            idTips: [
                "Gold iris in a large eye.",
                "Dorsal fin starts behind the front of the anal fin; a mooneye's starts ahead.",
                "Fleshy belly keel runs from the pectoral fins to the anal fin."
            ],
            lookalikes: ["mooneye"],
            traits: [.deepFlatBody, .glassyEye, .silverColor, .forkedTail],
            sizeCutoffsCm: [25, 32, 38, 44],
            weightA: nil,
            weightB: nil,
            colorHex: 0x8F7F3E,
            habitat: "Turbid rivers and shallow, muddy lakes; feeds at the surface at dusk.",
            range: "Native from the Mackenzie River south through the Prairies and northwestern Ontario to the Missouri and Mississippi rivers.",
            regions: [.prairies, .ontario, .northernCanada, .mountainWest, .northernPlains, .upperMidwest, .ohioValley]
        ),
        Species(
            id: "mooneye",
            commonName: "Mooneye",
            otherNames: ["Laquaiche argentée"],
            scientificName: "Hiodon tergisus",
            group: .other,
            summary: "Silver cousin of the goldeye that prefers clearer water. Takes small flies and spinners.",
            idTips: [
                "Silver or white iris, not gold.",
                "Dorsal fin starts ahead of the front of the anal fin.",
                "Belly keel runs only from the pelvic fins to the anal fin."
            ],
            lookalikes: ["goldeye"],
            traits: [.deepFlatBody, .glassyEye, .silverColor, .forkedTail],
            sizeCutoffsCm: [22, 28, 34, 40],
            weightA: nil,
            weightB: nil,
            colorHex: 0x6F7F8E,
            habitat: "Clear, large rivers and lakes, often in current.",
            range: "Native from the St. Lawrence west through the Great Lakes to the Prairies and south through the Ohio and Mississippi basins.",
            regions: [.prairies, .ontario, .quebec, .upperMidwest, .ohioValley]
        ),
        Species(
            id: "white_sucker",
            commonName: "White sucker",
            otherNames: ["Sucker", "Mullet", "Meunier noir"],
            scientificName: "Catostomus commersonii",
            group: .carpSuckers,
            summary: "Bottom feeder caught on worms in lakes and rivers across Canada and the northern US. Runs up streams in large numbers in spring.",
            idTips: [
                "Thick, fleshy lips on a mouth set under the head.",
                "No barbels and a short dorsal fin; a carp has barbels and a long one.",
                "Round body with small scales, dull grey to olive."
            ],
            lookalikes: ["common_carp"],
            traits: [.torpedoBody, .smallMouth, .forkedTail],
            sizeCutoffsCm: [25, 35, 45, 55],
            weightA: -4.755,
            weightB: 2.940,
            colorHex: 0x76705A,
            habitat: "Lakes and streams of every size, feeding on the bottom.",
            range: "Native across most of Canada and the northern and eastern US, south to Georgia and west to the Rockies.",
            regions: [.britishColumbia, .prairies, .ontario, .quebec, .atlanticCanada, .northernCanada, .mountainWest, .northernPlains, .upperMidwest, .ohioValley, .northeast, .midAtlantic, .southeast]
        ),
        Species(
            id: "round_goby",
            commonName: "Round goby",
            otherNames: ["Goby", "Gobie à taches noires"],
            scientificName: "Neogobius melanostomus",
            group: .other,
            summary: "Invasive bottom fish now common in the Great Lakes and spreading inland. Do not use or move them alive.",
            idTips: [
                "Pelvic fins joined into a single suction disc under the belly.",
                "Black spot at the back of the front dorsal fin.",
                "Frog-like head with raised eyes near the top."
            ],
            lookalikes: [],
            traits: [.twoSeparateDorsals, .darkMottling, .roundedTail],
            sizeCutoffsCm: [7, 10, 13, 16],
            weightA: nil,
            weightB: nil,
            colorHex: 0x5A5244,
            habitat: "Rocky and rubble bottoms in lakes and rivers, from shore out to deep water.",
            range: "Invasive in all five Great Lakes, the St. Lawrence, and connected rivers and canals; native to the Black and Caspian seas.",
            regions: [.ontario, .quebec, .upperMidwest, .ohioValley, .northeast]
        ),
    ]
}
