import SwiftUI

struct SkyMapView: View {
    @EnvironmentObject private var catalog: StarCatalog
    @EnvironmentObject private var location: LocationManager
    @EnvironmentObject private var collection: CollectionStore

    @State private var centerAzimuth: Double = 0
    @State private var centerAltitude: Double = 45
    @State private var fieldOfView: Double = 90
    @State private var selectedAsterism: Asterism?
    @State private var dragStartAzimuth: Double = 0
    @State private var dragStartAltitude: Double = 45
    @State private var pinchStartFOV: Double = 90

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 60)) { timeline in
                GeometryReader { geometry in
                    ZStack(alignment: .bottom) {
                        skyCanvas(size: geometry.size, date: timeline.date)
                            .ignoresSafeArea()
                            .gesture(dragGesture)
                            .simultaneousGesture(magnificationGesture)
                            .onTapGesture { point in
                                selectNearestAsterism(at: point, size: geometry.size, date: timeline.date)
                            }

                        directionOverlay
                            .allowsHitTesting(false)

                        if let selectedAsterism {
                            StarInfoPopup(asterism: selectedAsterism) {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    self.selectedAsterism = nil
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("星图")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: "0A0E27"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                location.requestLocation()
            }
        }
    }

    private func skyCanvas(size: CGSize, date: Date) -> some View {
        let projection = SkyProjection(
            centerAzimuth: centerAzimuth,
            centerAltitude: centerAltitude,
            fieldOfView: fieldOfView,
            screenSize: size
        )
        let positions = AstroMath.calculateVisibleStars(
            stars: catalog.stars,
            latitude: location.latitude,
            longitude: location.longitude,
            date: date,
            minAltitude: -5
        )
        let positionByHIP = Dictionary(uniqueKeysWithValues: positions.map { ($0.star.hip, $0) })

        return Canvas { context, canvasSize in
            drawBackground(in: context, size: canvasSize)
            drawHorizon(in: context, projection: projection, size: canvasSize)
            drawAsterismLines(in: context, projection: projection, positionByHIP: positionByHIP)
            drawStars(in: context, projection: projection, positions: positions)
            drawAsterismLabels(in: context, projection: projection, positionByHIP: positionByHIP)
        }
        .background(Color(hex: "0A0E27"))
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if value.translation == .zero {
                    dragStartAzimuth = centerAzimuth
                    dragStartAltitude = centerAltitude
                }
                centerAzimuth = (dragStartAzimuth - value.translation.width * 0.25).normalizedDegrees
                centerAltitude = min(90, max(-10, dragStartAltitude + value.translation.height * 0.18))
            }
            .onEnded { _ in
                dragStartAzimuth = centerAzimuth
                dragStartAltitude = centerAltitude
            }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                fieldOfView = min(120, max(30, pinchStartFOV / Double(value)))
            }
            .onEnded { _ in
                pinchStartFOV = fieldOfView
            }
    }

    private var directionOverlay: some View {
        VStack {
            HStack {
                directionChip("N")
                Spacer()
                directionChip("\(Int(centerAzimuth.rounded()))°")
                Spacer()
                directionChip("S")
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            Spacer()
            HStack {
                directionChip("E")
                Spacer()
                directionChip("W")
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 120)
        }
    }

    private func directionChip(_ text: String) -> some View {
        Text(text)
            .font(.caption.bold())
            .foregroundStyle(Color.white.opacity(0.76))
            .frame(minWidth: 34, minHeight: 28)
            .background(Color.black.opacity(0.18))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func drawBackground(in context: GraphicsContext, size: CGSize) {
        let rect = CGRect(origin: .zero, size: size)
        let gradient = Gradient(colors: [Color(hex: "0A0E27"), Color(hex: "11183A"), Color.black])
        context.fill(Path(rect), with: .radialGradient(gradient, center: CGPoint(x: size.width / 2, y: size.height / 2), startRadius: 10, endRadius: max(size.width, size.height)))
    }

    private func drawHorizon(in context: GraphicsContext, projection: SkyProjection, size: CGSize) {
        var path = Path()
        var started = false
        for azimuth in stride(from: 0.0, through: 360.0, by: 3.0) {
            guard let point = projection.project(azimuth: azimuth, altitude: 0) else {
                started = false
                continue
            }
            if started {
                path.addLine(to: point)
            } else {
                path.move(to: point)
                started = true
            }
        }
        context.stroke(path, with: .color(Color.white.opacity(0.18)), lineWidth: 1)
    }

    private func drawStars(in context: GraphicsContext, projection: SkyProjection, positions: [StarPosition]) {
        for position in positions {
            guard let point = projection.project(azimuth: position.azimuth, altitude: position.altitude) else { continue }
            let radius = starRadius(magnitude: position.star.mag)
            let rect = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
            context.fill(Path(ellipseIn: rect), with: .color(starColor(colorIndex: position.star.ci)))
        }
    }

    private func drawAsterismLines(
        in context: GraphicsContext,
        projection: SkyProjection,
        positionByHIP: [Int: StarPosition]
    ) {
        for asterism in catalog.allAsterisms() {
            drawLines(asterism.lines, in: context, projection: projection, positionByHIP: positionByHIP, color: Color(hex: "2A3A5C").opacity(0.4), width: 0.8)
        }
        for asterism in catalog.featuredAsterisms() {
            drawLines(asterism.lines, in: context, projection: projection, positionByHIP: positionByHIP, color: Color(hex: "4A90D9").opacity(0.7), width: 1.5)
        }
    }

    private func drawLines(
        _ lines: [[Int]],
        in context: GraphicsContext,
        projection: SkyProjection,
        positionByHIP: [Int: StarPosition],
        color: Color,
        width: CGFloat
    ) {
        for line in lines where line.count >= 2 {
            guard let first = positionByHIP[line[0]],
                  let second = positionByHIP[line[1]],
                  let start = projection.project(azimuth: first.azimuth, altitude: first.altitude),
                  let end = projection.project(azimuth: second.azimuth, altitude: second.altitude) else {
                continue
            }
            var path = Path()
            path.move(to: start)
            path.addLine(to: end)
            context.stroke(path, with: .color(color), lineWidth: width)
        }
    }

    private func drawAsterismLabels(
        in context: GraphicsContext,
        projection: SkyProjection,
        positionByHIP: [Int: StarPosition]
    ) {
        for asterism in catalog.featuredAsterisms() {
            let points = asterism.stars.compactMap { hip -> CGPoint? in
                guard let position = positionByHIP[hip] else { return nil }
                return projection.project(azimuth: position.azimuth, altitude: position.altitude)
            }
            guard !points.isEmpty else { continue }
            let center = CGPoint(
                x: points.map(\.x).reduce(0, +) / CGFloat(points.count),
                y: points.map(\.y).reduce(0, +) / CGFloat(points.count)
            )
            let text = Text(asterism.name)
                .font(.caption.bold())
                .foregroundColor(Color(hex: "FFD700"))
            context.draw(text, at: center)
        }
    }

    private func selectNearestAsterism(at point: CGPoint, size: CGSize, date: Date) {
        let projection = SkyProjection(centerAzimuth: centerAzimuth, centerAltitude: centerAltitude, fieldOfView: fieldOfView, screenSize: size)
        let positions = AstroMath.calculateVisibleStars(stars: catalog.stars, latitude: location.latitude, longitude: location.longitude, date: date, minAltitude: -5)
        let positionByHIP = Dictionary(uniqueKeysWithValues: positions.map { ($0.star.hip, $0) })

        var closest: (asterism: Asterism, distance: CGFloat)?
        for asterism in catalog.featuredAsterisms() {
            for hip in asterism.stars {
                guard let position = positionByHIP[hip],
                      let projected = projection.project(azimuth: position.azimuth, altitude: position.altitude) else { continue }
                let distance = hypot(projected.x - point.x, projected.y - point.y)
                if distance < 32, closest == nil || distance < closest!.distance {
                    closest = (asterism, distance)
                }
            }
        }

        if let closest {
            collection.markViewed(closest.asterism.id)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                selectedAsterism = closest.asterism
            }
        }
    }
}

private extension Double {
    var normalizedDegrees: Double {
        let value = truncatingRemainder(dividingBy: 360.0)
        return value >= 0 ? value : value + 360.0
    }
}
