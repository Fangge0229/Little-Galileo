import Foundation

struct Star: Codable, Identifiable {
    let hip: Int
    let ra: Double
    let dec: Double
    let mag: Double
    let ci: Double?
    let name: String?

    var id: Int { hip }
}

struct StarPosition: Identifiable {
    let star: Star
    let azimuth: Double
    let altitude: Double

    var id: Int { star.hip }
    var isVisible: Bool { altitude > 0 }
}
