import Foundation

enum AstroMath {
    static func degToRad(_ degrees: Double) -> Double {
        degrees * .pi / 180.0
    }

    static func radToDeg(_ radians: Double) -> Double {
        radians * 180.0 / .pi
    }

    static func julianDay(from date: Date) -> Double {
        2_440_587.5 + date.timeIntervalSince1970 / 86_400.0
    }

    static func greenwichMeanSiderealTime(jd: Double) -> Double {
        let t = (jd - 2_451_545.0) / 36_525.0
        let degrees = 280.46061837
            + 360.98564736629 * (jd - 2_451_545.0)
            + 0.000387933 * t * t
            - t * t * t / 38_710_000.0
        return normalizeDegrees(degrees) / 15.0
    }

    static func horizontalCoordinates(
        ra: Double,
        dec: Double,
        latitude: Double,
        longitude: Double,
        date: Date
    ) -> (azimuth: Double, altitude: Double) {
        let jd = julianDay(from: date)
        let gmst = greenwichMeanSiderealTime(jd: jd)
        let lst = normalizeHours(gmst + longitude / 15.0)
        let hourAngle = normalizeDegreesToSigned((lst - ra) * 15.0)

        let haRad = degToRad(hourAngle)
        let decRad = degToRad(dec)
        let latRad = degToRad(latitude)

        let altitudeRad = asin(
            sin(latRad) * sin(decRad)
            + cos(latRad) * cos(decRad) * cos(haRad)
        )

        let azimuthRad = atan2(
            -sin(haRad) * cos(decRad),
            cos(latRad) * sin(decRad) - sin(latRad) * cos(decRad) * cos(haRad)
        )

        return (
            azimuth: normalizeDegrees(radToDeg(azimuthRad)),
            altitude: radToDeg(altitudeRad)
        )
    }

    static func calculateVisibleStars(
        stars: [Star],
        latitude: Double,
        longitude: Double,
        date: Date,
        minAltitude: Double = 0
    ) -> [StarPosition] {
        stars.compactMap { star in
            let coordinates = horizontalCoordinates(
                ra: star.ra,
                dec: star.dec,
                latitude: latitude,
                longitude: longitude,
                date: date
            )
            guard coordinates.altitude >= minAltitude else { return nil }
            return StarPosition(star: star, azimuth: coordinates.azimuth, altitude: coordinates.altitude)
        }
    }

    private static func normalizeHours(_ hours: Double) -> Double {
        let value = hours.truncatingRemainder(dividingBy: 24.0)
        return value >= 0 ? value : value + 24.0
    }

    private static func normalizeDegrees(_ degrees: Double) -> Double {
        let value = degrees.truncatingRemainder(dividingBy: 360.0)
        return value >= 0 ? value : value + 360.0
    }

    private static func normalizeDegreesToSigned(_ degrees: Double) -> Double {
        var value = normalizeDegrees(degrees)
        if value > 180.0 {
            value -= 360.0
        }
        return value
    }
}
