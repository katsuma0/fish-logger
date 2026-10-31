import Foundation

// Canadian freshwater sport fish, plus a few common catches an Ontario angler will meet anyway.
// Weight coefficients are published standard weight (Ws) equations. Species without one we trust are
// nil, so the app shows no weight estimate rather than a guessed one.
extension SpeciesCatalog {
    static let all: [Species] = [

        // MARK: Walleye and perch

        Species(
            id: "walleye",
            commonName: "Walleye",
            otherNames: ["Pickerel", "Yellow pickerel", "Walleyed pike", "Doré jaune"],
            scientificName: "Sander vitreus",
            group: .perch,
            summary: "Ontario's most sought-after table fish. Feeds most at dawn, dusk, and under cloud or chop.",
            idTips: [
                "White patch on the lower tip of the tail; sauger has none.",
                "Spiny dorsal fin has a dark blotch at the back and no rows of spots.",
                "Big glassy eyes that shine in low light.",
                "Gold to olive sides with faint saddles, not sharp dark blotches."
            ],
            lookalikes: ["sauger", "yellow_perch"],
            traits: [.torpedoBody, .spinyDorsal, .twoSeparateDorsals, .glassyEye, .whiteTailTip, .goldenColor, .forkedTail],
            sizeCutoffsCm: [30, 40, 55, 70],
            weightA: -5.453,
            weightB: 3.180,
            colorHex: 0x9A7F2E,
            habitat: "Large lakes and rivers, around rocky points, reefs, weed edges, and drop-offs.",
            range: "From Quebec west to northeastern BC and north into the Northwest Territories; rare or absent in the Maritimes."
        ),
        Species(
            id: "sauger",
            commonName: "Sauger",
            otherNames: ["Sand pike", "Doré noir"],
            scientificName: "Sander canadensis",
            group: .perch,
            summary: "Smaller cousin of the walleye that favours murky, flowing water. Eats just as well.",
            idTips: [
                "No white patch on the lower tail tip, or only a thin pale edge.",
                "Rows of distinct black spots on the spiny dorsal fin.",
                "Dark, blotchy saddles along the back and sides.",
                "Rough, scaly cheeks; a walleye's cheeks are smoother."
            ],
            lookalikes: ["walleye"],
            traits: [.torpedoBody, .spinyDorsal, .twoSeparateDorsals, .glassyEye, .darkMottling, .darkSpotsLightBody, .forkedTail],
            sizeCutoffsCm: [25, 33, 40, 48],
            weightA: -5.492,
            weightB: 3.187,
            colorHex: 0x7A6644,
            habitat: "Turbid rivers and large shallow lakes, over sand and gravel, often in current.",
            range: "The St. Lawrence and Ottawa rivers, northwestern Ontario, and big Prairie rivers and lakes such as Lake Winnipeg."
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
                "Two separate back fins, the front one spiny.",
                "Lower fins often orange, brightest in spring.",
                "No big canine teeth and no glassy eye, unlike a young walleye."
            ],
            lookalikes: ["walleye", "white_perch"],
            traits: [.spinyDorsal, .twoSeparateDorsals, .verticalBars, .goldenColor, .forkedTail],
            sizeCutoffsCm: [15, 20, 25, 32],
            weightA: -5.386,
            weightB: 3.230,
            colorHex: 0x7D8B2B,
            habitat: "Weedy bays, flats, and open basins of lakes and slow rivers; schools roam over sand and mud.",
            range: "From the Maritimes west to northeastern BC and north into the Northwest Territories; introduced in southern BC."
        ),

        // MARK: Pike and muskie

