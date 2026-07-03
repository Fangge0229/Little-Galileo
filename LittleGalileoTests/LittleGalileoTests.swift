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

        #expect(catalog.featuredAsterisms().count == 8)
        #expect(catalog.featuredAsterisms().allSatisfy { $0.story?.isEmpty == false })
        #expect(catalog.star(byHIP: 11767) != nil)
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
