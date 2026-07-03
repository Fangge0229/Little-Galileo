import CoreGraphics
import SwiftUI

struct SkyProjection {
    let centerAzimuth: Double
    let centerAltitude: Double
    let fieldOfView: Double
    let screenSize: CGSize

    func project(azimuth: Double, altitude: Double) -> CGPoint? {
        let center = vector(azimuth: centerAzimuth, altitude: centerAltitude)
        let target = vector(azimuth: azimuth, altitude: altitude)
        let dot = max(-1.0, min(1.0, center.x * target.x + center.y * target.y + center.z * target.z))
        let angularDistance = acos(dot)
        let maxAngle = AstroMath.degToRad(fieldOfView / 2.0)
        guard angularDistance <= maxAngle else { return nil }

        let centerAz = AstroMath.degToRad(centerAzimuth)
        let centerAlt = AstroMath.degToRad(centerAltitude)

        let east = (x: cos(centerAz), y: 0.0, z: -sin(centerAz))
        let north = (
            x: -sin(centerAlt) * sin(centerAz),
            y: cos(centerAlt),
            z: -sin(centerAlt) * cos(centerAz)
        )

        let x = target.x * east.x + target.y * east.y + target.z * east.z
        let y = target.x * north.x + target.y * north.y + target.z * north.z
        let scale = 2.0 / max(0.0001, 1.0 + dot)
        let projectedX = x * scale
        let projectedY = y * scale

        let radius = min(screenSize.width, screenSize.height) * 0.5
        let maxProjectedRadius = 2.0 * tan(maxAngle / 2.0)
        let pixelsPerUnit = radius / maxProjectedRadius

        return CGPoint(
            x: screenSize.width / 2.0 + projectedX * pixelsPerUnit,
            y: screenSize.height / 2.0 - projectedY * pixelsPerUnit
        )
    }

    func unproject(point: CGPoint) -> (azimuth: Double, altitude: Double)? {
        let radius = min(screenSize.width, screenSize.height) * 0.5
        guard radius > 0 else { return nil }

        let maxAngle = AstroMath.degToRad(fieldOfView / 2.0)
        let maxProjectedRadius = 2.0 * tan(maxAngle / 2.0)
        let pixelsPerUnit = radius / maxProjectedRadius
        let x = (point.x - screenSize.width / 2.0) / pixelsPerUnit
        let y = -(point.y - screenSize.height / 2.0) / pixelsPerUnit
        let rho = hypot(x, y)
        let angularDistance = 2.0 * atan(rho / 2.0)
        guard angularDistance <= maxAngle else { return nil }

        let center = vector(azimuth: centerAzimuth, altitude: centerAltitude)
        let centerAz = AstroMath.degToRad(centerAzimuth)
        let centerAlt = AstroMath.degToRad(centerAltitude)
        let east = (x: cos(centerAz), y: 0.0, z: -sin(centerAz))
        let north = (
            x: -sin(centerAlt) * sin(centerAz),
            y: cos(centerAlt),
            z: -sin(centerAlt) * cos(centerAz)
        )

        let sinC = sin(angularDistance)
        let cosC = cos(angularDistance)
        let factor = rho == 0 ? 0 : sinC / rho
        let target = (
            x: cosC * center.x + factor * (x * east.x + y * north.x),
            y: cosC * center.y + factor * (x * east.y + y * north.y),
            z: cosC * center.z + factor * (x * east.z + y * north.z)
        )

        let altitude = AstroMath.radToDeg(asin(target.y))
        let azimuth = AstroMath.radToDeg(atan2(target.x, target.z)).positiveDegrees
        return (azimuth, altitude)
    }

    private func vector(azimuth: Double, altitude: Double) -> (x: Double, y: Double, z: Double) {
        let az = AstroMath.degToRad(azimuth)
        let alt = AstroMath.degToRad(altitude)
        return (
            x: cos(alt) * sin(az),
            y: sin(alt),
            z: cos(alt) * cos(az)
        )
    }
}

func starRadius(magnitude: Double) -> CGFloat {
    let clamped = max(-1.5, min(5.5, magnitude))
    let normalized = (5.5 - clamped) / 7.0
    return CGFloat(0.5 + normalized * 3.5)
}

func starColor(colorIndex: Double?) -> Color {
    guard let colorIndex else { return Color(hex: "F0F0FF") }
    switch colorIndex {
    case ..<(-0.1):
        return Color(hex: "CAD7FF")
    case -0.1..<0.2:
        return Color(hex: "F0F0FF")
    case 0.2..<0.5:
        return Color(hex: "FFF8E0")
    case 0.5...1.0:
        return Color(hex: "FFE070")
    default:
        return Color(hex: "FFAA33")
    }
}

private extension Double {
    var positiveDegrees: Double {
        let value = truncatingRemainder(dividingBy: 360.0)
        return value >= 0 ? value : value + 360.0
    }
}