        Species(
            id: "northern_pike",
            commonName: "Northern pike",
            otherNames: ["Pike", "Jackfish", "Jack", "Grand brochet"],
            scientificName: "Esox lucius",
            group: .pike,
            summary: "Common, aggressive predator in almost every weedy lake in Canada. The teeth cut, so use long pliers or a jaw spreader.",
            idTips: [
                "Rows of pale, bean-shaped spots on a dark green body.",
                "Cheek fully scaled, lower half of the gill cover bare.",
                "Five or fewer pores under each side of the lower jaw; muskie has six or more.",
                "Tail lobes rounded at the tips; a muskie's are more pointed."
            ],
            lookalikes: ["muskellunge", "tiger_muskie", "chain_pickerel"],
            traits: [.torpedoBody, .duckbillSnout, .largeMouth, .lightSpotsDarkBody, .forkedTail],
            sizeCutoffsCm: [45, 60, 80, 100],
            weightA: -5.437,
            weightB: 3.096,
            colorHex: 0x3E6E3F,
            habitat: "Weedy bays, shallow flats, and river backwaters; big fish move to cooler, deeper water in summer.",
            range: "From Labrador and Quebec west to the Yukon and north to the Arctic; absent from most of the Maritimes and southern BC."
        ),
        Species(
            id: "muskellunge",
            commonName: "Muskellunge",
            otherNames: ["Muskie", "Musky", "Lunge", "Maskinongé"],
            scientificName: "Esox masquinongy",
            group: .pike,
            summary: "The biggest predator in the Ontario lakes it lives in, slow to catch and nearly always released. Heavy gear and a big net keep fish in good shape.",
            idTips: [
                "Dark bars or spots on a light olive to tan body; a pike is the reverse.",
                "Six or more pores under each side of the lower jaw.",
                "Lower half of both the cheek and the gill cover bare.",
                "Tail lobes come to sharper points than a pike's."
            ],
            lookalikes: ["northern_pike", "tiger_muskie", "chain_pickerel"],
            traits: [.torpedoBody, .duckbillSnout, .largeMouth, .darkSpotsLightBody, .verticalBars, .forkedTail],
            sizeCutoffsCm: [70, 90, 110, 125],
            weightA: -5.920,
            weightB: 3.271,
            colorHex: 0x8A7550,
            habitat: "Large, clear lakes and rivers with weed beds, rocky shoals, and deep edges close by.",
            range: "Southern Ontario and southwestern Quebec, Georgian Bay, the Ottawa and St. Lawrence rivers, and the Lake of the Woods area; spreading in New Brunswick's Saint John River."
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
                "Tail lobes rounded at the tips.",
                "Cheek and gill cover partly scaled, in between pike and muskie.",
                "Jaw pore count in between, often five to eight per side and uneven."
            ],
            lookalikes: ["muskellunge", "northern_pike"],
            traits: [.torpedoBody, .duckbillSnout, .largeMouth, .verticalBars, .darkMottling, .forkedTail],
            sizeCutoffsCm: [65, 80, 95, 110],
            weightA: nil,
            weightB: nil,
            colorHex: 0x6A6B35,
            habitat: "Same water as muskie and pike: weedy bays, points, and river edges.",
            range: "Turns up wherever pike and muskie share water in Ontario and Quebec; rare in most lakes."
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
                "Dark vertical bar below each eye, like a tear drop.",
                "Cheek and gill cover both fully scaled.",
                "Rarely over 60 cm; small pike have pale spots, not chains."
            ],
            lookalikes: ["northern_pike", "muskellunge"],
            traits: [.torpedoBody, .duckbillSnout, .largeMouth, .darkMottling, .forkedTail],
            sizeCutoffsCm: [30, 40, 50, 60],
            weightA: nil,
            weightB: nil,
            colorHex: 0x4C7A5E,
            habitat: "Clear, weedy ponds, lakes, and slow streams with lots of cover.",
            range: "Southern New Brunswick and southern Quebec, and introduced in Nova Scotia, where it is still spreading. Rare or absent in Ontario."
        ),

        // MARK: Bass and sunfish

        Species(
            id: "smallmouth_bass",
            commonName: "Smallmouth bass",
            otherNames: ["Smallmouth", "Bronzeback", "Achigan à petite bouche"],
            scientificName: "Micropterus dolomieu",
            group: .bassSunfish,
            summary: "Hard-fighting bass of rocky, clear water. Jumps often and pulls harder than its size suggests.",
            idTips: [
                "Bronze to brown with dark vertical bars, not a stripe along the side.",
                "Jaw ends below the middle of the eye; a largemouth's reaches past it.",
                "Spiny and soft dorsal fins joined with only a shallow notch.",
                "Red or orange eye, often with dark bars running back from it."
            ],
            lookalikes: ["largemouth_bass", "rock_bass"],
            traits: [.spinyDorsal, .verticalBars, .goldenColor, .forkedTail],
            sizeCutoffsCm: [25, 33, 43, 50],
            weightA: -5.329,
            weightB: 3.200,
            colorHex: 0x8F6430,
            habitat: "Rocky shoals, points, rubble, and current breaks in clear lakes and rivers.",
            range: "Native to the Great Lakes and St. Lawrence in Ontario and Quebec and now well north of there; introduced in the Maritimes, Manitoba, and BC."
        ),
        Species(
            id: "largemouth_bass",
            commonName: "Largemouth bass",
            otherNames: ["Largemouth", "Bucketmouth", "Achigan à grande bouche"],
            scientificName: "Micropterus salmoides",
            group: .bassSunfish,
            summary: "Bass of warm, weedy water. Ambushes from cover and takes topwater well on summer evenings.",
            idTips: [
                "Jaw reaches past the back of the eye when the mouth is closed.",
                "Dark, blotchy stripe along the side instead of vertical bars.",
                "Deep notch between the spiny and soft dorsal fins, nearly separate.",
                "Green to olive, not bronze."
            ],
            lookalikes: ["smallmouth_bass"],
            traits: [.spinyDorsal, .largeMouth, .darkMottling, .forkedTail],
            sizeCutoffsCm: [25, 33, 45, 53],
            weightA: -5.528,
            weightB: 3.273,
            colorHex: 0x5B7A33,
            habitat: "Shallow, weedy bays, lily pads, docks, and fallen timber in warm lakes and slow rivers.",
            range: "Southern Ontario and southwestern Quebec, north to about Georgian Bay and the Ottawa Valley; introduced in southern BC."
        ),
        Species(
            id: "rock_bass",
            commonName: "Rock bass",
            otherNames: ["Red eye", "Goggle-eye", "Crapet de roche"],
            scientificName: "Ambloplites rupestris",
            group: .bassSunfish,
            summary: "Common panfish around rocks and docks. Bites readily, good for kids, decent eating.",
            idTips: [
                "Bright red eye.",
                "Rows of dark spots on brassy sides, like dotted lines.",
                "Thicker body and bigger mouth than a bluegill or pumpkinseed.",
                "Six spines on the anal fin; bluegill and pumpkinseed have three."
            ],
            lookalikes: ["pumpkinseed", "smallmouth_bass"],
            traits: [.deepFlatBody, .spinyDorsal, .darkSpotsLightBody, .goldenColor, .forkedTail],
            sizeCutoffsCm: [13, 17, 21, 25],
            weightA: -4.827,
            weightB: 3.021,
            colorHex: 0x8A4E3A,
            habitat: "Rocky shorelines, docks, and boulders in clear lakes and streams.",
            range: "Southern and central Ontario and southwestern Quebec, west to Manitoba and eastern Saskatchewan."
        ),
        Species(
            id: "black_crappie",
            commonName: "Black crappie",
            otherNames: ["Crappie", "Calico bass", "Speck", "Marigane noire"],
            scientificName: "Pomoxis nigromaculatus",
            group: .bassSunfish,
            summary: "Schooling panfish that suspends near cover. Light bite, soft mouth, very good eating.",
            idTips: [
                "Seven or eight spines in the dorsal fin; white crappie has five or six.",
                "Black speckles and blotches scattered all over, no clear bars.",
                "Dorsal fin base about as long as the distance from the eye to the dorsal fin.",
                "Deeper, rounder body than a white crappie."
            ],
            lookalikes: ["white_crappie"],
            traits: [.deepFlatBody, .spinyDorsal, .darkMottling, .darkSpotsLightBody, .forkedTail],
            sizeCutoffsCm: [18, 23, 28, 33],
            weightA: -5.618,
            weightB: 3.345,
            colorHex: 0x4C5866,
            habitat: "Clear, weedy lakes and backwaters; schools hold near brush, docks, and weed edges, often off the bottom.",
            range: "Southern Ontario and southwestern Quebec, plus parts of Manitoba; spreading north in Ontario and introduced in southern BC."
        ),
        Species(
            id: "white_crappie",
            commonName: "White crappie",
            otherNames: ["Crappie", "Marigane blanche"],
            scientificName: "Pomoxis annularis",
            group: .bassSunfish,
            summary: "Close relative of the black crappie that handles murkier water. Uncommon in Canada.",
            idTips: [
                "Five or six dorsal spines; black crappie has seven or eight.",
                "Faint dark vertical bars instead of scattered speckles.",
                "Longer, slimmer body with a humped back ahead of the dorsal fin.",
                "Dorsal fin base shorter than the distance from the eye to the dorsal fin."
            ],
            lookalikes: ["black_crappie"],
            traits: [.deepFlatBody, .spinyDorsal, .verticalBars, .silverColor, .forkedTail],
            sizeCutoffsCm: [18, 23, 28, 33],
            weightA: -5.642,
            weightB: 3.332,
            colorHex: 0x6E7A86,
            habitat: "Turbid lakes, bays, and slow rivers, around brush and drop-offs.",
            range: "Only a few waters in southwestern Ontario, mostly bays and rivers around Lake Erie and Lake St. Clair."
        ),
        Species(
            id: "bluegill",
            commonName: "Bluegill",
            otherNames: ["Sunfish", "Bream", "Crapet arlequin"],
            scientificName: "Lepomis macrochirus",
            group: .bassSunfish,
            summary: "Classic sunfish of warm, weedy water. Easy to catch on small baits and good eating.",
            idTips: [
                "Solid dark ear flap with no red or orange edge.",
                "Dark smudge at the back of the soft dorsal fin.",
                "Faint vertical bars on blue-green to olive sides, no wavy blue lines on the cheek.",
                "Very small mouth that ends well ahead of the eye."
            ],
            lookalikes: ["pumpkinseed"],
            traits: [.deepFlatBody, .spinyDorsal, .earFlap, .smallMouth, .verticalBars, .forkedTail],
            sizeCutoffsCm: [12, 16, 20, 24],
            weightA: -5.374,
            weightB: 3.316,
            colorHex: 0x3D6A8A,
            habitat: "Warm, weedy shallows of lakes, ponds, and slow rivers, around docks and lily pads.",
            range: "Southern Ontario, mostly south of the Canadian Shield, and a few waters in southwestern Quebec."
        ),
        Species(
            id: "pumpkinseed",
            commonName: "Pumpkinseed",
            otherNames: ["Sunfish", "Sunny", "Crapet-soleil"],
            scientificName: "Lepomis gibbosus",
            group: .bassSunfish,
            summary: "The sunfish under almost every Ontario dock. Small, colourful, and easy to catch.",
            idTips: [
                "Bright orange or red spot on the tip of the black ear flap.",
                "Wavy blue lines across the cheek.",
                "Orange-gold spots on the sides and an orange belly.",
                "Small mouth that ends ahead of the eye."
            ],
            lookalikes: ["bluegill", "rock_bass"],
            traits: [.deepFlatBody, .spinyDorsal, .earFlap, .smallMouth, .lightSpotsDarkBody, .goldenColor, .forkedTail],
            sizeCutoffsCm: [11, 14, 18, 21],
            weightA: -5.179,
            weightB: 3.237,
            colorHex: 0xAD5E2A,
            habitat: "Shallow, weedy water near shore in lakes, ponds, and slow streams.",
            range: "Southern Ontario and Quebec, the Maritimes, and southeastern Manitoba; introduced in southern BC."
        ),
        Species(
            id: "white_bass",
            commonName: "White bass",
            otherNames: ["Silver bass", "Bar blanc"],
            scientificName: "Morone chrysops",
            group: .bassSunfish,
            summary: "Schooling relative of the striped bass. Runs up rivers in spring and chases baitfish at the surface in summer.",
            idTips: [
                "Silver sides with thin, faint dark stripes running nose to tail.",
                "Deep body with a humped back; a striped bass is much longer and slimmer.",
                "Spiny and soft dorsal fins fully separate; a white perch's are joined by a low membrane.",
                "Lower jaw sticks out past the upper."
            ],
            lookalikes: ["white_perch", "striped_bass"],
            traits: [.deepFlatBody, .spinyDorsal, .twoSeparateDorsals, .silverColor, .forkedTail],
            sizeCutoffsCm: [22, 28, 34, 40],
            weightA: -5.066,
            weightB: 3.081,
            colorHex: 0x5F7690,
            habitat: "Open water of large lakes and big rivers; spawns over gravel in tributaries.",
            range: "Lake Erie and Lake St. Clair, parts of Lake Ontario and southern Lake Huron, plus the Red River and Lake Winnipeg in Manitoba."
        ),
        Species(
            id: "white_perch",
            commonName: "White perch",
            otherNames: ["Silver perch", "Bar-perche"],
            scientificName: "Morone americana",
            group: .bassSunfish,
            summary: "Small schooling cousin of the white bass. Native in the Maritimes and St. Lawrence, invasive in the lower Great Lakes.",
            idTips: [
                "Plain silver to olive-grey sides with no stripes on adults.",
                "Spiny and soft dorsal fins joined by a low membrane.",
                "Deep body with an arched back, smaller than a white bass.",
                "Rarely over 30 cm."
            ],
            lookalikes: ["white_bass", "striped_bass"],
            traits: [.deepFlatBody, .spinyDorsal, .silverColor, .forkedTail],
            sizeCutoffsCm: [15, 20, 25, 30],
            weightA: nil,
            weightB: nil,
            colorHex: 0x77806E,
            habitat: "Bays, harbours, and river mouths with soft bottoms; schools move around a lot.",
            range: "Native to the St. Lawrence and coastal Maritimes; invasive in Lakes Ontario and Erie."
        ),
        Species(
            id: "striped_bass",
            commonName: "Striped bass",
            otherNames: ["Striper", "Bar rayé"],
            scientificName: "Morone saxatilis",
            group: .bassSunfish,
            summary: "Sea-run bass that enters rivers to spawn. In Canada mostly a Maritime and lower St. Lawrence fish.",
            idTips: [
                "Seven or eight bold, unbroken dark stripes along silver sides.",
                "Long, fairly slim body; a white bass is deep and humped.",
                "Two dorsal fins fully separate.",
                "Two tooth patches on the back of the tongue; white bass has one."
            ],
            lookalikes: ["white_bass", "white_perch"],
            traits: [.torpedoBody, .spinyDorsal, .twoSeparateDorsals, .silverColor, .forkedTail],
            sizeCutoffsCm: [45, 60, 75, 95],
            weightA: -4.924,
            weightB: 3.007,
            colorHex: 0x3F566F,
            habitat: "Estuaries and tidal rivers; follows bait into fresh water in spring and early summer.",
            range: "The Miramichi and other Gulf of St. Lawrence rivers, the Bay of Fundy, and the St. Lawrence estuary in Quebec."
        ),

        // MARK: Trout and char

        Species(
            id: "lake_trout",
            commonName: "Lake trout",
            otherNames: ["Laker", "Grey trout", "Togue", "Touladi"],
            scientificName: "Salvelinus namaycush",
            group: .troutChar,
            summary: "Cold-water char of deep, clear lakes. Shallow in spring and fall, deep in summer.",
            idTips: [
                "Deeply forked tail; brook trout and splake tails are square or only slightly forked.",
                "Pale cream spots all over a grey to dark green body, tail included.",
                "No red spots and no blue halos.",
                "Thin white edges on the lower fins, less bold than a brook trout's."
            ],
            lookalikes: ["splake", "brook_trout", "arctic_char"],
            traits: [.adiposeFin, .torpedoBody, .largeMouth, .lightSpotsDarkBody, .whiteFinEdges, .forkedTail],
            sizeCutoffsCm: [40, 55, 70, 85],
            weightA: -5.681,
            weightB: 3.246,
            colorHex: 0x55675C,
            habitat: "Deep, cold, clear lakes; near the surface after ice-out, then down near the thermocline.",
            range: "Shield and northern lakes from Labrador to the Yukon and northern BC, plus the Great Lakes and Arctic islands."
        ),
        Species(
            id: "brook_trout",
            commonName: "Brook trout",
            otherNames: ["Speckled trout", "Speckle", "Brookie", "Omble de fontaine", "Truite mouchetée"],
            scientificName: "Salvelinus fontinalis",
            group: .troutChar,
            summary: "Native char of cold streams and lakes, and Ontario's classic wild trout. Needs cold, clean water.",
            idTips: [
                "Wavy, worm-like pale marks on the back and dorsal fin.",
                "Red spots with blue halos among the pale spots on the sides.",
                "Lower fins orange-red with a white front edge and a black line behind it.",
                "Tail square or barely forked."
            ],
            lookalikes: ["splake", "lake_trout", "brown_trout"],
            traits: [.adiposeFin, .torpedoBody, .lightSpotsDarkBody, .darkMottling, .whiteFinEdges, .squareTail],
            sizeCutoffsCm: [18, 25, 35, 45],
            weightA: -5.186,
            weightB: 3.103,
            colorHex: 0x5F6A2E,
            habitat: "Cold, clean streams, spring-fed ponds, and lakes, usually under 20 °C.",
            range: "Eastern Canada from Labrador and Newfoundland west to Manitoba and north to Hudson Bay; stocked in the West."
        ),
        Species(
            id: "brown_trout",
            commonName: "Brown trout",
            otherNames: ["Brown", "German brown", "Truite brune"],
            scientificName: "Salmo trutta",
            group: .troutChar,
            summary: "European trout stocked across Canada over a century ago. Wary, and most active at night and in low light.",
            idTips: [
                "Black and red spots, often with pale halos, on a golden brown body.",
                "Few or no spots on the tail; a rainbow's tail is heavily spotted.",
                "No bold white front edges on the lower fins, unlike brook trout and splake.",
                "Square tail and a jaw that reaches past the eye in big fish."
            ],
            lookalikes: ["brook_trout", "atlantic_salmon", "rainbow_trout"],
            traits: [.adiposeFin, .torpedoBody, .darkSpotsLightBody, .goldenColor, .squareTail],
            sizeCutoffsCm: [25, 35, 50, 65],
            weightA: -4.867,
            weightB: 2.960,
            colorHex: 0x8C6A38,
            habitat: "Cool streams and rivers with undercut banks and wood; also Great Lakes shorelines and tributaries.",
            range: "Introduced in every province; well established in southern Ontario streams, the Great Lakes, Newfoundland, and Alberta's Bow River."
        ),
        Species(
            id: "rainbow_trout",
            commonName: "Rainbow trout",
            otherNames: ["Steelhead", "Rainbow", "Kamloops trout", "Truite arc-en-ciel"],
            scientificName: "Oncorhynchus mykiss",
            group: .troutChar,
            summary: "Native to BC and stocked across Canada. Lake-run and sea-run fish, called steelhead, run rivers in spring and fall.",
            idTips: [
                "Pink to red band along the side, faded or missing on fresh steelhead.",
                "Small black spots all over the back, dorsal fin, and tail.",
                "No red or orange slash under the jaw; a cutthroat has one.",
                "White tips on the dorsal, anal, and pelvic fins in many fish."
            ],
            lookalikes: ["cutthroat_trout", "brown_trout", "coho_salmon"],
            traits: [.adiposeFin, .torpedoBody, .darkSpotsLightBody, .pinkOrRedStripe, .silverColor],
            sizeCutoffsCm: [25, 38, 55, 72],
            weightA: -4.898,
            weightB: 2.990,
            colorHex: 0xA35A72,
            habitat: "Cool streams, rivers, and lakes; steelhead spend summers in the Great Lakes or the ocean.",
            range: "Native to BC and Alberta's Athabasca River; stocked across Canada and wild-spawning in Great Lakes tributaries."
        ),
        Species(
            id: "splake",
            commonName: "Splake",
            otherNames: ["Truite moulac"],
            scientificName: "Salvelinus namaycush × S. fontinalis",
            group: .troutChar,
            summary: "Hatchery cross of lake trout and brook trout, stocked widely in Ontario. Grows faster than a brook trout and fishes well through the ice.",
            idTips: [
                "Tail moderately forked, between a brook trout's square tail and a laker's deep fork.",
                "Worm-like marks on the back like a brook trout, but few or no red spots.",
                "Pale spots on a dark grey-green body.",
                "Lower fins orange with white front edges."
            ],
            lookalikes: ["brook_trout", "lake_trout"],
            traits: [.adiposeFin, .torpedoBody, .lightSpotsDarkBody, .darkMottling, .whiteFinEdges, .forkedTail],
            sizeCutoffsCm: [25, 35, 45, 58],
            weightA: nil,
            weightB: nil,
            colorHex: 0x6E6248,
            habitat: "Stocked lakes, often small and cold; cruises shorelines in spring and under the ice.",
            range: "Stocked lakes, mostly in Ontario, Quebec, and the Prairie provinces; rarely reproduces in the wild."
        ),
        Species(
            id: "cutthroat_trout",
            commonName: "Cutthroat trout",
            otherNames: ["Cutthroat", "Cutty", "Westslope cutthroat", "Coastal cutthroat", "Truite fardée"],
            scientificName: "Oncorhynchus clarkii",
            group: .troutChar,
            summary: "Western trout with a red mark under the jaw. Takes dry flies readily in clear mountain streams.",
            idTips: [
                "Red or orange slash in the skin folds under the lower jaw.",
                "Spots heavier toward the tail, often fewer on the front half.",
                "Jaw usually reaches past the back of the eye.",
                "Tiny teeth at the base of the tongue; rainbows lack them."
            ],
            lookalikes: ["rainbow_trout"],
            traits: [.adiposeFin, .torpedoBody, .largeMouth, .darkSpotsLightBody, .goldenColor],
            sizeCutoffsCm: [20, 30, 40, 50],
            weightA: -5.189,
            weightB: 3.099,
            colorHex: 0xA8643A,
            habitat: "Cold, clear mountain streams and lakes; coastal fish also use estuaries.",
            range: "BC and southwestern Alberta, from the coast to the Rockies."
        ),
        Species(
            id: "bull_trout",
            commonName: "Bull trout",
            otherNames: ["Bull char", "Omble à tête plate"],
            scientificName: "Salvelinus confluentus",
            group: .troutChar,
            summary: "Big-headed native char of western mountain rivers. Protected in many waters, so check the rules before keeping one.",
            idTips: [
                "Pale yellow, orange, or pink spots on an olive to grey back, and no black spots.",
                "Large, broad, flat head with the jaw reaching past the eye; a Dolly Varden's head is smaller and rounder.",
                "Where you are helps: a char from an interior BC or Alberta river is most likely a bull trout, one near the coast a Dolly Varden.",
                "Lower fins with white front edges, and no worm-like marks on the back like a brook trout."
            ],
            lookalikes: ["dolly_varden", "brook_trout", "lake_trout"],
            traits: [.adiposeFin, .torpedoBody, .largeMouth, .lightSpotsDarkBody, .whiteFinEdges, .forkedTail],
            sizeCutoffsCm: [30, 45, 60, 75],
            weightA: nil,
            weightB: nil,
            colorHex: 0x5E7470,
            habitat: "Cold, clean rivers and lakes fed by snowmelt and glaciers; needs very cold water to spawn.",
            range: "BC, western Alberta, and the southern Yukon and Northwest Territories."
        ),
        Species(
            id: "dolly_varden",
            commonName: "Dolly Varden",
            otherNames: ["Dolly", "Dolly char"],
            scientificName: "Salvelinus malma",
            group: .troutChar,
            summary: "Coastal and northern char. Sea-run fish enter rivers bright silver and colour up as they spawn.",
            idTips: [
                "Smaller, rounder head than a bull trout, with a shorter snout.",
                "Small pink to red spots on olive or silver sides, and no black spots.",
                "Where you are helps: on the coast and in the far north a char is most likely a Dolly Varden, inland a bull trout.",
                "Lower fins with white front edges; sea-run fish are bright silver with faint spots."
            ],
            lookalikes: ["bull_trout", "arctic_char"],
            traits: [.adiposeFin, .torpedoBody, .lightSpotsDarkBody, .whiteFinEdges, .silverColor, .forkedTail],
            sizeCutoffsCm: [25, 35, 48, 60],
            weightA: nil,
            weightB: nil,
            colorHex: 0x75668A,
            habitat: "Coastal streams, rivers, lakes, and estuaries; some northern fish stay in rivers year round.",
            range: "Coastal BC, the Yukon, and the Northwest Territories, including rivers that drain to the Arctic coast."
        ),
        Species(
            id: "arctic_char",
            commonName: "Arctic char",
            otherNames: ["Char", "Omble chevalier"],
            scientificName: "Salvelinus alpinus",
            group: .troutChar,
            summary: "The most northern freshwater fish in Canada. Sea-run char are a staple food across the Arctic.",
            idTips: [
                "Pale pink, red, or cream spots on the sides, and no black spots.",
                "Bright red-orange belly and lower fins on spawning fish.",
                "Lower fins with clear white front edges.",
                "Tail only slightly forked; a lake trout's is deeply forked."
            ],
            lookalikes: ["dolly_varden", "lake_trout", "brook_trout"],
            traits: [.adiposeFin, .torpedoBody, .lightSpotsDarkBody, .whiteFinEdges, .silverColor, .forkedTail],
            sizeCutoffsCm: [35, 50, 65, 80],
            weightA: nil,
            weightB: nil,
            colorHex: 0xA8503C,
            habitat: "Cold Arctic lakes, rivers, and coastal waters; landlocked fish live in some deep lakes farther south.",
            range: "Nunavut and the Arctic islands, the Arctic coast of the Northwest Territories, the Hudson Bay coast, northern Quebec, Labrador, and Newfoundland, with landlocked fish in a few southern Quebec lakes."
        ),

        // MARK: Salmon

        Species(
            id: "chinook_salmon",
            commonName: "Chinook salmon",
            otherNames: ["Chinook", "King salmon", "Spring salmon", "Tyee", "Saumon chinook", "Saumon quinnat"],
            scientificName: "Oncorhynchus tshawytscha",
            group: .salmon,
            summary: "The biggest Pacific salmon. Stocked in the Great Lakes, where fall runs fill Ontario rivers.",
            idTips: [
                "Black gums at the base of the teeth on the lower jaw.",
                "Spots on the back and on both lobes of the tail.",
                "Mouth dark inside, black or dark grey.",
                "Thick tail wrist that does not narrow much."
            ],
            lookalikes: ["coho_salmon", "pink_salmon"],
            traits: [.adiposeFin, .torpedoBody, .darkSpotsLightBody, .silverColor, .forkedTail],
            sizeCutoffsCm: [50, 70, 90, 105],
            weightA: nil,
            weightB: nil,
            colorHex: 0x55708C,
            habitat: "Open, cold water of big lakes and the ocean; runs up rivers to spawn in late summer and fall.",
            range: "Native to BC and the Yukon River; stocked and wild-spawning in the Great Lakes, mostly Lake Ontario and Lake Huron."
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
                "Narrow tail wrist compared to a chinook.",
                "Spawning males turn red on the sides and grow a hooked jaw."
            ],
            lookalikes: ["chinook_salmon", "rainbow_trout"],
            traits: [.adiposeFin, .torpedoBody, .darkSpotsLightBody, .silverColor, .forkedTail],
            sizeCutoffsCm: [40, 52, 65, 75],
            weightA: nil,
            weightB: nil,
            colorHex: 0x37707F,
            habitat: "Open water of the ocean and big lakes; spawns in small coastal and tributary streams in the fall.",
            range: "Native to coastal BC and the Yukon River; stocked in the Great Lakes, with the most in Lake Ontario."
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
                "Spawning males grow a big hump behind the head.",
                "Rarely over 60 cm."
            ],
            lookalikes: ["chinook_salmon", "coho_salmon"],
            traits: [.adiposeFin, .torpedoBody, .darkSpotsLightBody, .silverColor, .forkedTail],
            sizeCutoffsCm: [38, 46, 54, 62],
            weightA: nil,
            weightB: nil,
            colorHex: 0x8A5F80,
            habitat: "Coastal waters; runs into rivers close to the sea to spawn in late summer.",
            range: "Coastal BC, with big runs in odd-numbered years; also established in Lakes Superior and Huron."
        ),
        Species(
            id: "sockeye_salmon",
            commonName: "Sockeye salmon",
            otherNames: ["Sockeye", "Kokanee", "Red salmon", "Saumon rouge"],
            scientificName: "Oncorhynchus nerka",
            group: .salmon,
            summary: "Pacific salmon that feeds on plankton. Its landlocked form, the kokanee, is a popular lake fish in BC.",
            idTips: [
                "Bright silver with tiny specks on the back and no large spots.",
                "No spots on the tail.",
                "Spawning fish turn bright red with a green head.",
                "Kokanee are the lake form, usually under 35 cm."
            ],
            lookalikes: ["coho_salmon", "rainbow_trout"],
            traits: [.adiposeFin, .torpedoBody, .silverColor, .forkedTail],
            sizeCutoffsCm: [25, 35, 50, 62],
            weightA: nil,
            weightB: nil,
            colorHex: 0x9E3B4B,
            habitat: "Sea-run fish spawn in rivers tied to lakes; kokanee live in cool, deep lakes and school in open water.",
            range: "Coastal and interior BC and the Yukon; kokanee are also stocked in some Alberta lakes."
        ),
        Species(
            id: "atlantic_salmon",
            commonName: "Atlantic salmon",
            otherNames: ["Landlocked salmon", "Ouananiche", "Grilse", "Saumon atlantique"],
            scientificName: "Salmo salar",
            group: .salmon,
            summary: "Sea-run salmon of the Atlantic rivers, with landlocked lake forms called ouananiche. Being restored to Lake Ontario streams.",
            idTips: [
                "Black X-shaped or round spots, mostly above the lateral line, few or none on the tail.",
                "Slim tail wrist that you can grip; a trout's slips through your hand.",
                "Upper jaw ends at about the back of the eye; a big brown trout's reaches past it.",
                "Tail slightly forked; a brown trout's is square."
            ],
            lookalikes: ["brown_trout", "rainbow_trout"],
            traits: [.adiposeFin, .torpedoBody, .darkSpotsLightBody, .silverColor, .forkedTail],
            sizeCutoffsCm: [40, 55, 70, 85],
            weightA: nil,
            weightB: nil,
            colorHex: 0x3E5674,
            habitat: "Cold, clear rivers with gravel riffles; landlocked fish live in large, cold lakes.",
            range: "Rivers of Quebec, Labrador, Newfoundland, and the Maritimes; landlocked in many Quebec and Labrador lakes and being restocked in Lake Ontario."
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
                "Silver-grey to purple sides and a small adipose fin.",
                "Small mouth and large scales."
            ],
            lookalikes: ["mountain_whitefish"],
            traits: [.adiposeFin, .longDorsalFin, .darkSpotsLightBody, .silverColor, .forkedTail],
            sizeCutoffsCm: [20, 28, 36, 44],
            weightA: nil,
            weightB: nil,
            colorHex: 0x66598A,
            habitat: "Clear, cold rivers and lakes; holds in runs and pool tails, feeding on drifting insects.",
            range: "The Yukon, Northwest Territories, and Nunavut, plus northern BC, Alberta, Saskatchewan, and Manitoba."
        ),
        Species(
            id: "lake_whitefish",
            commonName: "Lake whitefish",
            otherNames: ["Whitefish", "Common whitefish", "Grand corégone"],
            scientificName: "Coregonus clupeaformis",
            group: .whitefish,
            summary: "Bottom-feeding relative of trout. Good eating, and an ice fishing target on many Ontario and Prairie lakes.",
            idTips: [
                "Small mouth with the snout overhanging the lower jaw.",
                "Hump behind the head in larger fish.",
                "Plain silver with no spots, and an adipose fin.",
                "A cisco's lower jaw meets or juts past the snout instead."
            ],
            lookalikes: ["cisco", "mountain_whitefish"],
            traits: [.adiposeFin, .smallMouth, .silverColor, .forkedTail],
            sizeCutoffsCm: [30, 40, 50, 60],
            weightA: nil,
            weightB: nil,
            colorHex: 0x6F7C88,
            habitat: "Cold, deep lakes; feeds near bottom on insects, snails, and small clams.",
            range: "Most of Canada, from Labrador and New Brunswick west to BC and the Yukon, including the Great Lakes."
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
                "Plain silver-brown with no spots.",
                "Normal dorsal fin, not the tall sail of a grayling."
            ],
            lookalikes: ["arctic_grayling", "lake_whitefish"],
            traits: [.adiposeFin, .torpedoBody, .smallMouth, .silverColor, .forkedTail],
            sizeCutoffsCm: [20, 28, 36, 44],
            weightA: nil,
            weightB: nil,
            colorHex: 0x7A7562,
            habitat: "Cold, clear rivers and streams with gravel bottoms; also some mountain lakes.",
            range: "BC, western Alberta, and the southern Yukon."
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
                "Plain silver with no spots, and an adipose fin.",
                "No hump and no overhanging snout, unlike a lake whitefish."
            ],
            lookalikes: ["lake_whitefish"],
            traits: [.adiposeFin, .torpedoBody, .silverColor, .forkedTail],
            sizeCutoffsCm: [20, 27, 34, 42],
            weightA: nil,
            weightB: nil,
            colorHex: 0x4F7590,
            habitat: "Cool open water of lakes, usually suspended at mid-depth in summer.",
            range: "From Quebec west to Alberta and north into the Northwest Territories, including the Great Lakes."
        ),
        Species(
            id: "inconnu",
            commonName: "Inconnu",
            otherNames: ["Sheefish", "Coney", "Connie"],
            scientificName: "Stenodus nelma",
            group: .whitefish,
            summary: "Big, predatory whitefish of the far northwest. Strong fighter and good eating.",
            idTips: [
                "Large mouth with the lower jaw jutting past the upper, unlike other whitefish.",
                "Long, silver body with a pointed head.",
                "Adipose fin present and no spots.",
                "Much bigger than other whitefish, often over 60 cm."
            ],
            lookalikes: ["lake_whitefish", "cisco"],
            traits: [.adiposeFin, .torpedoBody, .largeMouth, .silverColor, .forkedTail],
            sizeCutoffsCm: [45, 60, 75, 90],
            weightA: nil,
            weightB: nil,
            colorHex: 0x5E7A7A,
            habitat: "Large northern rivers and lakes; moves between feeding lakes and spawning rivers.",
            range: "The Mackenzie River system and Great Slave Lake in the Northwest Territories, plus the Yukon River."
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
                "Deeply forked tail; bullheads have square tails.",
                "Scattered dark spots on grey sides, mostly on younger fish.",
                "Eight barbels around the mouth.",
                "Curved, long anal fin with 24 to 29 rays."
            ],
            lookalikes: ["brown_bullhead"],
            traits: [.adiposeFin, .barbels, .smoothSkin, .darkSpotsLightBody, .forkedTail],
            sizeCutoffsCm: [40, 55, 70, 85],
            weightA: -5.800,
            weightB: 3.294,
            colorHex: 0x4E5C6A,
            habitat: "Warm rivers and large lakes over sand, gravel, or rock, holding near logjams and deep holes.",
            range: "Southern Ontario and southwestern Quebec, plus the Red River and Lake Winnipeg area of Manitoba."
        ),
        Species(
            id: "brown_bullhead",
            commonName: "Brown bullhead",
            otherNames: ["Bullhead", "Mudcat", "Horned pout", "Barbotte brune"],
            scientificName: "Ameiurus nebulosus",
            group: .catfish,
            summary: "Small catfish of weedy, soft-bottomed water. Bites at night and handles warm, low-oxygen water.",
            idTips: [
                "Square or slightly notched tail, not forked.",
                "Dark brown or olive with darker mottling.",
                "Dark chin barbels; a yellow bullhead's are white.",
                "Sharp spines in the dorsal and pectoral fins, so handle with care."
            ],
            lookalikes: ["channel_catfish"],
            traits: [.adiposeFin, .barbels, .smoothSkin, .darkMottling, .squareTail],
            sizeCutoffsCm: [18, 24, 30, 36],
            weightA: nil,
            weightB: nil,
            colorHex: 0x5E5240,
            habitat: "Warm, weedy ponds, bays, and slow rivers with mud bottoms.",
            range: "From Nova Scotia west to southern Manitoba; introduced in southern BC."
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
                "Long second dorsal and anal fins running back to a rounded tail.",
                "Smooth, slimy skin with a brown, marbled pattern.",
                "Short first dorsal fin, separate from the long second one; a bowfin has just one."
            ],
            lookalikes: ["bowfin"],
            traits: [.twoSeparateDorsals, .longDorsalFin, .barbels, .smoothSkin, .darkMottling, .roundedTail],
            sizeCutoffsCm: [35, 45, 60, 75],
            weightA: nil,
            weightB: nil,
            colorHex: 0x6A5E3A,
            habitat: "Cold, deep lakes and large rivers; moves shallow at night and in winter.",
            range: "Almost all of Canada, from New Brunswick to BC and north to the Arctic coast."
        ),
        Species(
            id: "common_carp",
            commonName: "Common carp",
            otherNames: ["Carp", "Carpe commune"],
            scientificName: "Cyprinus carpio",
            group: .other,
            summary: "Large, strong, wary bottom feeder from Europe and Asia. Now common in warm water across southern Canada.",
            idTips: [
                "Two pairs of barbels on the upper jaw, the longer pair at the corners of the mouth.",
                "Large bronze to golden scales outlined in dark.",
                "Long dorsal fin with a stout, saw-toothed front spine.",
                "Small, rubbery mouth that points down when feeding."
            ],
            lookalikes: ["white_sucker", "freshwater_drum"],
            traits: [.longDorsalFin, .barbels, .smallMouth, .goldenColor, .forkedTail],
            sizeCutoffsCm: [40, 55, 70, 85],
            weightA: -4.639,
            weightB: 2.920,
            colorHex: 0x9C7A34,
            habitat: "Warm, shallow lakes, bays, marshes, and slow rivers with soft bottoms.",
            range: "Southern Ontario and Quebec, the southern Prairies, and southern BC."
        ),
        Species(
            id: "freshwater_drum",
            commonName: "Freshwater drum",
            otherNames: ["Sheepshead", "Drum", "Malachigan"],
            scientificName: "Aplodinotus grunniens",
            group: .other,
            summary: "Hard-fighting bottom feeder that crushes snails and mussels. Grunts when you land it.",
            idTips: [
                "Lateral line runs all the way to the end of the rounded tail.",
                "Long dorsal fin, the spiny front part joined to a soft rear part.",
                "High, humped back and a blunt, down-turned snout.",
                "Silver to grey with no stripes."
            ],
            lookalikes: ["white_bass", "common_carp"],
            traits: [.deepFlatBody, .spinyDorsal, .longDorsalFin, .silverColor, .roundedTail],
            sizeCutoffsCm: [30, 40, 50, 62],
            weightA: nil,
            weightB: nil,
            colorHex: 0x7A8088,
            habitat: "Large lakes and rivers with soft bottoms, often in murky water.",
            range: "Lake Erie and the rest of the lower Great Lakes, the St. Lawrence, and southern Manitoba."
        ),
        Species(
            id: "bowfin",
            commonName: "Bowfin",
            otherNames: ["Eyetail bowfin", "Dogfish", "Mudfish", "Poisson-castor"],
            scientificName: "Amia ocellicauda",
            group: .other,
            summary: "Ancient, air-breathing fish of warm, weedy water. Fights hard and is tough to unhook.",
            idTips: [
                "One long, soft dorsal fin running over half the back.",
                "Black eyespot at the base of the tail, ringed in orange on males.",
                "No chin barbel; a burbot has one.",
                "Big mouth full of teeth and a bony plate under the chin."
            ],
            lookalikes: ["burbot"],
            traits: [.torpedoBody, .largeMouth, .longDorsalFin, .darkMottling, .roundedTail],
            sizeCutoffsCm: [40, 50, 60, 70],
            weightA: nil,
            weightB: nil,
            colorHex: 0x4E5A36,
            habitat: "Warm, heavily weeded bays, marshes, and backwaters, often low in oxygen.",
            range: "Southern Ontario and southwestern Quebec, including Lake Erie, Lake St. Clair, the Ottawa River, and the St. Lawrence."
        ),
        Species(
            id: "longnose_gar",
            commonName: "Longnose gar",
            otherNames: ["Gar", "Garpike", "Lépisosté osseux"],
            scientificName: "Lepisosteus osseus",
            group: .other,
            summary: "Long, armoured fish that basks near the surface in summer. Hard to hook in its bony beak.",
            idTips: [
                "Long, narrow beak more than twice the length of the rest of the head.",
                "Hard, diamond-shaped scales like armour.",
                "Dorsal fin set far back, right above the anal fin.",
                "Dark spots on the rear fins and tail."
            ],
            lookalikes: ["northern_pike"],
            traits: [.torpedoBody, .longToothySnout, .bonyPlates, .darkSpotsLightBody, .roundedTail],
            sizeCutoffsCm: [50, 70, 90, 110],
            weightA: nil,
            weightB: nil,
            colorHex: 0x6F7448,
            habitat: "Warm, weedy shallows of lakes and slow rivers; often lies just under the surface.",
            range: "Southern Ontario and southwestern Quebec: the lower Great Lakes, the Ottawa River, and the St. Lawrence."
        ),
        Species(
            id: "lake_sturgeon",
            commonName: "Lake sturgeon",
            otherNames: ["Rock sturgeon", "Sturgeon", "Esturgeon jaune"],
            scientificName: "Acipenser fulvescens",
            group: .other,
            summary: "Long-lived bottom feeder that can pass 100 years and 2 m. Protected in much of its range, so check the rules and handle it gently.",
            idTips: [
                "Rows of bony plates along the back and sides.",
                "Four smooth barbels under a rounded, cone-shaped snout.",
                "Toothless mouth under the head that pushes out to suck up food.",
                "Shark-like tail with a longer upper lobe."
            ],
            lookalikes: ["white_sturgeon"],
            traits: [.torpedoBody, .barbels, .bonyPlates, .forkedTail],
            sizeCutoffsCm: [80, 110, 140, 165],
            weightA: nil,
            weightB: nil,
            colorHex: 0x6E6250,
            habitat: "Large lakes and rivers, over sand, gravel, and mud in deep runs and holes.",
            range: "From the St. Lawrence and the Great Lakes west through the Hudson Bay drainage to Alberta."
        ),
        Species(
            id: "white_sturgeon",
            commonName: "White sturgeon",
            otherNames: ["Pacific sturgeon", "Sturgeon", "Esturgeon blanc"],
            scientificName: "Acipenser transmontanus",
            group: .other,
            summary: "The largest freshwater fish in North America; fish over 3 m still turn up in the Fraser River. Catch and release only in BC.",
            idTips: [
                "In BC rivers, a sturgeon you catch is almost always a white sturgeon.",
                "Grey to brown back and pale belly, with no yellow tint.",
                "Rows of bony plates along the back and sides, smoothing with age.",
                "Four barbels under a broad, rounded snout."
            ],
            lookalikes: ["lake_sturgeon"],
            traits: [.torpedoBody, .barbels, .bonyPlates, .forkedTail],
            sizeCutoffsCm: [100, 140, 180, 220],
            weightA: nil,
            weightB: nil,
            colorHex: 0x5E6670,
            habitat: "Large rivers and their estuaries, holding in deep holes and back eddies.",
            range: "BC's Fraser, Columbia, Kootenay, and Nechako rivers."
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
                "Dorsal fin starts behind the front of the anal fin; a mooneye's starts ahead of it.",
                "Fleshy keel along the belly from the pectoral fins to the anal fin.",
                "Thin, flat, silver body with large scales."
            ],
            lookalikes: ["mooneye"],
            traits: [.deepFlatBody, .glassyEye, .silverColor, .forkedTail],
            sizeCutoffsCm: [25, 32, 38, 44],
            weightA: nil,
            weightB: nil,
            colorHex: 0x8F7F3E,
            habitat: "Turbid rivers and shallow, muddy lakes; feeds at the surface at dusk.",
            range: "Mainly the Prairie provinces and northwestern Ontario, north down the Mackenzie River into the Northwest Territories."
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
                "Belly keel runs only from the pelvic fins to the anal fin.",
                "Found in clearer water and smaller on average than a goldeye."
            ],
            lookalikes: ["goldeye"],
            traits: [.deepFlatBody, .glassyEye, .silverColor, .forkedTail],
            sizeCutoffsCm: [22, 28, 34, 40],
            weightA: nil,
            weightB: nil,
            colorHex: 0x6F7F8E,
            habitat: "Clear, large rivers and lakes, often in current.",
            range: "The St. Lawrence and Ottawa rivers and the lower Great Lakes, west through northwestern Ontario into Manitoba and Saskatchewan."
        ),
        Species(
            id: "white_sucker",
            commonName: "White sucker",
            otherNames: ["Sucker", "Mullet", "Meunier noir"],
            scientificName: "Catostomus commersonii",
            group: .other,
            summary: "Bottom feeder caught on worms in nearly every lake and river in Canada. Runs up streams in large numbers in spring.",
            idTips: [
                "Thick-lipped mouth on the underside of the head.",
                "No barbels, unlike a carp.",
                "Round body with fine scales, dull grey to olive.",
                "Single short dorsal fin with no spines."
            ],
            lookalikes: ["common_carp"],
            traits: [.torpedoBody, .smallMouth, .forkedTail],
            sizeCutoffsCm: [25, 35, 45, 55],
            weightA: nil,
            weightB: nil,
            colorHex: 0x76705A,
            habitat: "Lakes and streams of every size, feeding on the bottom.",
            range: "Almost all of Canada, north to the Mackenzie Delta; absent from the island of Newfoundland and most of coastal BC."
        ),
        Species(
            id: "round_goby",
            commonName: "Round goby",
            otherNames: ["Goby", "Gobie à taches noires"],
            scientificName: "Neogobius melanostomus",
            group: .other,
            summary: "Invasive bottom fish now common in the lower Great Lakes and spreading inland. Do not use or move them alive.",
            idTips: [
                "Pelvic fins joined into a single suction disc under the belly.",
                "Black spot at the back of the front dorsal fin.",
                "Frog-like head with raised eyes near the top.",
                "Brown to grey mottling, rarely over 15 cm."
            ],
            lookalikes: [],
            traits: [.twoSeparateDorsals, .darkMottling, .roundedTail],
            sizeCutoffsCm: [7, 10, 13, 16],
            weightA: nil,
            weightB: nil,
            colorHex: 0x5A5244,
            habitat: "Rocky and rubble bottoms in lakes and rivers, from shore out to deep water.",
            range: "The Great Lakes, mostly Erie, Ontario, Huron, and St. Clair, plus the St. Lawrence and connected rivers."
        ),
    ]
}
