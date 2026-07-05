//
//  LittleGalileoTests.swift
//  LittleGalileoTests
//
//  Created by 钱前 on 2026/7/4.
//

import Testing
import Foundation
@testable import LittleGalileo

struct LittleGalileoTests {

    @Test func polarisAltitudeMatchesObserverLatitude() async throws {
        let date = Date(timeIntervalSince1970: 1_704_067_200)

        let position = AstroMath.horizontalCoordinates(
            ra: 2.5303,
            dec: 89.2641,
            latitude: 30.25,
            longitude: 120.17,
            date: date
        )

        #expect(abs(position.altitude - 30.25) < 1.0)
        #expect(position.azimuth < 5.0 || position.azimuth > 355.0)
    }

    @Test func equatorialStarAtMeridianUsesLatitudeComplementAltitude() async throws {
        let latitude = 30.0
        let longitude = 0.0
        let date = Date(timeIntervalSince1970: 1_704_067_200)
        let jd = AstroMath.julianDay(from: date)
        let raOnMeridian = AstroMath.greenwichMeanSiderealTime(jd: jd) + longitude / 15.0

        let position = AstroMath.horizontalCoordinates(
            ra: raOnMeridian,
            dec: 0.0,
            latitude: latitude,
            longitude: longitude,
            date: date
        )

        #expect(abs(position.altitude - 60.0) < 0.001)
        #expect(abs(position.azimuth - 180.0) < 0.001)
    }

    @Test func skyProjectionProjectsCenterToScreenCenter() async throws {
        let projection = SkyProjection(
            centerAzimuth: 180,
            centerAltitude: 45,
            fieldOfView: 90,
            screenSize: CGSize(width: 300, height: 600)
        )

        let point = try #require(projection.project(azimuth: 180, altitude: 45))

        #expect(abs(point.x - 150) < 0.001)
        #expect(abs(point.y - 300) < 0.001)
    }

    @Test func bundledAsterismDataDecodesFeaturedStories() async throws {
        let catalog = StarCatalog()

        #expect(catalog.featuredAsterisms().count >= 8)
        #expect(catalog.featuredAsterisms().filter { $0.story?.isEmpty == false }.count >= 8)
        #expect(catalog.star(byHIP: 11767) != nil)
    }

    @Test func catalogLoadsDualModeSkyDataAndStarNames() async throws {
        let catalog = StarCatalog()

        #expect(catalog.stars.count < 2_848)
        #expect(catalog.westernConstellations().count >= 88)
        #expect(catalog.chineseAsterisms().count >= 280)
        #expect(catalog.displayStars(for: .chinese).count > 80)
        #expect(catalog.displayStars(for: .chinese).count < 700)
        #expect(catalog.displayStars(for: .western).count > 80)
        #expect(catalog.displayStars(for: .western).count < 700)
        #expect(catalog.starName(hip: 91262, mode: .chinese) != nil)
        #expect(catalog.starName(hip: 91262, mode: .western) != nil)
        #expect(catalog.displayStars(for: .chinese).contains { $0.hip == 11767 })
    }

    @Test func displayedStarsUseChineseNamesInBothSkyModes() async throws {
        let catalog = StarCatalog()

        #expect(catalog.starName(hip: 71860, mode: .western) == "骑官十")

        for mode in ConstellationMode.allCases {
            let missingChineseNames = catalog.displayStars(for: mode).filter { star in
                guard let name = catalog.starName(hip: star.hip, mode: mode) else { return true }
                return !name.containsChineseCharacter
            }

            #expect(missingChineseNames.isEmpty)
        }
    }

    @Test func collectionStorePersistsViewedAsterisms() async throws {
        let suiteName = "LittleGalileoTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = CollectionStore(defaults: defaults)
        store.markViewed("beidou")

        let reloaded = CollectionStore(defaults: defaults)
        #expect(reloaded.isViewed("beidou"))
        #expect(reloaded.viewedCount() == 1)
        #expect(reloaded.totalFeatured() == 8)
    }

}

private extension String {
    var containsChineseCharacter: Bool {
        unicodeScalars.contains { scalar in
            scalar.value >= 0x4E00 && scalar.value <= 0x9FFF
        }
    }
}
