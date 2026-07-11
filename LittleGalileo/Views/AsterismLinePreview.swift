import SwiftUI

struct AsterismLinePreview: View {
    let asterism: Asterism
    var compact: Bool

    @EnvironmentObject private var catalog: StarCatalog

    init(asterism: Asterism, compact: Bool = false) {
        self.asterism = asterism
        self.compact = compact
    }

    private var lineColor: Color {
        compact
            ? Color(hex: "4AC6D9").opacity(0.78)
            : Color(hex: "4A90D9").opacity(0.82)
    }

    private var starColor: Color {
        compact
            ? Color(hex: "FFF8E7").opacity(0.92)
            : Color(hex: "FFD700").opacity(0.95)
    }

    private var background: Color {
        compact
            ? Color.white.opacity(0.08)
            : Color.black.opacity(0.18)
    }

    var body: some View {
        let unitPoints = Self.previewUnitPoints(for: asterism, catalog: catalog)

        ZStack {
            if unitPoints.isEmpty {
                fallbackIcon
            } else {
                Canvas { context, size in
                    let inset: CGFloat = compact ? 4 : 8
                    let drawSize = CGSize(
                        width: max(1, size.width - inset * 2),
                        height: max(1, size.height - inset * 2)
                    )

                    func point(for hip: Int) -> CGPoint? {
                        guard let unit = unitPoints[hip] else { return nil }
                        return CGPoint(
                            x: inset + unit.x * drawSize.width,
                            y: inset + unit.y * drawSize.height
                        )
                    }

                    for line in asterism.lines where line.count >= 2 {
                        guard let start = point(for: line[0]),
                              let end = point(for: line[1]) else { continue }
                        var path = Path()
                        path.move(to: start)
                        path.addLine(to: end)
                        context.stroke(path, with: .color(lineColor), lineWidth: compact ? 0.8 : 1.2)
                    }

                    for hip in asterism.stars {
                        guard let center = point(for: hip) else { continue }
                        drawStar(at: center, in: context, singlePoint: unitPoints.count <= 1)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: compact ? 6 : 8))
    }

    @ViewBuilder
    private var fallbackIcon: some View {
        if let iconName = asterism.iconName {
            Image(iconName)
                .resizable()
                .scaledToFit()
                .padding(compact ? 10 : 16)
                .opacity(0.82)
        } else {
            Image(systemName: "star.fill")
                .font(.system(size: compact ? 22 : 34, weight: .semibold))
                .foregroundStyle(starColor)
        }
    }

    private func drawStar(at center: CGPoint, in context: GraphicsContext, singlePoint: Bool) {
        if singlePoint {
            for radius in stride(from: 12.0, through: 2.0, by: -2.0) {
                let glowRect = CGRect(
                    x: center.x - radius,
                    y: center.y - radius,
                    width: radius * 2,
                    height: radius * 2
                )
                context.fill(
                    Path(ellipseIn: glowRect),
                    with: .color(starColor.opacity(Double(2.0 / radius) * 0.3))
                )
            }
        }

        let radius: CGFloat = singlePoint
            ? (compact ? 3.0 : 4.5)
            : (compact ? 1.5 : 2.3)
        let rect = CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        )
        context.fill(Path(ellipseIn: rect), with: .color(starColor))
    }

    nonisolated static func previewUnitPoints(for asterism: Asterism, catalog: StarCatalog) -> [Int: CGPoint] {
        let stars = asterism.stars.compactMap { catalog.star(byHIP: $0) }
        guard !stars.isEmpty else { return [:] }
        if stars.count == 1, let star = stars.first {
            return [star.hip: CGPoint(x: 0.5, y: 0.5)]
        }

        let rawRAs = stars.map(\.ra)
        let minRawRA = rawRAs.min() ?? 0
        let maxRawRA = rawRAs.max() ?? 0
        let wrapsRA = maxRawRA - minRawRA > 12

        let adjusted = stars.map { star -> (hip: Int, ra: Double, dec: Double) in
            let ra = wrapsRA && star.ra < 12 ? star.ra + 24 : star.ra
            return (star.hip, ra, star.dec)
        }

        let minRA = adjusted.map(\.ra).min() ?? 0
        let maxRA = adjusted.map(\.ra).max() ?? 0
        let minDec = adjusted.map(\.dec).min() ?? 0
        let maxDec = adjusted.map(\.dec).max() ?? 0
        let raRange = max(maxRA - minRA, 0.0001)
        let decRange = max(maxDec - minDec, 0.0001)

        return Dictionary(uniqueKeysWithValues: adjusted.map { star in
            let x = CGFloat((star.ra - minRA) / raRange)
            let y = CGFloat(1 - ((star.dec - minDec) / decRange))
            return (star.hip, CGPoint(x: x, y: y))
        })
    }
}
