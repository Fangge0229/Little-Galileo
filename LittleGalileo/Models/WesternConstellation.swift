import Foundation

struct WesternConstellation: Codable, Identifiable {
    let id: String
    let name: String
    let en: String
    let stars: [Int]
    let lines: [[Int]]
    let rank: Int?
}

struct WesternConstellationData: Codable {
    let constellations: [WesternConstellation]
    let starNames: [String: String]
}
