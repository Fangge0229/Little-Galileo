import Foundation

enum ConstellationMode: String, CaseIterable, Identifiable {
    case chinese
    case western

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .chinese:
            return "星宿"
        case .western:
            return "星座"
        }
    }

    var description: String {
        switch self {
        case .chinese:
            return "中国传统星宿"
        case .western:
            return "西方星座"
        }
    }
}
