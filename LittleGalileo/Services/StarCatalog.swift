import Foundation

final class StarCatalog: ObservableObject {
    @Published private(set) var stars: [Star] = []
    @Published private(set) var asterismData = AsterismData(featured: [], all: [])
    @Published private(set) var westernData = WesternConstellationData(constellations: [], starNames: [:])
    @Published private(set) var chineseData = ChineseAsterismData(asterisms: [], starNames: [:])

    private var starIndex: [Int: Star] = [:]
    private var modeStarHIPs: [ConstellationMode: Set<Int>] = [:]
    private var featuredAsterismByHIP: [Int: Asterism] = [:]
    private var chineseAsterismByHIP: [Int: Asterism] = [:]
    private var westernConstellationByHIP: [Int: WesternConstellation] = [:]
    private let renderMagnitudeLimit = 4.0
    private let brightMagnitudeLimit = 2.0

    init(bundle: Bundle? = nil) {
        let bundle = bundle ?? Bundle.littleGalileoResources
        loadWesternConstellations(from: bundle)
        loadAsterisms(from: bundle)
        loadStars(from: bundle)
        buildIndexes()
    }

    func star(byHIP hip: Int) -> Star? {
        starIndex[hip]
    }

    func featuredAsterisms() -> [Asterism] {
        Self.sortedFeatured(chineseData.asterisms.filter(\.isFeatured))
    }

    func allAsterisms() -> [Asterism] {
        chineseData.asterisms
    }

    func chineseAsterisms() -> [Asterism] {
        chineseData.asterisms
    }

    func westernConstellations() -> [WesternConstellation] {
        westernData.constellations
    }

    func displayStars(for mode: ConstellationMode) -> [Star] {
        let featuredHIPs = mode == .chinese ? Set(featuredAsterisms().flatMap(\.stars)) : []
        let modeHIPs = modeStarHIPs[mode, default: []]
        return stars.filter { star in
            let isModeStar = modeHIPs.contains(star.hip)
            let isBright = star.mag <= brightMagnitudeLimit
            let shouldRenderModeStar = isModeStar && star.mag <= renderMagnitudeLimit
            return shouldRenderModeStar || isBright || featuredHIPs.contains(star.hip)
        }
    }

    func lineReferenceStars(for mode: ConstellationMode) -> [Star] {
        let modeHIPs = modeStarHIPs[mode, default: []]
        return stars.filter { modeHIPs.contains($0.hip) || $0.mag <= brightMagnitudeLimit }
    }

    func starName(hip: Int, mode: ConstellationMode) -> String? {
        let hipKey = String(hip)
        return chineseData.starNames[hipKey]?.name
            ?? starIndex[hip]?.chineseName
            ?? westernData.starNames[hipKey]
            ?? starIndex[hip]?.name
    }

    func featuredAsterism(containing hip: Int) -> Asterism? {
        featuredAsterismByHIP[hip]
    }

    func chineseAsterism(containing hip: Int) -> Asterism? {
        featuredAsterismByHIP[hip] ?? chineseAsterismByHIP[hip]
    }

    func westernConstellation(containing hip: Int) -> WesternConstellation? {
        westernConstellationByHIP[hip]
    }

    func constellationName(containing hip: Int, mode: ConstellationMode) -> String? {
        switch mode {
        case .chinese:
            return chineseAsterism(containing: hip)?.name
        case .western:
            return westernConstellation(containing: hip)?.name
        }
    }

    private func loadStars(from bundle: Bundle) {
        do {
            stars = try Self.decode([Star].self, fileName: "stars_filtered", in: bundle)
            injectChineseNames()
            starIndex = Dictionary(uniqueKeysWithValues: stars.map { ($0.hip, $0) })
            print("Loaded \(stars.count) filtered stars")
        } catch {
            loadLegacyStars(from: bundle, originalError: error)
        }
    }

    private func loadAsterisms(from bundle: Bundle) {
        do {
            chineseData = try Self.decode(ChineseAsterismData.self, fileName: "chinese_asterisms", in: bundle)
            asterismData = AsterismData(
                featured: Self.sortedFeatured(chineseData.asterisms.filter(\.isFeatured)),
                all: chineseData.asterisms.filter { !$0.isFeatured }
            )
            print("Loaded \(chineseData.asterisms.count) Chinese asterisms")
        } catch {
            loadLegacyAsterisms(from: bundle, originalError: error)
        }
    }

