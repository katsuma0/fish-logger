import Foundation

// PLACEHOLDER: replaced by the full Canadian freshwater game fish list.
extension SpeciesCatalog {
    static let all: [Species] = [
        Species(
            id: "walleye",
            commonName: "Walleye",
            otherNames: ["Pickerel", "Yellow pickerel", "Doré jaune"],
            scientificName: "Sander vitreus",
            group: .perch,
            summary: "Canada's most popular table fish. Feeds hardest at dawn, dusk, and under cloud.",
            idTips: [
                "White patch on the bottom tip of the tail",
                "Big glassy eyes that shine in light",
                "Dark blotch at the back of the spiny dorsal fin"
            ],
            lookalikes: ["sauger"],
            traits: [.torpedoBody, .spinyDorsal, .twoSeparateDorsals, .glassyEye, .whiteTailTip, .goldenColor, .forkedTail],
            sizeCutoffsCm: [30, 40, 55, 70],
            weightA: -5.453,
            weightB: 3.180,
            colorHex: 0xB8860B,
            habitat: "Large lakes and rivers, near rocky points, weed edges, and drop-offs.",
            range: "Every province and territory except the island of Newfoundland and BC's coast."
        )
    ]
}
