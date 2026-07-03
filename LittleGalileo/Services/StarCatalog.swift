import Foundation

final class StarCatalog: ObservableObject {
    @Published private(set) var stars: [Star] = []
    @Published private(set) var asterismData = AsterismData(featured: [], all: [])

    private var starIndex: [Int: Star] = [:]

    init(bundle: Bundle? = nil) {
        let bundle = bundle ?? Bundle.littleGalileoResources
        loadStars(from: bundle)
        loadAsterisms(from: bundle)
    }

    func star(byHIP hip: Int) -> Star? {
        starIndex[hip]
    }

    func featuredAsterisms() -> [Asterism] {
        asterismData.featured
    }

    func allAsterisms() -> [Asterism] {
        asterismData.all
    }

    private func loadStars(from bundle: Bundle) {
        do {
            stars = try Self.decode([Star].self, fileName: "stars", in: bundle)
            starIndex = Dictionary(uniqueKeysWithValues: stars.map { ($0.hip, $0) })
            print("Loaded \(stars.count) stars")
        } catch {
            stars = []
            starIndex = [:]
            print("Failed to load stars.json: \(error)")
        }
    }

    private func loadAsterisms(from bundle: Bundle) {
        do {
            asterismData = try Self.decode(AsterismData.self, fileName: "asterisms", in: bundle)
            print("Loaded \(asterismData.featured.count) featured asterisms")
        } catch {
            asterismData = AsterismData(featured: [], all: [])
            print("Failed to load asterisms.json: \(error)")
        }
    }

    private static func decode<T: Decodable>(_ type: T.Type, fileName: String, in bundle: Bundle) throws -> T {
        guard let url = bundle.url(forResource: fileName, withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(type, from: data)
    }
}

private final class BundleToken {}

private extension Bundle {
    static var littleGalileoResources: Bundle {
        let candidates = [Bundle.main, Bundle(for: BundleToken.self)] + Bundle.allBundles
        return candidates.first { $0.url(forResource: "stars", withExtension: "json") != nil } ?? .main
    }
}