    private func loadWesternConstellations(from bundle: Bundle) {
        do {
            westernData = try Self.decode(WesternConstellationData.self, fileName: "western_constellations", in: bundle)
            print("Loaded \(westernData.constellations.count) western constellations")
        } catch {
            westernData = WesternConstellationData(constellations: [], starNames: [:])
            print("Failed to load western_constellations.json: \(error)")
        }
    }

    private func loadLegacyStars(from bundle: Bundle, originalError: Error) {
        do {
            stars = try Self.decode([Star].self, fileName: "stars", in: bundle)
            injectChineseNames()
            starIndex = Dictionary(uniqueKeysWithValues: stars.map { ($0.hip, $0) })
            print("Loaded \(stars.count) legacy stars after filtered load failed: \(originalError)")
        } catch {
            stars = []
            starIndex = [:]
            print("Failed to load stars_filtered.json: \(originalError)")
            print("Failed to load stars.json: \(error)")
        }
    }

    private func loadLegacyAsterisms(from bundle: Bundle, originalError: Error) {
        do {
            asterismData = try Self.decode(AsterismData.self, fileName: "asterisms", in: bundle)
            let merged = asterismData.featured.map { legacyFeatured($0) } + asterismData.all
            chineseData = ChineseAsterismData(asterisms: merged, starNames: [:])
            print("Loaded \(asterismData.featured.count) legacy featured asterisms after Chinese data load failed: \(originalError)")
        } catch {
            asterismData = AsterismData(featured: [], all: [])
            chineseData = ChineseAsterismData(asterisms: [], starNames: [:])
            print("Failed to load chinese_asterisms.json: \(originalError)")
            print("Failed to load asterisms.json: \(error)")
        }
    }

    private func legacyFeatured(_ asterism: Asterism) -> Asterism {
        Asterism(
            id: asterism.id,
            name: asterism.name,
            pinyin: asterism.pinyin,
            en: asterism.en,
            stars: asterism.stars,
            lines: asterism.lines,
            featured: true,
            rank: asterism.rank,
            brief: asterism.brief,
            story: asterism.story,
            science: asterism.science,
            difficulty: asterism.difficulty,
            best_season: asterism.best_season,
            storyType: asterism.storyType,
            sourceNotes: asterism.sourceNotes,
            childTitle: asterism.childTitle,
            symbol: asterism.symbol,
            iconName: asterism.iconName,
            category: asterism.category,
            lore: asterism.lore
        )
    }

    private func injectChineseNames() {
        for index in stars.indices {
            let hip = stars[index].hip
            stars[index].chineseName = chineseData.starNames[String(hip)]?.name
        }
    }

    private func buildIndexes() {
        modeStarHIPs[.chinese] = Set(chineseData.asterisms.flatMap(\.stars))
        modeStarHIPs[.western] = Set(westernData.constellations.flatMap(\.stars))

        featuredAsterismByHIP = [:]
        chineseAsterismByHIP = [:]
        for asterism in chineseData.asterisms {
            for hip in asterism.stars {
                if asterism.isFeatured {
                    featuredAsterismByHIP[hip] = asterism
                }
                chineseAsterismByHIP[hip] = asterism
            }
        }

        westernConstellationByHIP = [:]
        for constellation in westernData.constellations {
            for hip in constellation.stars {
                westernConstellationByHIP[hip] = constellation
            }
        }

        print("Catalog indexed: \(displayStars(for: .chinese).count) Chinese display stars, \(displayStars(for: .western).count) western display stars")
    }

    private static func decode<T: Decodable>(_ type: T.Type, fileName: String, in bundle: Bundle) throws -> T {
        guard let url = bundle.url(forResource: fileName, withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(type, from: data)
    }

    private static func sortedFeatured(_ asterisms: [Asterism]) -> [Asterism] {
        asterisms.sorted { lhs, rhs in
            featuredSortKey(lhs) < featuredSortKey(rhs)
        }
    }

    private static func featuredSortKey(_ asterism: Asterism) -> String {
        asterism.iconName ?? "zz_\(asterism.name)"
    }
}

private final class BundleToken {}

private extension Bundle {
    static var littleGalileoResources: Bundle {
        let candidates = [Bundle.main, Bundle(for: BundleToken.self)] + Bundle.allBundles
        return candidates.first {
            $0.url(forResource: "stars_filtered", withExtension: "json") != nil
                || $0.url(forResource: "stars", withExtension: "json") != nil
        } ?? .main
    }
}
