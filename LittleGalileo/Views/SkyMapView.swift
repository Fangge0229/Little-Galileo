import SwiftUI

struct SkyMapView: View {
    @EnvironmentObject private var catalog: StarCatalog
    @EnvironmentObject private var location: LocationManager
    @EnvironmentObject private var collection: CollectionStore

    @State private var centerAzimuth: Double = 0
    @State private var centerAltitude: Double = 45
    @State private var fieldOfView: Double = 90
    @State private var constellationMode: ConstellationMode = .chinese
    @State private var selectedAsterism: Asterism?
    @State private var selectedWesternConstellation: WesternConstellation?
    @State private var tappedStarInfo: TappedStarInfo?
    @State private var dragStartAzimuth: Double = 0
    @State private var dragStartAltitude: Double = 45
    @State private var pinchStartFOV: Double = 90

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 60)) { timeline in
                GeometryReader { geometry in
                    ZStack(alignment: .bottom) {
                        Color(hex: "0A0E27")
                            .ignoresSafeArea()

                        skyCanvas(size: geometry.size, date: timeline.date)
                            .contentShape(Rectangle())
                            .gesture(dragGesture)
                            .simultaneousGesture(magnificationGesture)
                            .onTapGesture { point in
                                handleTap(at: point, size: geometry.size, date: timeline.date)
                            }

                        directionOverlay
                            .allowsHitTesting(false)

                        modeOverlay

                        if let tappedStarInfo {
                            StarTooltip(
                                starName: tappedStarInfo.starName,
                                constellation: tappedStarInfo.constellationName ?? constellationMode.description
                            )
                            .position(tooltipPosition(for: tappedStarInfo, in: geometry.size))
                            .transition(.scale(scale: 0.92).combined(with: .opacity))
                        }

                        if let selectedAsterism {
                            StarInfoPopup(
                                asterism: selectedAsterism,
                                mode: constellationMode,
                                westernConstellation: selectedWesternConstellation
                            ) {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    self.selectedAsterism = nil
                                    self.selectedWesternConstellation = nil
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("小小星官 · 星图")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: "0A0E27"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                location.requestLocation()
            }
            .onChange(of: constellationMode) { _ in
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedAsterism = nil
                    selectedWesternConstellation = nil
                    tappedStarInfo = nil
                }
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
        let referencePositions = AstroMath.calculateVisibleStars(
            stars: catalog.lineReferenceStars(for: constellationMode),
            latitude: location.latitude,
            longitude: location.longitude,
            date: date,
            minAltitude: -5
        )
        let displayHIPs = Set(catalog.displayStars(for: constellationMode).map(\.hip))
        let displayPositions = referencePositions.filter { displayHIPs.contains($0.star.hip) }
        let positionByHIP = Dictionary(uniqueKeysWithValues: referencePositions.map { ($0.star.hip, $0) })

        return Canvas { context, canvasSize in
            drawBackground(in: context, size: canvasSize)
            drawHorizon(in: context, projection: projection, size: canvasSize)
            drawConstellationLines(in: context, projection: projection, positionByHIP: positionByHIP)
            drawStars(in: context, projection: projection, positions: displayPositions)
            drawConstellationLabels(in: context, projection: projection, positionByHIP: positionByHIP)
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

    private var modeOverlay: some View {
        VStack {
            Picker("模式", selection: $constellationMode) {
                ForEach(ConstellationMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 176)
            .padding(8)
            .background(.ultraThinMaterial)
            .background(Color(hex: "11183A").opacity(0.62))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.top, 52)
            Spacer()
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

    private func drawConstellationLines(
        in context: GraphicsContext,
        projection: SkyProjection,
        positionByHIP: [Int: StarPosition]
    ) {
        switch constellationMode {
        case .chinese:
            for asterism in catalog.chineseAsterisms() where !asterism.isFeatured {
                drawLines(asterism.lines, in: context, projection: projection, positionByHIP: positionByHIP, color: Color(hex: "2A3A5C").opacity(0.42), width: 0.8)
            }
            for asterism in catalog.featuredAsterisms() {
                drawLines(asterism.lines, in: context, projection: projection, positionByHIP: positionByHIP, color: Color(hex: "4A90D9").opacity(0.78), width: 1.5)
            }
        case .western:
            for constellation in catalog.westernConstellations() {
                drawLines(constellation.lines, in: context, projection: projection, positionByHIP: positionByHIP, color: Color(hex: "4AC6D9").opacity(0.7), width: 1.2)
            }
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

    private func drawConstellationLabels(
        in context: GraphicsContext,
        projection: SkyProjection,
        positionByHIP: [Int: StarPosition]
    ) {
        var occupied: [CGRect] = []
        switch constellationMode {
        case .chinese:
            let asterisms = catalog.chineseAsterisms().sorted {
                if $0.isFeatured != $1.isFeatured { return $0.isFeatured && !$1.isFeatured }
                return ($0.rank ?? 3) < ($1.rank ?? 3)
            }
            for asterism in asterisms where shouldShowChineseLabel(for: asterism) {
                guard let center = labelCenter(for: asterism.stars, projection: projection, positionByHIP: positionByHIP) else { continue }
                let font: Font = asterism.isFeatured ? .caption.bold() : .caption2
                let color = asterism.isFeatured ? Color(hex: "FFD700") : Color(hex: "B8C4E0").opacity(0.72)
                drawLabel(asterism.name, at: center, font: font, color: color, occupied: &occupied, in: context)
            }
        case .western:
            let constellations = catalog.westernConstellations().sorted { ($0.rank ?? 3) < ($1.rank ?? 3) }
            for constellation in constellations where shouldShowWesternLabel(for: constellation) {
                guard let center = labelCenter(for: constellation.stars, projection: projection, positionByHIP: positionByHIP) else { continue }
                drawLabel(constellation.name, at: center, font: .caption.bold(), color: Color(hex: "4AC6D9"), occupied: &occupied, in: context)
            }
        }
    }

    private func labelCenter(
        for hips: [Int],
        projection: SkyProjection,
        positionByHIP: [Int: StarPosition]
    ) -> CGPoint? {
        let points = hips.compactMap { hip -> CGPoint? in
            guard let position = positionByHIP[hip] else { return nil }
            return projection.project(azimuth: position.azimuth, altitude: position.altitude)
        }
        guard !points.isEmpty else { return nil }
        return CGPoint(
            x: points.map(\.x).reduce(0, +) / CGFloat(points.count),
            y: points.map(\.y).reduce(0, +) / CGFloat(points.count)
        )
    }

    private func drawLabel(
        _ value: String,
        at center: CGPoint,
        font: Font,
        color: Color,
        occupied: inout [CGRect],
        in context: GraphicsContext
    ) {
        let estimatedWidth = CGFloat(max(2, value.count)) * 15
        let rect = CGRect(x: center.x - estimatedWidth / 2, y: center.y - 10, width: estimatedWidth, height: 20)
        guard !occupied.contains(where: { $0.intersects(rect.insetBy(dx: -8, dy: -4)) }) else { return }
        occupied.append(rect)
        let text = Text(value)
            .font(font)
            .foregroundColor(color)
        context.draw(text, at: center)
    }

    private func shouldShowChineseLabel(for asterism: Asterism) -> Bool {
        if asterism.isFeatured { return true }
        let rank = asterism.rank ?? 3
        if fieldOfView > 80 { return rank == 1 }
        if fieldOfView > 50 { return rank <= 2 }
        return true
    }

    private func shouldShowWesternLabel(for constellation: WesternConstellation) -> Bool {
        let rank = constellation.rank ?? 3
        if fieldOfView > 80 { return rank == 1 }
        if fieldOfView > 50 { return rank <= 2 }
        return true
    }

    private func handleTap(at point: CGPoint, size: CGSize, date: Date) {
        let projection = SkyProjection(centerAzimuth: centerAzimuth, centerAltitude: centerAltitude, fieldOfView: fieldOfView, screenSize: size)
        let positions = AstroMath.calculateVisibleStars(stars: catalog.lineReferenceStars(for: constellationMode), latitude: location.latitude, longitude: location.longitude, date: date, minAltitude: -5)
        let displayHIPs = Set(catalog.displayStars(for: constellationMode).map(\.hip))
        let tapHitRadius: CGFloat = 22

        var closest: (star: Star, position: CGPoint, distance: CGFloat)?
        for position in positions where displayHIPs.contains(position.star.hip) {
            guard let projected = projection.project(azimuth: position.azimuth, altitude: position.altitude) else { continue }
            let distance = hypot(projected.x - point.x, projected.y - point.y)
            if distance < tapHitRadius, closest == nil || distance < closest!.distance {
                closest = (position.star, projected, distance)
            }
        }

        if let closest {
            let hip = closest.star.hip
            let starName = catalog.starName(hip: hip, mode: constellationMode) ?? "HIP \(hip)"
            let constellationName = catalog.constellationName(containing: hip, mode: constellationMode)
            if let featuredAsterism = catalog.featuredAsterism(containing: hip) {
                collection.markViewed(featuredAsterism.id)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    tappedStarInfo = nil
                    selectedAsterism = featuredAsterism
                    selectedWesternConstellation = constellationMode == .western ? catalog.westernConstellation(containing: hip) : nil
                }
            } else {
                let info = TappedStarInfo(
                    hip: hip,
                    starName: starName,
                    constellationName: constellationName,
                    screenPosition: closest.position
                )
                withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                    selectedAsterism = nil
                    selectedWesternConstellation = nil
                    tappedStarInfo = info
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    if tappedStarInfo?.hip == hip {
                        withAnimation(.easeOut(duration: 0.2)) {
                            tappedStarInfo = nil
                        }
                    }
                }
            }
        } else {
            withAnimation(.easeOut(duration: 0.2)) {
                tappedStarInfo = nil
                selectedAsterism = nil
                selectedWesternConstellation = nil
            }
        }
    }

    private func tooltipPosition(for info: TappedStarInfo, in size: CGSize) -> CGPoint {
        let xLimit = max(84, size.width - 84)
        let yLimit = max(96, size.height - 150)
        return CGPoint(
            x: min(max(info.screenPosition.x, 84), xLimit),
            y: min(max(info.screenPosition.y - 48, 82), yLimit)
        )
    }
}

private struct TappedStarInfo: Identifiable {
    let hip: Int
    let starName: String
    let constellationName: String?
    let screenPosition: CGPoint

    var id: Int { hip }
}

private extension Double {
    var normalizedDegrees: Double {
        let value = truncatingRemainder(dividingBy: 360.0)
        return value >= 0 ? value : value + 360.0
    }
}
