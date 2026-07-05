import Foundation

struct Asterism: Codable, Identifiable {
    let id: String
    let name: String
    let pinyin: String
    let en: String
    let stars: [Int]
    let lines: [[Int]]
    let featured: Bool?
    let rank: Int?
    let brief: String?
    let story: String?
    let science: String?
    let difficulty: Int?
    let best_season: String?

    var isFeatured: Bool { featured ?? false }
    var hasStory: Bool { story?.isEmpty == false }
}

struct AsterismData: Codable {
    let featured: [Asterism]
    let all: [Asterism]
}

struct ChineseAsterismData: Codable {
    let asterisms: [Asterism]
    let starNames: [String: StarNameInfo]
}

struct StarNameInfo: Codable {
    let name: String
    let pinyin: String?
}
