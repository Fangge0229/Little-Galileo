import Foundation

struct Asterism: Codable, Identifiable {
    let id: String
    let name: String
    let pinyin: String
    let en: String
    let stars: [Int]
    let lines: [[Int]]
    let brief: String?
    let story: String?
    let science: String?
    let difficulty: Int?
    let best_season: String?
}

struct AsterismData: Codable {
    let featured: [Asterism]
    let all: [Asterism]
}
