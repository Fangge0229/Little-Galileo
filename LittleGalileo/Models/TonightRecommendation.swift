import Foundation

struct TonightRecommendation: Identifiable {
    let asterism: Asterism
    let azimuth: Double
    let altitude: Double

    var id: String { asterism.id }
}

extension StarCatalog {
    func tonightRecommendations(
        latitude: Double,
        longitude: Double,
        date: Date,
        visibleAltitude: Double = 15,
        limit: Int = 5
    ) -> [TonightRecommendation] {
        let items = featuredAsterisms().compactMap { asterism -> TonightRecommendation? in
            guard let hip = asterism.stars.first,
                  let star = star(byHIP: hip) else { return nil }

            let position = AstroMath.horizontalCoordinates(
                ra: star.ra,
                dec: star.dec,
                latitude: latitude,
                longitude: longitude,
                date: date
            )

            return TonightRecommendation(
                asterism: asterism,
                azimuth: position.azimuth,
                altitude: position.altitude
            )
        }

        let visible = items.filter { $0.altitude > visibleAltitude }
            .sorted { $0.altitude > $1.altitude }

        return visible.isEmpty
            ? items.sorted { $0.altitude > $1.altitude }
            : Array(visible.prefix(limit))
    }
}
