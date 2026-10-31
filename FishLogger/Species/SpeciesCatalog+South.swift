import Foundation

// Southern and eastern US bass, panfish and warm-water exotics. Weights only where a published Ws equation exists.
extension SpeciesCatalog {
    static let southernSpecies: [Species] = [

        // MARK: Black bass

        Species(
            id: "spotted_bass",
            commonName: "Spotted bass",
            otherNames: ["Kentucky bass", "Spot", "Spotted black bass"],
            scientificName: "Micropterus punctulatus",
            group: .blackBass,
            summary: "Bass of clear rivers and deep, rocky reservoirs from the Ohio Valley to the Gulf. Often holds deeper than largemouth and roams in schools.",
            idTips: [
                "Rows of small dark spots on the lower sides, forming thin stripes.",
                "Rough tooth patch on the tongue; a largemouth's tongue is smooth.",
                "Jaw reaches the back of the eye but not past it."
            ],
            lookalikes: ["largemouth_bass", "smallmouth_bass", "alabama_bass"],
            traits: [.spinyDorsal, .darkMottling, .darkSpotsLightBody, .forkedTail],
            sizeCutoffsCm: [25, 32, 40, 46],
            weightA: -5.392,
            weightB: 3.215,
            colorHex: 0x6D8555,
            habitat: "Clear streams and rivers with gentle current, and deep reservoirs with rocky banks.",
            range: "Native from Ohio and West Virginia south to the Gulf and west to Kansas and Texas, including the Florida panhandle.",
            regions: [.northernPlains, .southernPlains, .ohioValley, .midAtlantic, .southeast, .florida]
        ),
        Species(
            id: "alabama_bass",
            commonName: "Alabama bass",
            otherNames: ["Alabama spotted bass", "Spotted bass", "Spot"],
            scientificName: "Micropterus henshalli",
            group: .blackBass,
            summary: "Long treated as a spotted bass, now its own species from the Mobile River system. Grows larger and has spread to many reservoirs in the Southeast and California.",
            idTips: [
                "Rows of dark spots on the lower sides and a tooth patch on the tongue.",
                "Jaw ends at the back of the eye, not past it like a largemouth's.",
                "Hard to tell from a spotted bass by eye; range is the best clue."
            ],
            lookalikes: ["spotted_bass", "largemouth_bass", "redeye_bass"],
            traits: [.spinyDorsal, .darkMottling, .darkSpotsLightBody, .forkedTail],
            sizeCutoffsCm: [25, 33, 42, 50],
            weightA: nil,
            weightB: nil,
            colorHex: 0x3A8A58,
            habitat: "Large, clear reservoirs and rivers, often deep along rocky banks, points and bluffs.",
            range: "Native to the Mobile River system of Alabama, Georgia and Mississippi; introduced elsewhere in the Southeast and in California.",
            regions: [.california, .southeast]
        ),
        Species(
            id: "florida_bass",
            commonName: "Florida bass",
            otherNames: ["Florida largemouth bass", "Florida-strain bass", "Largemouth bass"],
            scientificName: "Micropterus salmoides",
            group: .blackBass,
            summary: "The largemouth of peninsular Florida, now treated as its own species. Grows larger than northern largemouth and is stocked across the South and in California for trophy fishing.",
            idTips: [
                "Jaw reaches past the back of the eye, as on a largemouth.",
                "Deep notch between the dorsal fins and no tooth patch on the tongue.",
                "Looks like a largemouth; only a genetic test tells them apart for sure."
            ],
            lookalikes: ["largemouth_bass", "spotted_bass", "suwannee_bass"],
            traits: [.spinyDorsal, .largeMouth, .darkMottling, .forkedTail],
            sizeCutoffsCm: [28, 38, 50, 60],
            weightA: nil,
            weightB: nil,
            colorHex: 0x2F7231,
            habitat: "Shallow, weedy lakes, slow rivers and canals, around grass, lily pads and fallen timber.",
            range: "Native to peninsular Florida and mixed with largemouth in nearby states; stocked in Texas, California and across the South.",
            regions: [.california, .southernPlains, .southeast, .florida]
        ),
        Species(
            id: "guadalupe_bass",
            commonName: "Guadalupe bass",
            otherNames: ["Guad", "Guadalupe spotted bass"],
            scientificName: "Micropterus treculii",
            group: .blackBass,
            summary: "Small, hard-fighting bass found only in the rivers of the Texas Hill Country. It is the state fish of Texas.",
            idTips: [
                "Dark diamond-shaped blotches along the side, with rows of spots below.",
                "Jaw stops at the back of the eye; a largemouth's reaches past it.",
                "No bronze vertical bars like a smallmouth; rarely over 35 cm."
            ],
            lookalikes: ["spotted_bass", "smallmouth_bass", "largemouth_bass"],
            traits: [.spinyDorsal, .darkMottling, .darkSpotsLightBody, .forkedTail],
            sizeCutoffsCm: [20, 25, 30, 36],
            weightA: nil,
            weightB: nil,
            colorHex: 0x588C3A,
            habitat: "Clear, flowing streams and rivers, around riffles, boulders and cypress roots.",
            range: "Found only in central Texas, in the Guadalupe, San Antonio, Colorado and Brazos river systems.",
            regions: [.southernPlains]
        ),
        Species(
            id: "shoal_bass",
            commonName: "Shoal bass",
            otherNames: ["Flint River smallmouth"],
            scientificName: "Micropterus cataractae",
            group: .blackBass,
            summary: "River bass of rocky shoals in the Apalachicola basin of Georgia, Alabama and Florida. Numbers have fallen in much of its range, so many anglers release them.",
            idTips: [
                "Dark vertical blotches along the sides instead of a solid stripe.",
                "No white edges on the tail; a redeye bass has them.",
                "Jaw reaches the back of the eye but not past it."
            ],
            lookalikes: ["smallmouth_bass", "chattahoochee_bass", "redeye_bass", "alabama_bass"],
            traits: [.spinyDorsal, .verticalBars, .darkMottling, .forkedTail],
            sizeCutoffsCm: [25, 33, 40, 48],
            weightA: nil,
            weightB: nil,
            colorHex: 0x78572E,
            habitat: "Rocky shoals, riffles and runs in medium to large rivers with steady current.",
            range: "The Apalachicola, Chattahoochee and Flint river systems of Georgia, Alabama and Florida, including the Chipola River.",
            regions: [.southeast, .florida]
        ),
        Species(
            id: "redeye_bass",
            commonName: "Redeye bass",
            otherNames: ["Coosa bass", "Redeye"],
            scientificName: "Micropterus coosae",
            group: .blackBass,
            summary: "Small, colourful bass of cool, rocky upland streams, a fine catch on a light fly rod. Recent splits limit the name to fish of the Coosa River system.",
            idTips: [
                "Upper and lower edges of the tail are white or pale.",
                "Soft dorsal, anal and tail fins tinged brick red or orange.",
                "Small for a bass, rarely over 30 cm, and usually in small streams."
            ],
            lookalikes: ["shoal_bass", "alabama_bass", "smallmouth_bass"],
            traits: [.spinyDorsal, .goldenColor, .forkedTail],
            sizeCutoffsCm: [15, 20, 25, 30],
            weightA: nil,
            weightB: nil,
            colorHex: 0xA03A32,
            habitat: "Clear, rocky upland streams and small rivers, in pools and around boulders.",
            range: "Upland streams of the Coosa River system in Alabama, Georgia and Tennessee.",
            regions: [.southeast]
        ),
        Species(
            id: "suwannee_bass",
            commonName: "Suwannee bass",
            otherNames: [],
            scientificName: "Micropterus notius",
            group: .blackBass,
            summary: "Small, stocky bass of spring-fed rivers in north Florida. Fights hard for its size around limestone shoals.",
            idTips: [
                "Blue to turquoise colour on the cheeks, chin and belly of adults.",
                "Short, chunky body with dark vertical blotches along the side.",
                "Jaw reaches the back of the eye but not past it, unlike a Florida bass."
            ],
            lookalikes: ["florida_bass", "largemouth_bass"],
            traits: [.spinyDorsal, .verticalBars, .forkedTail],
            sizeCutoffsCm: [18, 24, 30, 36],
            weightA: nil,
            weightB: nil,
            colorHex: 0x2F8786,
            habitat: "Limestone shoals and runs in clear, spring-fed rivers with steady current.",
            range: "The Suwannee and Ochlockonee river systems of north Florida and southern Georgia.",
            regions: [.southeast, .florida]
        ),

        // MARK: Sunfish

        Species(
            id: "ozark_bass",
            commonName: "Ozark bass",
            otherNames: ["Goggle-eye", "Red eye"],
            scientificName: "Ambloplites constellatus",
            group: .sunfish,
            summary: "Rock bass relative found only in Ozark streams of the White River system. Bites readily in clear, rocky pools.",
            idTips: [
                "Dark freckles scattered over the sides; a rock bass has spots in rows.",
                "Six anal spines, like a rock bass; a warmouth has three.",
                "Found only in the White River system of Missouri and Arkansas."
            ],
            lookalikes: ["rock_bass", "warmouth"],
            traits: [.deepFlatBody, .spinyDorsal, .darkSpotsLightBody, .forkedTail],
            sizeCutoffsCm: [12, 16, 20, 24],
            weightA: nil,
            weightB: nil,
            colorHex: 0x835E4A,
            habitat: "Clear, cool streams with rocky pools, boulders and steady flow.",
            range: "The White River system of southern Missouri and northern Arkansas.",
            regions: [.ohioValley, .southeast]
        ),
        Species(
            id: "redear_sunfish",
            commonName: "Redear sunfish",
            otherNames: ["Shellcracker", "Chinquapin", "Bream"],
            scientificName: "Lepomis microlophus",
            group: .sunfish,
            summary: "Large sunfish that feeds on snails near the bottom. Grows bigger than a bluegill and is very good eating.",
            idTips: [
                "Black ear flap with a red or orange edge.",
                "No wavy blue lines on the cheek, unlike a pumpkinseed.",
                "No dark spot at the back of the soft dorsal fin, unlike a bluegill."
            ],
            lookalikes: ["bluegill", "pumpkinseed"],
            traits: [.deepFlatBody, .spinyDorsal, .earFlap, .smallMouth, .forkedTail],
            sizeCutoffsCm: [15, 20, 25, 30],
            weightA: -4.968,
            weightB: 3.119,
            colorHex: 0x72622C,
            habitat: "Warm, clear lakes, ponds and slow rivers, usually near the bottom around weeds and stumps.",
            range: "Native from the Carolinas and Florida west to Texas and north to southern Illinois; stocked widely, including Arizona and California.",
            regions: [.california, .southwest, .northernPlains, .southernPlains, .ohioValley, .midAtlantic, .southeast, .florida]
        ),
        Species(
            id: "green_sunfish",
            commonName: "Green sunfish",
            otherNames: ["Green perch", "Sunfish", "Crapet vert"],
            scientificName: "Lepomis cyanellus",
            group: .sunfish,
            summary: "Thick, aggressive little sunfish that thrives in ponds, ditches and creeks. Often crosses with bluegill and other sunfish.",
            idTips: [
                "Large mouth for a sunfish, with the jaw reaching below the eye.",
                "Dark ear flap with a pale yellow or white edge.",
                "Dark spot at the back of the soft dorsal and anal fins."
            ],
            lookalikes: ["warmouth", "bluegill", "pumpkinseed"],
            traits: [.spinyDorsal, .earFlap, .forkedTail],
            sizeCutoffsCm: [10, 14, 18, 22],
            weightA: -4.915,
            weightB: 3.111,
            colorHex: 0x29665E,
            habitat: "Small ponds, ditches, creeks and weedy shallows, including warm or muddy water other sunfish avoid.",
            range: "Native from southwestern Ontario west to the Dakotas and south to Texas and the Gulf; introduced across most of the US.",
            regions: [.ontario, .california, .mountainWest, .southwest, .northernPlains, .southernPlains, .upperMidwest, .ohioValley, .northeast, .midAtlantic, .southeast]
        ),
        Species(
            id: "warmouth",
            commonName: "Warmouth",
            otherNames: ["Goggle-eye", "Mud bass"],
            scientificName: "Lepomis gulosus",
            group: .sunfish,
            summary: "Chunky, big-mouthed sunfish of swamps and weedy backwaters. Often mistaken for a rock bass.",
            idTips: [
                "Dark red-brown lines running back from the eye across the cheek.",
                "Small tooth patch on the tongue, unlike bluegill or green sunfish.",
                "Three anal spines; a rock bass has six."
            ],
            lookalikes: ["rock_bass", "green_sunfish", "ozark_bass"],
            traits: [.spinyDorsal, .earFlap, .darkMottling, .forkedTail],
            sizeCutoffsCm: [12, 16, 20, 24],
            weightA: nil,
            weightB: nil,
            colorHex: 0x84504A,
            habitat: "Swamps, weedy ponds, backwaters and slow streams with soft bottoms and plenty of cover.",
            range: "Native from Virginia south to Florida and west to Texas, and up the Mississippi basin to the southern Great Lakes.",
            regions: [.southernPlains, .ohioValley, .midAtlantic, .southeast, .florida]
        ),
        Species(
            id: "longear_sunfish",
            commonName: "Longear sunfish",
            otherNames: ["Longear"],
            scientificName: "Lepomis megalotis",
            group: .sunfish,
            summary: "One of the most colourful sunfish, common in clear, rocky creeks. Small, but quick to take tiny flies and baits.",
            idTips: [
                "Very long black ear flap, often tilted up, with a pale edge.",
                "Wavy blue lines on the cheek and an orange to red belly.",
                "Short, rounded pectoral fins; bluegill and redear have long, pointed ones."
            ],
            lookalikes: ["redbreast_sunfish", "pumpkinseed", "bluegill"],
            traits: [.deepFlatBody, .spinyDorsal, .earFlap, .forkedTail],
            sizeCutoffsCm: [8, 11, 14, 17],
            weightA: nil,
            weightB: nil,
            colorHex: 0xA86C34,
            habitat: "Clear, rocky creeks and small rivers with pools and gentle current.",
            range: "The Mississippi basin from Ohio and Indiana south to the Gulf and west to Texas; Great Lakes fish are now a separate species.",
            regions: [.southernPlains, .ohioValley, .southeast]
        ),
        Species(
            id: "redbreast_sunfish",
            commonName: "Redbreast sunfish",
            otherNames: ["Redbreast", "Robin", "Yellowbelly"],
            scientificName: "Lepomis auritus",
            group: .sunfish,
            summary: "Common river sunfish of the Atlantic coast. Holds in current around rocks and logs and takes small spinners and flies.",
            idTips: [
                "Long, narrow ear flap that is solid black to the edge.",
                "Orange to red breast and belly, brightest on breeding males.",
                "Thin blue lines on the cheek, running back from the snout."
            ],
            lookalikes: ["longear_sunfish", "pumpkinseed", "bluegill"],
            traits: [.deepFlatBody, .spinyDorsal, .earFlap, .forkedTail],
            sizeCutoffsCm: [11, 14, 18, 22],
            weightA: nil,
            weightB: nil,
            colorHex: 0xBA5434,
            habitat: "Rivers and streams with moderate current, around rocks, logs and undercut banks; also lakes and ponds.",
            range: "Atlantic and eastern Gulf drainages from Maine to central Florida; introduced in central Texas and elsewhere in the South.",
            regions: [.southernPlains, .northeast, .midAtlantic, .southeast, .florida]
        ),
        Species(
            id: "spotted_sunfish",
            commonName: "Spotted sunfish",
            otherNames: ["Stumpknocker", "Spotted bream"],
            scientificName: "Lepomis punctatus",
            group: .sunfish,
            summary: "Small, speckled sunfish of Florida springs and swampy streams, better known as the stumpknocker. Bites hard for its size.",
            idTips: [
                "Black specks over the head and sides, many lined up in rows.",
                "Short, dark ear flap on a dark olive to brown body.",
                "Usually 10 to 15 cm, rarely over 20 cm."
            ],
            lookalikes: ["flier", "warmouth"],
            traits: [.deepFlatBody, .spinyDorsal, .earFlap, .darkSpotsLightBody],
            sizeCutoffsCm: [8, 11, 14, 17],
            weightA: nil,
            weightB: nil,
            colorHex: 0x788244,
            habitat: "Spring runs, clear streams and swamps, close to stumps, roots and fallen trees.",
            range: "Coastal plain from the Carolinas through Georgia and all of Florida.",
            regions: [.southeast, .florida]
        ),
        Species(
            id: "flier",
            commonName: "Flier",
            otherNames: ["Flier sunfish", "Round sunfish"],
            scientificName: "Centrarchus macropterus",
            group: .sunfish,
            summary: "Round, saucer-shaped sunfish of blackwater swamps and ponds. Looks like a small crappie and bites small jigs and worms.",
            idTips: [
                "Rows of dark spots along the sides form thin horizontal lines.",
                "Dark teardrop bar below the eye.",
                "Eleven or more dorsal spines; crappies have eight or fewer."
            ],
            lookalikes: ["black_crappie", "white_crappie", "spotted_sunfish"],
            traits: [.deepFlatBody, .spinyDorsal, .darkSpotsLightBody],
            sizeCutoffsCm: [9, 12, 15, 18],
            weightA: nil,
            weightB: nil,
            colorHex: 0x5C8070,
            habitat: "Swamps, blackwater streams, ponds and backwaters with tea-stained water and thick weeds.",
            range: "Coastal plain swamps and lowlands from Virginia to Florida and west to eastern Texas.",
            regions: [.southernPlains, .midAtlantic, .southeast, .florida]
        ),

        // MARK: Gar

        Species(
            id: "florida_gar",
            commonName: "Florida gar",
            otherNames: ["Gar", "Garfish"],
            scientificName: "Lepisosteus platyrhincus",
            group: .ancient,
            summary: "Common gar of Florida's lakes, canals and slow rivers. Breathes air and often rolls at the surface on calm days.",
            idTips: [
                "Short, broad snout; a longnose gar's beak is long and narrow.",
                "Round dark spots over the head, body and fins.",
                "Nearly identical to spotted gar; where it was caught is the best clue."
            ],
            lookalikes: ["spotted_gar", "longnose_gar"],
            traits: [.torpedoBody, .longToothySnout, .bonyPlates, .darkSpotsLightBody, .roundedTail],
            sizeCutoffsCm: [38, 50, 63, 76],
            weightA: nil,
            weightB: nil,
            colorHex: 0x56744E,
            habitat: "Lakes, canals, ponds and slow, weedy rivers, usually in still, warm water.",
            range: "From the Ochlockonee River in Florida and Georgia east and south through peninsular Florida.",
            regions: [.southeast, .florida]
        ),

        // MARK: Warm-water exotics

        Species(
            id: "peacock_bass",
            commonName: "Peacock bass",
            otherNames: ["Butterfly peacock bass", "Butterfly peacock", "Peacock"],
            scientificName: "Cichla ocellaris",
            group: .other,
            summary: "South American cichlid stocked in south Florida canals in the 1980s to control other exotic fish. Hits lures hard, and cold snaps keep it to the southeast of the state.",
            idTips: [
                "Black eyespot ringed in gold at the base of the tail.",
                "Three dark vertical blotches along gold to green sides.",
                "Spawning males grow a hump on the forehead."
            ],
            lookalikes: ["florida_bass", "largemouth_bass", "mayan_cichlid"],
            traits: [.spinyDorsal, .verticalBars, .goldenColor],
            sizeCutoffsCm: [25, 33, 40, 48],
            weightA: nil,
            weightB: nil,
            colorHex: 0x8C8530,
            habitat: "Warm canals, lakes and ponds, often near bridges, culverts and rocky edges.",
            range: "Canals and lakes of southeast Florida, mostly Miami-Dade and Broward counties; native to South America.",
            regions: [.florida]
        ),
        Species(
            id: "mayan_cichlid",
            commonName: "Mayan cichlid",
            otherNames: ["Mayan"],
            scientificName: "Mayaheros urophthalmus",
            group: .other,
            summary: "Central American cichlid now common in south Florida canals and the Everglades, even in brackish water. Fights hard for its size and is good eating.",
            idTips: [
                "Large black eyespot with a pale ring at the base of the tail.",
                "Six or seven dark vertical bars on an olive to tan body.",
                "Red to orange throat and chest, brightest when breeding."
            ],
            lookalikes: ["peacock_bass", "rio_grande_cichlid"],
            traits: [.deepFlatBody, .spinyDorsal, .verticalBars],
            sizeCutoffsCm: [12, 16, 20, 25],
            weightA: nil,
            weightB: nil,
            colorHex: 0xB04A72,
            habitat: "Canals, ponds, marshes and mangrove creeks, in fresh or brackish water.",
            range: "South Florida, including the Everglades and Florida Bay; native to southern Mexico and Central America.",
            regions: [.florida]
        ),
        Species(
            id: "rio_grande_cichlid",
            commonName: "Rio Grande cichlid",
            otherNames: ["Texas cichlid", "Rio Grande perch"],
            scientificName: "Herichthys cyanoguttatus",
            group: .other,
            summary: "The only cichlid native to the United States, from the lower Rio Grande in Texas. Now spread to central Texas spring rivers and the New Orleans area.",
            idTips: [
                "Pale blue or white spots all over a grey to olive body.",
                "Lateral line broken into two parts, as on all cichlids.",
                "Mature males grow a hump on the forehead."
            ],
            lookalikes: ["green_sunfish", "mayan_cichlid"],
            traits: [.deepFlatBody, .spinyDorsal, .lightSpotsDarkBody],
            sizeCutoffsCm: [12, 16, 21, 26],
            weightA: nil,
            weightB: nil,
            colorHex: 0x4A72B0,
            habitat: "Spring-fed rivers, canals, ponds and slow streams with warm water and rocky or weedy cover.",
            range: "Native to the lower Rio Grande in Texas and northeastern Mexico; established in central Texas rivers and around New Orleans.",
            regions: [.southernPlains, .southeast]
        ),
        Species(
            id: "bullseye_snakehead",
            commonName: "Bullseye snakehead",
            otherNames: ["Great snakehead", "Cobra snakehead", "Snakehead"],
            scientificName: "Channa marulius",
            group: .other,
            summary: "Large Asian snakehead established in canals of southeast Florida. Hits topwater lures hard; never move or release one alive.",
            idTips: [
                "Long anal fin as well as a long dorsal; a bowfin's anal fin is short.",
                "Flat, scaly, snake-like head with no bony plate under the chin.",
                "Orange-ringed black eyespot near the tail base; a northern snakehead has none."
            ],
            lookalikes: ["ruddy_bowfin", "northern_snakehead"],
            traits: [.torpedoBody, .largeMouth, .longDorsalFin, .darkMottling, .roundedTail],
            sizeCutoffsCm: [40, 50, 62, 75],
            weightA: nil,
            weightB: nil,
            colorHex: 0x6B5A6E,
            habitat: "Warm, weedy canals and lakes with slow water, often close to shore cover.",
            range: "Canals of southeast Florida, centred on Broward County; native to southern Asia.",
            regions: [.florida]
        ),
    ]
}
