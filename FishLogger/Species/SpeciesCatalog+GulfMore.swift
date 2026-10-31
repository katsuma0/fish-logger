import Foundation

// More fish of the Gulf coast, Florida and the South Atlantic, from inshore flats to offshore reefs. Sizes are total length; weights only where a published length-weight relationship is known.
extension SpeciesCatalog {
    static let gulfMoreSpecies: [Species] = [

        // MARK: Inshore

        Species(
            id: "gulf_flounder",
            commonName: "Gulf flounder",
            otherNames: ["Flounder"],
            scientificName: "Paralichthys albigutta",
            group: .inshore,
            summary: "Smaller relative of the southern flounder that lies buried in sand to ambush shrimp and small fish. Most common in Florida, in saltier water over sand and seagrass.",
            idTips: [
                "Three dark eyespots form a triangle on the eyed side.",
                "A southern flounder has no ringed eyespots, only faint blotches.",
                "A summer flounder has five or more eyespots and lives mostly farther north."
            ],
            lookalikes: ["southern_flounder", "summer_flounder"],
            traits: [.eyesOnOneSide, .deepFlatBody, .largeMouth, .longDorsalFin, .darkSpotsLightBody, .darkMottling],
            sizeCutoffsCm: [28, 35, 42, 50],
            weightA: nil,
            weightB: nil,
            colorHex: 0xA08464,
            habitat: "Sand, mud and seagrass in bays, inlets and tidal creeks, and around jetties and nearshore reefs.",
            range: "North Carolina to Florida and the northern Gulf; most common in Florida and scarce west of the Mississippi delta.",
            regions: [.southeast, .florida]
        ),
        Species(
            id: "sand_seatrout",
            commonName: "Sand seatrout",
            otherNames: ["White trout", "Sand trout"],
            scientificName: "Cynoscion arenarius",
            group: .inshore,
            summary: "Pale, unspotted seatrout that schools in Gulf bays, channels and passes, and a common catch from piers and boats. Small but plentiful, and good eating when fresh.",
            idTips: [
                "Plain tan to yellowish back and silver sides, with no clear spots.",
                "A spotted seatrout has bold black spots on the back, fins and tail.",
                "Weakfish have dark speckles in slanting rows and live mainly on the Atlantic coast."
            ],
            lookalikes: ["spotted_seatrout", "weakfish"],
            traits: [.torpedoBody, .spinyDorsal, .squareTail, .silverColor],
            sizeCutoffsCm: [23, 28, 33, 40],
            weightA: nil,
            weightB: nil,
            colorHex: 0x948C54,
            habitat: "Bays, channels, passes and nearshore Gulf water over sand and mud, often schooling near the bottom.",
            range: "Gulf of Mexico, from the west coast of Florida to Texas and Mexico.",
            regions: [.southernPlains, .southeast, .florida]
        ),
        Species(
            id: "gafftopsail_catfish",
            commonName: "Gafftopsail catfish",
            otherNames: ["Gafftop", "Sail cat"],
            scientificName: "Bagre marinus",
            group: .inshore,
            summary: "Saltwater catfish of bays, passes and surf, named for its tall, sail-like dorsal fin trailing a long thread. Better eating than the hardhead catfish, but its fin spines give a painful sting.",
            idTips: [
                "Long threads trail from the dorsal and pectoral fin spines.",
                "Two long, flat, ribbon-like whiskers at the corners of the mouth.",
                "A hardhead catfish has six round whiskers and no long fin threads."
            ],
            lookalikes: [],
            traits: [.spinyDorsal, .adiposeFin, .forkedTail, .barbels, .smoothSkin],
            sizeCutoffsCm: [35, 45, 55, 65],
            weightA: nil,
            weightB: nil,
            colorHex: 0x54546C,
            habitat: "Bays, passes, channels, piers and surf over sand and mud, often in murky water.",
            range: "Florida and the Gulf coast to Texas and Mexico, and along the Atlantic coast to the Carolinas.",
            regions: [.southernPlains, .southeast, .florida]
        ),
        Species(
            id: "pinfish",
            commonName: "Pinfish",
            otherNames: ["Pin perch", "Sailor's choice", "Saltwater bream"],
            scientificName: "Lagodon rhomboides",
            group: .inshore,
            summary: "Small, bait-stealing porgy that swarms over seagrass, docks and jetties, and one of the best live baits for bigger inshore fish. Named for the sharp spines in its dorsal fin.",
            idTips: [
                "Thin blue and yellow stripes along silver sides; a spot has none.",
                "Dark spot on the shoulder behind the gill cover; a scup has none.",
                "Only faint dark bars; a sheepshead has five to seven bold black bars."
            ],
            lookalikes: ["spot", "scup", "sheepshead"],
            traits: [.deepFlatBody, .smallMouth, .spinyDorsal, .forkedTail],
            sizeCutoffsCm: [12, 16, 20, 25],
            weightA: nil,
            weightB: nil,
            colorHex: 0x64907C,
            habitat: "Seagrass flats, docks, jetties, pilings and nearshore reefs, often in large schools.",
            range: "Most common from Virginia to Florida and around the Gulf to Texas and Mexico.",
            regions: [.southernPlains, .midAtlantic, .southeast, .florida]
        ),
        Species(
            id: "atlantic_spadefish",
            commonName: "Atlantic spadefish",
            otherNames: ["Spadefish", "Spades"],
            scientificName: "Chaetodipterus faber",
            group: .inshore,
            summary: "Disc-shaped, barred fish that schools around wrecks, buoys, bridges and towers, and a summer favourite at the Chesapeake Bay Bridge-Tunnel. Often caught on small pieces of clam or jellyfish, and fights hard for its size.",
            idTips: [
                "Round, flat body with four to six black bars that fade with age.",
                "Tall, pointed rear dorsal and anal fins sweep back like sickles.",
                "A sheepshead is longer, with human-like front teeth and one continuous dorsal fin."
            ],
            lookalikes: ["sheepshead"],
            traits: [.deepFlatBody, .smallMouth, .spinyDorsal, .twoSeparateDorsals, .verticalBars],
            sizeCutoffsCm: [20, 30, 40, 50],
            weightA: nil,
            weightB: nil,
            colorHex: 0x584C5C,
            habitat: "Wrecks, reefs, bridges, buoys, pilings and towers in bays and nearshore water.",
            range: "Atlantic coast from the Chesapeake Bay to Florida and around the Gulf to Texas; strays to New England.",
            regions: [.southernPlains, .midAtlantic, .southeast, .florida]
        ),
        Species(
            id: "great_barracuda",
            commonName: "Great barracuda",
            otherNames: ["Barracuda", "Cuda"],
            scientificName: "Sphyraena barracuda",
            group: .inshore,
            summary: "Long, fang-toothed predator of flats, reefs and wrecks that hits fast lures with startling speed. Big ones can carry ciguatera, a reef toxin that sickens people, so many anglers release them.",
            idTips: [
                "Scattered inky black blotches on the lower sides toward the tail.",
                "No finlets before the tail, unlike a king mackerel.",
                "Jutting lower jaw with large, uneven fangs; grows much larger than a Pacific barracuda."
            ],
            lookalikes: ["king_mackerel", "pacific_barracuda"],
            traits: [.torpedoBody, .longToothySnout, .twoSeparateDorsals, .forkedTail, .silverColor, .darkSpotsLightBody],
            sizeCutoffsCm: [50, 75, 100, 125],
            weightA: nil,
            weightB: nil,
            colorHex: 0x385864,
            habitat: "Flats, mangrove edges, channels, reefs and wrecks, from shallow water to well offshore.",
            range: "Warm Atlantic and Indo-Pacific seas; in the US mainly Florida and the Keys, with summer fish along the Gulf and the Carolinas.",
            regions: [.southernPlains, .southeast, .florida]
        ),
        Species(
            id: "cero",
            commonName: "Cero",
            otherNames: ["Cero mackerel", "Painted mackerel"],
            scientificName: "Scomberomorus regalis",
            group: .inshore,
            summary: "Reef-loving cousin of the Spanish and king mackerels, most common in South Florida and the Keys. Usually found alone or in small groups over reefs and wrecks rather than in big schools.",
            idTips: [
                "Bronze stripe along the middle of the side, with gold spots above and below.",
                "Scales on the pectoral fins; Spanish and king mackerel have nearly bare fins.",
                "A Spanish mackerel has gold spots but no stripe; a king's lateral line dips."
            ],
            lookalikes: ["spanish_mackerel", "king_mackerel"],
            traits: [.torpedoBody, .spinyDorsal, .twoSeparateDorsals, .finlets, .forkedTail, .silverColor],
            sizeCutoffsCm: [35, 45, 55, 70],
            weightA: nil,
            weightB: nil,
            colorHex: 0x206070,
            habitat: "Coral and rock reefs, wrecks and channel edges in clear, warm water.",
            range: "South Florida, the Keys, the Bahamas and the Caribbean; uncommon north of central Florida.",
            regions: [.florida]
        ),
        Species(
            id: "blacktip_shark",
            commonName: "Blacktip shark",
            otherNames: ["Blacktip"],
            scientificName: "Carcharhinus limbatus",
            group: .inshore,
            summary: "Fast, schooling shark of beaches and inlets that often leaps and spins when hooked, and one of the sharks most often caught from the surf. Check shark rules before keeping one, since several similar sharks are protected.",
            idTips: [
                "Black tips on most fins, but the anal fin is plain.",
                "Long, pointed snout and no ridge on the back between the dorsal fins.",
                "A bull shark has a short, blunt snout and dusky fin tips at most."
            ],
            lookalikes: ["bull_shark"],
            traits: [.torpedoBody, .twoSeparateDorsals, .smoothSkin],
            sizeCutoffsCm: [90, 120, 150, 180],
            weightA: nil,
            weightB: nil,
            colorHex: 0x908474,
            habitat: "Surf, inlets, passes and nearshore water, often in big schools chasing bait.",
            range: "Warm coastal seas worldwide; in the US from Virginia to Florida and around the Gulf to Texas.",
            regions: [.southernPlains, .midAtlantic, .southeast, .florida]
        ),
        Species(
            id: "bull_shark",
            commonName: "Bull shark",
            otherNames: [],
            scientificName: "Carcharhinus leucas",
            group: .inshore,
            summary: "Heavy, powerful shark of murky bays, passes and river mouths, able to swim far up into fresh water. Potentially dangerous, so handle with great care and release big ones in the water.",
            idTips: [
                "Short, broad, blunt snout, shorter than the mouth is wide.",
                "Stout, heavy body with small eyes and a tall, triangular first dorsal fin.",
                "Fin tips dusky at most; a blacktip has crisp black tips."
            ],
            lookalikes: ["blacktip_shark"],
            traits: [.torpedoBody, .twoSeparateDorsals, .smoothSkin],
            sizeCutoffsCm: [120, 160, 200, 240],
            weightA: nil,
            weightB: nil,
            colorHex: 0x708880,
            habitat: "Murky bays, passes, river mouths and nearshore water; often enters rivers and fresh water.",
            range: "Warm coasts worldwide; in the US mainly Florida and the Gulf coast, with summer fish north to the Carolinas.",
            regions: [.southernPlains, .southeast, .florida]
        ),

        // MARK: Bottomfish

        Species(
            id: "gray_triggerfish",
            commonName: "Gray triggerfish",
            otherNames: ["Triggerfish", "Trigger", "Grey triggerfish"],
            scientificName: "Balistes capriscus",
            group: .bottomfish,
            summary: "Tough-skinned reef fish with a locking dorsal spine and strong teeth that clip baits off the hook. Hard to clean but excellent eating, and caught over reefs, wrecks and oil rigs.",
            idTips: [
                "Stout first dorsal spine locks upright; pressing the small second spine releases it.",
                "Plain grey to olive; a queen triggerfish has bright blue face lines.",
                "Small mouth with chisel-like teeth and tough, sandpaper-like skin."
            ],
            lookalikes: [],
            traits: [.deepFlatBody, .smallMouth, .spinyDorsal, .twoSeparateDorsals],
            sizeCutoffsCm: [30, 38, 46, 55],
            weightA: -4.509,
            weightB: 2.880,
            colorHex: 0x58604C,
            habitat: "Reefs, ledges, wrecks, artificial reefs and oil rigs; young fish drift under floating weed.",
            range: "Both sides of the Atlantic; in the US from Virginia to Florida and across the Gulf to Texas.",
            regions: [.southernPlains, .midAtlantic, .southeast, .florida]
        ),
        Species(
            id: "red_porgy",
            commonName: "Red porgy",
            otherNames: ["Silver snapper", "Pink porgy"],
            scientificName: "Pagrus pagrus",
            group: .bottomfish,
            summary: "Pinkish-silver porgy of offshore ledges and hard bottom, often caught on cut bait along with snapper and grouper. Most common off the Carolinas, Georgia and northeast Florida.",
            idTips: [
                "Pinkish silver with tiny blue spots on the upper sides.",
                "Steep, blunt head and small mouth; snappers have longer, pointed faces.",
                "A scup is paler, smaller and lives mostly north of the Carolinas."
            ],
            lookalikes: ["red_snapper", "vermilion_snapper", "scup"],
            traits: [.deepFlatBody, .smallMouth, .spinyDorsal, .forkedTail, .lightSpotsDarkBody],
            sizeCutoffsCm: [28, 36, 43, 50],
            weightA: -4.598,
            weightB: 2.894,
            colorHex: 0xB46878,
            habitat: "Rock ledges, live bottom, reefs and wrecks on the outer continental shelf.",
            range: "Both sides of the Atlantic; in the US mainly North Carolina to Florida, with some in the eastern Gulf.",
            regions: [.southeast, .florida]
        ),
        Species(
            id: "hogfish",
            commonName: "Hogfish",
            otherNames: ["Hog snapper"],
            scientificName: "Lachnolaimus maximus",
            group: .bottomfish,
            summary: "Large wrasse with a long, pig-like snout that roots crabs and clams out of the sand, and one of the finest eating reef fish. Most are speared, but anglers catch them on live shrimp and small crabs.",
            idTips: [
                "First three dorsal spines stretch into long, trailing streamers.",
                "Long, pig-like snout; big males are dark from the snout to the dorsal fin.",
                "Black spot at the rear base of the soft dorsal fin."
            ],
            lookalikes: [],
            traits: [.deepFlatBody, .smallMouth, .spinyDorsal, .longDorsalFin],
            sizeCutoffsCm: [30, 40, 50, 60],
            weightA: nil,
            weightB: nil,
            colorHex: 0xC0705C,
            habitat: "Reefs, rock ledges and the sand and seagrass beside them, where they root for crabs and clams.",
            range: "North Carolina to Florida and the eastern Gulf, south to Brazil; most common in Florida.",
            regions: [.southeast, .florida]
        ),
        Species(
            id: "mutton_snapper",
            commonName: "Mutton snapper",
            otherNames: ["Mutton", "Muttonfish"],
            scientificName: "Lutjanus analis",
            group: .bottomfish,
            summary: "Big, wary snapper of reefs, channels and flats, and a prized catch in South Florida and the Keys. Large fish gather on reef ledges to spawn in late spring and early summer.",
            idTips: [
                "Pointed anal fin; a lane snapper's is rounded.",
                "Small black spot on the upper side, below the soft dorsal fin.",
                "Blue lines below the eye on an olive to reddish body."
            ],
            lookalikes: ["lane_snapper", "red_snapper", "gray_snapper"],
            traits: [.deepFlatBody, .spinyDorsal, .forkedTail],
            sizeCutoffsCm: [46, 56, 66, 78],
            weightA: nil,
            weightB: nil,
            colorHex: 0xAC806C,
            habitat: "Reefs, wrecks, channel edges and grass flats, from shallow water to deep ledges.",
            range: "Mainly South Florida and the Keys, south through the Bahamas and Caribbean to Brazil.",
            regions: [.florida]
        ),
        Species(
            id: "yellowtail_snapper",
            commonName: "Yellowtail snapper",
            otherNames: ["Yellowtail", "Flag"],
            scientificName: "Ocyurus chrysurus",
            group: .bottomfish,
            summary: "Slim, fast snapper that rises into a chum slick over reefs, and a staple of Florida Keys reef fishing. Light leaders and small baits drifted back in the chum catch the most.",
            idTips: [
                "Bright yellow stripe from the snout to a deeply forked yellow tail.",
                "No black side spot, unlike lane and mutton snapper.",
                "Blue-grey back with yellow spots; a lane snapper is pink with many stripes."
            ],
            lookalikes: ["lane_snapper", "mutton_snapper"],
            traits: [.spinyDorsal, .forkedTail, .goldenColor],
            sizeCutoffsCm: [30, 36, 42, 50],
            weightA: nil,
            weightB: nil,
            colorHex: 0x807420,
            habitat: "Coral reefs, patch reefs and wrecks, usually in schools well above the bottom.",
            range: "South Florida and the Keys, the Bahamas and the Caribbean, south to Brazil.",
            regions: [.florida]
        ),
        Species(
            id: "lane_snapper",
            commonName: "Lane snapper",
            otherNames: [],
            scientificName: "Lutjanus synagris",
            group: .bottomfish,
            summary: "Small, colourful snapper of reefs, rubble and grass beds, often caught while bottom fishing for bigger snapper and grouper. Good eating despite its modest size.",
            idTips: [
                "Pink and yellow stripes along the sides, with yellow fins.",
                "Big, fuzzy black spot below the soft dorsal; rounded anal fin, unlike a mutton's.",
                "Yellowtail snapper have one bold stripe and no spot; red snapper have no stripes."
            ],
            lookalikes: ["mutton_snapper", "yellowtail_snapper", "red_snapper"],
            traits: [.deepFlatBody, .spinyDorsal, .forkedTail, .pinkOrRedStripe],
            sizeCutoffsCm: [20, 26, 32, 38],
            weightA: nil,
            weightB: nil,
            colorHex: 0xC05C6C,
            habitat: "Reefs, rubble, sand and seagrass near structure; young fish live inshore in grass beds and channels.",
            range: "Atlantic coast from North Carolina to Florida and across the Gulf to Texas; most common in Florida.",
            regions: [.southernPlains, .southeast, .florida]
        ),
        Species(
            id: "black_grouper",
            commonName: "Black grouper",
            otherNames: [],
            scientificName: "Mycteroperca bonaci",
            group: .bottomfish,
            summary: "Big, powerful grouper of reefs and ledges that bolts for a hole when hooked, so it takes heavy tackle. Most common in South Florida and the Keys.",
            idTips: [
                "Dark rectangular blotches on the sides, with brassy spots on the head.",
                "Gill cover edge evenly rounded, with no notch or spur like a gag's.",
                "No white tail edge like a gag, and no broom-like rays like a scamp."
            ],
            lookalikes: ["gag_grouper", "scamp"],
            traits: [.largeMouth, .spinyDorsal, .squareTail, .darkMottling],
            sizeCutoffsCm: [61, 76, 92, 110],
            weightA: -5.256,
            weightB: 3.141,
            colorHex: 0x644C40,
            habitat: "Coral reefs, rock ledges, drop-offs and wrecks; young fish live on shallow patch reefs.",
            range: "Mainly South Florida and the Keys, with some in the eastern Gulf, south through the Caribbean to Brazil.",
            regions: [.florida]
        ),
        Species(
            id: "scamp",
            commonName: "Scamp",
            otherNames: ["Scamp grouper"],
            scientificName: "Mycteroperca phenax",
            group: .bottomfish,
            summary: "Mid-sized grouper of offshore ledges and hard bottom, rated by many anglers as the best eating grouper. Often caught on live bait or squid fished near the bottom.",
            idTips: [
                "Adults have a ragged tail edge, with rays sticking out like a broom.",
                "Tan to brown with small dark spots in clusters, like cat paw prints.",
                "A gag has worm-like marks and a smooth tail edge with a white rim."
            ],
            lookalikes: ["gag_grouper", "black_grouper"],
            traits: [.largeMouth, .spinyDorsal, .darkSpotsLightBody],
            sizeCutoffsCm: [41, 51, 61, 75],
            weightA: nil,
            weightB: nil,
            colorHex: 0xB07874,
            habitat: "Rock ledges, live bottom and high-relief reefs on the continental shelf.",
            range: "Atlantic coast from North Carolina to Florida and across the Gulf; young fish stray farther north.",
            regions: [.southeast, .florida]
        ),
        Species(
            id: "goliath_grouper",
            commonName: "Goliath grouper",
            otherNames: ["Goliath", "Atlantic goliath grouper"],
            scientificName: "Epinephelus itajara",
            group: .bottomfish,
            summary: "The largest grouper in the Atlantic, able to top 300 kg, and found around wrecks, bridges, docks and mangroves. Harvest is closed in federal waters and limited to a few permit fish a year in Florida, so nearly all are released.",
            idTips: [
                "Rounded tail; gag and black grouper have squarer tails.",
                "Huge, broad, flat head with small eyes and a wide mouth.",
                "Small black spots on the head and fins, over faint dark bars."
            ],
            lookalikes: ["black_grouper", "gag_grouper"],
            traits: [.largeMouth, .spinyDorsal, .roundedTail, .darkSpotsLightBody, .darkMottling],
            sizeCutoffsCm: [90, 130, 170, 200],
            weightA: nil,
            weightB: nil,
            colorHex: 0x64502C,
            habitat: "Wrecks, ledges, bridges, docks and reefs; young fish live in mangrove creeks and estuaries.",
            range: "Both sides of the Atlantic; in the US mostly Florida, and less often along the Gulf coast and the Carolinas.",
            regions: [.florida]
        ),
        Species(
            id: "almaco_jack",
            commonName: "Almaco jack",
            otherNames: ["Almaco", "Longfin yellowtail"],
            scientificName: "Seriola rivoliana",
            group: .bottomfish,
            summary: "Deep-bodied amberjack of reefs, wrecks and oil rigs that fights hard and is good eating. Often mistaken for a small greater amberjack.",
            idTips: [
                "Tall, sickle-shaped second dorsal and anal fins; an amberjack's are low.",
                "Deeper, flatter body than a greater amberjack, often with a purple or olive cast.",
                "No tail scutes or gill cover spot, unlike a crevalle jack."
            ],
            lookalikes: ["greater_amberjack", "jack_crevalle"],
            traits: [.deepFlatBody, .spinyDorsal, .twoSeparateDorsals, .forkedTail],
            sizeCutoffsCm: [45, 60, 75, 90],
            weightA: nil,
            weightB: nil,
            colorHex: 0x886890,
            habitat: "Offshore reefs, wrecks, ledges and oil rigs, usually in mid water around the structure.",
            range: "Warm seas worldwide; in the US from the Carolinas to Florida and across the Gulf to Texas.",
            regions: [.southernPlains, .southeast, .florida]
        ),
    ]
}
