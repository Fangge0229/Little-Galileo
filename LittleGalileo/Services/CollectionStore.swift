import Foundation

final class CollectionStore: ObservableObject {
    @Published private(set) var viewedAsterisms: Set<String> = []

    private let defaults: UserDefaults
    private let key = "viewedAsterisms"
    private var featuredTotal = 38

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func markViewed(_ asterismId: String) {
        guard !asterismId.isEmpty else { return }
        viewedAsterisms.insert(asterismId)
        save()
    }

    func isViewed(_ asterismId: String) -> Bool {
        viewedAsterisms.contains(asterismId)
    }

    func viewedCount() -> Int {
        viewedAsterisms.count
    }

    func setFeaturedTotal(_ total: Int) {
        featuredTotal = max(0, total)
    }

    func totalFeatured() -> Int {
        featuredTotal
    }

    func progress() -> Double {
        guard totalFeatured() > 0 else { return 0 }
        return Double(viewedCount()) / Double(totalFeatured())
    }

    private func load() {
        guard let data = defaults.data(forKey: key),
              let values = try? JSONDecoder().decode([String].self, from: data) else {
            viewedAsterisms = []
            return
        }
        viewedAsterisms = Set(values)
    }

    private func save() {
        let values = Array(viewedAsterisms).sorted()
        if let data = try? JSONEncoder().encode(values) {
            defaults.set(data, forKey: key)
        }
    }
}
