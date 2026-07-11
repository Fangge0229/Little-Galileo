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
    let storyType: String?
    let sourceNotes: String?
    let childTitle: String?
    let symbol: String?
    let iconName: String?
    let category: String?
    let lore: String?

    var isFeatured: Bool { featured ?? false }
    var hasStory: Bool { story?.isEmpty == false }
    var displayTitle: String { childTitle ?? name }

    var categoryLabel: String {
        switch category {
        case "starter": return "新手核心"
        case "ershiba": return "二十八宿"
        case "artifact": return "器物建筑"
        case "mythical": return "神兽人物"
        default: return "其他"
        }
    }
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
