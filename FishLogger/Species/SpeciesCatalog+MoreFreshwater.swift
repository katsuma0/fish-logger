import Foundation

// Freshwater and sea-run fish still missing from the catalogue: kokanee, steelhead, smelt, tomcod, suckers, and the split redeye basses. Weights only where a published equation exists.
extension SpeciesCatalog {
    static let moreFreshwaterSpecies: [Species] = [

        // MARK: Trout and salmon

        Species(
            id: "kokanee",
            commonName: "Kokanee",
            otherNames: ["Kokanee salmon", "Silver trout", "Landlocked sockeye", "Kokani"],
            scientificName: "Oncorhynchus nerka",
            group: .salmon,
            summary: "Landlocked sockeye salmon that spends its whole life in lakes, feeding on plankton. Schools roam open water and are often caught trolling small lures behind dodgers.",
            idTips: [
                "No spots on the tail; a rainbow trout's tail is covered in black spots.",
                "Dark blue back over plain silver sides; spawners turn red with a green head.",
                "Lives its whole life in lakes and is much smaller than sea-run sockeye."
            ],
            lookalikes: ["sockeye_salmon", "rainbow_trout"],
            traits: [.adiposeFin, .torpedoBody, .silverColor, .forkedTail],
            sizeCutoffsCm: [22, 30, 38, 46],
            weightA: -5.062,
            weightB: 3.033,
            colorHex: 0xC94754,
            habitat: "Cool, deep lakes and reservoirs; spawns in tributary streams or along gravel shores.",
            range: "Native to lakes in BC, the Yukon, Alaska, and the Pacific Northwest; stocked in lakes across the West.",
            regions: [.britishColumbia, .northernCanada, .alaska, .pacificNorthwest, .california, .mountainWest, .southwest]
        ),
        Species(
            id: "steelhead",
            commonName: "Steelhead",
            otherNames: ["Steelhead trout", "Steelie", "Chromer", "Sea-run rainbow trout", "Lake-run rainbow trout"],
            scientificName: "Oncorhynchus mykiss",
            group: .troutChar,
            summary: "Rainbow trout that grow large in the ocean or the Great Lakes and return to rivers to spawn. Unlike Pacific salmon, some survive spawning and return to spawn again.",
            idTips: [
                "White mouth and gums; chinook and coho salmon have dark mouths.",
                "Black spots across the whole tail; a coho's are only on the upper lobe.",
                "Fresh fish are chrome with a faint pink band; river rainbows are darker."
            ],
            lookalikes: ["rainbow_trout", "coho_salmon", "chinook_salmon"],
            traits: [.adiposeFin, .torpedoBody, .darkSpotsLightBody, .silverColor],
            sizeCutoffsCm: [50, 60, 70, 80],
            weightA: nil,
            weightB: nil,
            colorHex: 0x5578A3,
            habitat: "Grows in the ocean or the Great Lakes; spawns in cold, fast rivers and their tributaries.",
            range: "Pacific coast rivers from California to Alaska; stocked in the Great Lakes, where many tributaries now have wild runs.",
            regions: [.britishColumbia, .ontario, .alaska, .pacificNorthwest, .california, .upperMidwest, .ohioValley, .northeast]
        ),

        // MARK: Black bass

        Species(
            id: "chattahoochee_bass",
            commonName: "Chattahoochee bass",
            otherNames: ["Redeye bass"],
            scientificName: "Micropterus chattahoochae",
            group: .blackBass,
            summary: "Small, colourful bass of upland streams in the Chattahoochee River system, split from redeye bass in 2013. It is uncommon, even in the streams where it lives.",
            idTips: [
                "Broad, bright red-orange edges on the soft dorsal, anal, and tail fins.",
                "Usually under 28 cm; shoal and Alabama bass grow much larger.",
                "Only in the Chattahoochee River system; true redeye bass live in the Coosa."
            ],
            lookalikes: ["shoal_bass", "alabama_bass", "redeye_bass"],
            traits: [.spinyDorsal, .darkMottling, .forkedTail],
            sizeCutoffsCm: [15, 20, 25, 30],
            weightA: nil,
            weightB: nil,
            colorHex: 0x944E2E,
            habitat: "Clear, rocky upland streams and small rivers, in runs and pools.",
            range: "Upland streams of the Chattahoochee River system, mainly in Georgia.",
            regions: [.southeast]
        ),
        Species(
            id: "tallapoosa_bass",
            commonName: "Tallapoosa bass",
            otherNames: ["Redeye bass"],
            scientificName: "Micropterus tallapoosae",
            group: .blackBass,
            summary: "Stream bass of the Tallapoosa River system in Alabama and Georgia, split from redeye bass in 2013. Hits small spinners, crayfish lures, and flies in rocky runs and pools.",
            idTips: [
                "Yellow-green soft dorsal, anal, and tail fins with white edges.",
                "No red or orange in the fins; a redeye bass's fins are brick red.",
                "Found only in the Tallapoosa River system of Alabama and Georgia."
            ],
            lookalikes: ["alabama_bass", "redeye_bass"],
            traits: [.spinyDorsal, .darkMottling, .forkedTail],
            sizeCutoffsCm: [18, 24, 30, 36],
            weightA: nil,
            weightB: nil,
            colorHex: 0x3E6625,
            habitat: "Rocky upland streams and small rivers with clear water and steady current.",
            range: "Upland streams of the Tallapoosa River system in eastern Alabama and western Georgia.",
            regions: [.southeast]
        ),
        Species(
            id: "bartrams_bass",
            commonName: "Bartram's bass",
            otherNames: ["Bartram bass", "Redeye bass"],
            scientificName: "Micropterus pucpuggy",
            group: .blackBass,
            summary: "Colourful native bass of the Savannah River system, long called redeye bass and formally described in 2025. Habitat change and crossing with introduced bass are its main threats.",
            idTips: [
                "Tail has little or no spotting and a narrow pale lower edge.",
                "Soft dorsal, anal, and tail fins usually tinged orange to yellow at the edges.",
                "Found only in the Savannah River system; true redeye bass live in the Coosa."
            ],
            lookalikes: ["alabama_bass", "redeye_bass"],
            traits: [.spinyDorsal, .darkMottling, .goldenColor, .forkedTail],
            sizeCutoffsCm: [15, 22, 28, 34],
            weightA: nil,
            weightB: nil,
            colorHex: 0xBD4D96,
            habitat: "Clear, rocky streams and small rivers in the mountains and Piedmont, in pools and runs.",
            range: "The Savannah River system of Georgia, South Carolina, and North Carolina.",
            regions: [.southeast]
        ),
        Species(
            id: "warrior_bass",
            commonName: "Warrior bass",
            otherNames: ["Redeye bass"],
            scientificName: "Micropterus warriorensis",
            group: .blackBass,
            summary: "Small bass of upland streams in Alabama's Black Warrior River system, split from redeye bass in 2013. Patchy and uncommon even within its small range.",
            idTips: [
                "Usually no tooth patch on the tongue; an Alabama bass has one.",
                "Orange on the anal fin, often also on the soft dorsal and tail.",
                "Found only in the Black Warrior River system of north-central Alabama."
            ],
            lookalikes: ["alabama_bass", "redeye_bass", "cahaba_bass"],
            traits: [.spinyDorsal, .darkMottling, .forkedTail],
            sizeCutoffsCm: [15, 20, 26, 32],
            weightA: nil,
            weightB: nil,
            colorHex: 0x824F28,
            habitat: "Clear, rocky streams and small rivers with riffles, pools, and steady flow.",
            range: "Upland streams of the Black Warrior River system in north-central Alabama.",
            regions: [.southeast]
        ),
        Species(
            id: "cahaba_bass",
            commonName: "Cahaba bass",
            otherNames: ["Redeye bass"],
            scientificName: "Micropterus cahabae",
            group: .blackBass,
            summary: "Small bass found only in the Cahaba River system of central Alabama, split from redeye bass in 2013. It is uncommon, even within that small range.",
            idTips: [
                "Short, wide dark bars along the side that become round spots toward the tail.",
                "No red or orange in the fins; a redeye or Warrior bass has some.",
                "Found only in the Cahaba River system of central Alabama."
            ],
            lookalikes: ["alabama_bass", "redeye_bass", "warrior_bass"],
            traits: [.spinyDorsal, .verticalBars, .darkSpotsLightBody, .forkedTail],
            sizeCutoffsCm: [15, 20, 26, 32],
            weightA: nil,
            weightB: nil,
            colorHex: 0x2E822E,
            habitat: "Clear, rocky upland streams and small rivers with riffles and pools.",
            range: "Upland reaches of the Cahaba River system in central Alabama.",
            regions: [.southeast]
        ),

        // MARK: Sunfish

        Species(
            id: "roanoke_bass",
            commonName: "Roanoke bass",
            otherNames: ["Redeye"],
            scientificName: "Ambloplites cavifrons",
            group: .sunfish,
            summary: "Rock bass found only in a few river systems of Virginia and North Carolina. Bites small lures and live bait in rocky pools and runs.",
            idTips: [
                "Cheek bare or only partly scaled; a rock bass's cheek is fully scaled.",
                "Anal fin has no dark edge; a rock bass's anal fin is edged in black.",
                "Usually six anal spines; a warmouth has three."
            ],
            lookalikes: ["rock_bass", "warmouth"],
            traits: [.deepFlatBody, .spinyDorsal, .lightSpotsDarkBody, .forkedTail],
            sizeCutoffsCm: [15, 20, 25, 30],
            weightA: nil,
            weightB: nil,
            colorHex: 0x7D5136,
            habitat: "Clear, rocky rivers and streams with pools, boulders, and moderate current.",
            range: "Native to the Roanoke, Chowan, Tar, and Neuse river systems of Virginia and North Carolina.",
            regions: [.midAtlantic, .southeast]
        ),

        // MARK: Suckers and buffalo

        Species(
            id: "shorthead_redhorse",
            commonName: "Shorthead redhorse",
            otherNames: ["Redhorse", "Northern redhorse", "Redhorse sucker", "Chevalier rouge"],
            scientificName: "Moxostoma macrolepidotum",
            group: .carpSuckers,
            summary: "Common redhorse sucker of clear rivers across much of the continent, with a bright red tail. Pulls hard on light tackle and bites worms on the bottom, best during its spring spawning run.",
            idTips: [
                "Bright red tail; a white sucker's tail is grey or dusky.",
                "Large scales, fewer than 50 along the side; a white sucker has many more.",
                "Short head and sucker mouth with no barbels, unlike a carp."
            ],
            lookalikes: ["white_sucker", "common_carp"],
            traits: [.torpedoBody, .smallMouth, .goldenColor, .forkedTail],
            sizeCutoffsCm: [28, 36, 44, 52],
            weightA: nil,
            weightB: nil,
            colorHex: 0xC45147,
            habitat: "Rivers and large streams with moderate current over gravel, sand, or rock; also large lakes.",
            range: "Great Lakes, St. Lawrence, Hudson Bay, and Mississippi basins from Quebec to Alberta, south to Oklahoma and northern Alabama; also Atlantic rivers from New York to South Carolina.",
            regions: [.prairies, .ontario, .quebec, .mountainWest, .northernPlains, .southernPlains, .upperMidwest, .ohioValley, .northeast, .midAtlantic, .southeast]
        ),
        Species(
            id: "black_buffalo",
            commonName: "Black buffalo",
            otherNames: ["Buffalo", "Buffalofish"],
            scientificName: "Ictiobus niger",
            group: .carpSuckers,
            summary: "Big, dark buffalo of large rivers with steady current, often scarcer than its bigmouth and smallmouth cousins. Takes dough, corn, and worms fished on the bottom, and is a common bowfishing target.",
            idTips: [
                "Small mouth just under the snout tip; a bigmouth buffalo's is large and faces forward.",
                "Thick, round body with a low back; a smallmouth buffalo has a high hump.",
                "No barbels at the mouth, unlike a common carp."
            ],
            lookalikes: ["smallmouth_buffalo", "bigmouth_buffalo", "common_carp"],
            traits: [.smallMouth, .longDorsalFin, .forkedTail],
            sizeCutoffsCm: [45, 60, 75, 90],
            weightA: nil,
            weightB: nil,
            colorHex: 0x4A4E7C,
            habitat: "Large rivers with strong current and deep channels; also big reservoirs and backwaters.",
            range: "The Mississippi basin from Wisconsin, Ohio, and South Dakota south to Louisiana, and Gulf drainages west to Texas.",
            regions: [.northernPlains, .southernPlains, .upperMidwest, .ohioValley, .southeast]
        ),

        // MARK: Everything else

        Species(
            id: "rainbow_smelt",
            commonName: "Rainbow smelt",
            otherNames: ["Smelt", "American smelt", "Éperlan arc-en-ciel"],
            scientificName: "Osmerus mordax",
            group: .other,
            summary: "Small, slender fish of cold lakes and coastal waters that crowds into streams to spawn in early spring. Dip-netted on spring runs, jigged through the ice in winter, and good eating fried whole.",
            idTips: [
                "Big mouth with sharp teeth on the jaws and tongue; a cisco has almost none.",
                "Slim, nearly see-through body with a silver stripe tinted pink, blue, or purple.",
                "Fresh fish smell like cut cucumber."
            ],
            lookalikes: ["cisco"],
            traits: [.adiposeFin, .torpedoBody, .silverColor, .forkedTail],
            sizeCutoffsCm: [13, 17, 21, 25],
            weightA: nil,
            weightB: nil,
            colorHex: 0x8F4B96,
            habitat: "Cool, open water of deep lakes and coastal bays; spawns over gravel in streams and along shores.",
            range: "Native to Atlantic coastal waters and lakes from Labrador to the Delaware River; introduced in the Great Lakes, Lake Winnipeg, and Missouri River reservoirs.",
            regions: [.prairies, .ontario, .quebec, .atlanticCanada, .northernPlains, .upperMidwest, .ohioValley, .northeast]
        ),
        Species(
            id: "atlantic_tomcod",
            commonName: "Atlantic tomcod",
            otherNames: ["Tomcod", "Frostfish", "Poulamon atlantique", "Petit poisson des chenaux"],
            scientificName: "Microgadus tomcod",
            group: .inshore,
            summary: "Small cod of bays, estuaries, and tidal rivers that spawns in midwinter. At Sainte-Anne-de-la-Pérade, Quebec, anglers fish its winter spawning run from heated cabins on the frozen Sainte-Anne River.",
            idTips: [
                "Rounded tail; an Atlantic cod's tail is square or slightly concave.",
                "Pelvic fins end in a long, thin thread.",
                "Three dorsal fins and a chin barbel; a burbot has only two dorsal fins."
            ],
            lookalikes: ["atlantic_cod", "burbot"],
            traits: [.barbels, .darkMottling, .roundedTail],
            sizeCutoffsCm: [15, 20, 25, 30],
            weightA: nil,
            weightB: nil,
            colorHex: 0x736E4C,
            habitat: "Shallow coastal water, estuaries, and tidal rivers; moves into fresh water to spawn in winter.",
            range: "Coastal waters from Labrador to Virginia, including the St. Lawrence estuary and the Gulf of St. Lawrence.",
            regions: [.quebec, .atlanticCanada, .northeast]
        ),
        Species(
            id: "blue_tilapia",
            commonName: "Blue tilapia",
            otherNames: ["Tilapia"],
            scientificName: "Oreochromis aureus",
            group: .other,
            summary: "African cichlid established in warm waters of Florida and Texas, where it can crowd out native fish. Feeds mostly on algae and detritus, so it rarely takes lures; anglers catch it by bowfishing or on small dough baits.",
            idTips: [
                "Lateral line broken in two; a bluegill's runs unbroken along the side.",
                "No black eyespot at the tail base; a Mayan cichlid has one.",
                "Breeding males turn metallic blue on the head, with red-edged dorsal and tail fins."
            ],
            lookalikes: ["mayan_cichlid", "bluegill"],
            traits: [.deepFlatBody, .spinyDorsal, .smallMouth],
            sizeCutoffsCm: [20, 28, 35, 42],
            weightA: nil,
            weightB: nil,
            colorHex: 0x4A6ECF,
            habitat: "Warm lakes, canals, ponds, and slow rivers; males dig round nest pits in shallow water.",
            range: "Native to North Africa and the Middle East; established in Florida and Texas, with scattered populations elsewhere in the South.",
            regions: [.southernPlains, .florida]
        ),
    ]
}
