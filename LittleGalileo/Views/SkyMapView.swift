import SwiftUI

struct SkyMapView: View {
    @EnvironmentObject private var catalog: StarCatalog
    @EnvironmentObject private var location: LocationManager
    @EnvironmentObject private var collection: CollectionStore
    @ObservedObject private var onboardingStore: OnboardingStore
    let onSkyGestureCompleted: () -> Void
    let onTonightRecommendationOpened: () -> Void
    let onTonightPanelClosed: () -> Void

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
    @State private var showTonightPanel = false

    init(
        onboardingStore: OnboardingStore,
        onSkyGestureCompleted: @escaping () -> Void = {},
        onTonightRecommendationOpened: @escaping () -> Void = {},
        onTonightPanelClosed: @escaping () -> Void = {}
    ) {
        self.onboardingStore = onboardingStore
        self.onSkyGestureCompleted = onSkyGestureCompleted
        self.onTonightRecommendationOpened = onTonightRecommendationOpened
        self.onTonightPanelClosed = onTonightPanelClosed
    }

    private var isTonightOnboarding: Bool {
        onboardingStore.isActive
            && (onboardingStore.currentStep == .tonightRecommendation
                || onboardingStore.currentStep == .tonightBrowse)
    }

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 60)) { timeline in
                GeometryReader { geometry in
                    let shouldShowTonightEntry = BirdOnboardingLayout.shouldShowTonightEntry(
                        hasSelectedAsterism: selectedAsterism != nil,
                        showTonightPanel: showTonightPanel,
                        isOnboardingActive: onboardingStore.isActive,
                        currentStep: onboardingStore.currentStep
                    )

                    ZStack(alignment: .bottom) {
                        skyBackground(size: geometry.size)

                        skyCanvas(size: geometry.size, date: timeline.date)
                            .contentShape(Rectangle())
                            .gesture(dragGesture)
                            .simultaneousGesture(magnificationGesture)
                            .onTapGesture { point in
                                handleTap(at: point, size: geometry.size, date: timeline.date)
                            }
                            .onboardingTarget(.skyCanvas)

                        bottomControlBackdrop(size: geometry.size)
                            .allowsHitTesting(false)

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

                        if shouldShowTonightEntry {
                            VStack {
                                Spacer()
                                tonightEntryBar(date: timeline.date)
                                    .padding(.bottom, 16)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        if showTonightPanel {
                            tonightExpandedPanel(date: timeline.date, size: geometry.size)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
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
            .onChange(of: onboardingStore.currentStep) { step in
                if step == .tonightRecommendation {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        selectedAsterism = nil
                        selectedWesternConstellation = nil
                        tappedStarInfo = nil
                    }
                }

                if step == .tonightBrowse && !showTonightPanel {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        selectedAsterism = nil
                        selectedWesternConstellation = nil
                        tappedStarInfo = nil
                        showTonightPanel = true
                    }
                }

                if step != .tonightRecommendation && step != .tonightBrowse && showTonightPanel {
                    closeTonightPanel(notify: false)
                }
            }
        }
        .background(Color(hex: SkyMapVisualStyle.appBackgroundHex).ignoresSafeArea())
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
            drawHorizon(in: context, projection: projection, size: canvasSize)
            drawConstellationLines(in: context, projection: projection, positionByHIP: positionByHIP)
            drawStars(in: context, projection: projection, positions: displayPositions)
            drawConstellationLabels(in: context, projection: projection, positionByHIP: positionByHIP)
        }
    }

    private func skyBackground(size: CGSize) -> some View {
        let layout = SkyBackgroundProjection.layout(
            centerAzimuth: centerAzimuth,
            centerAltitude: centerAltitude,
            fieldOfView: fieldOfView,
            screenSize: size
        )

        return HStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { _ in
                Image("SkyMapBackground")
                    .resizable()
                    .scaledToFill()
                    .frame(width: layout.tileWidth, height: layout.tileHeight)
                    .clipped()
            }
        }
        .offset(layout.offset)
        .opacity(0.98)
        .frame(width: size.width, height: size.height)
        .clipped()
        .background(Color(hex: SkyMapVisualStyle.appBackgroundHex).ignoresSafeArea())
        .accessibilityHidden(true)
    }

    private func bottomControlBackdrop(size: CGSize) -> some View {
        let height = max(
            SkyMapVisualStyle.bottomControlBackdropMinHeight,
            size.height * SkyMapVisualStyle.bottomControlBackdropHeightRatio
        )

        return VStack(spacing: 0) {
            Spacer()
            LinearGradient(
                colors: [
                    Color(hex: SkyMapVisualStyle.appBackgroundHex)
                        .opacity(SkyMapVisualStyle.bottomControlBackdropTopOpacity),
                    Color(hex: SkyMapVisualStyle.appBackgroundHex)
                        .opacity(SkyMapVisualStyle.bottomControlBackdropOpacity)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: height)
        }
        .frame(width: size.width, height: size.height)
        .accessibilityHidden(true)
    }

    private func tonightEntryBar(date: Date) -> some View {
        let items = recommendedAsterisms(date: date)
        let count = items.count
        let first = items.first

        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                selectedAsterism = nil
                selectedWesternConstellation = nil
                tappedStarInfo = nil
                showTonightPanel = true
            }
            onTonightRecommendationOpened()
        } label: {
            HStack(spacing: 8) {
                if let first {
                    asterismPreview(first.asterism, compact: true)
                        .frame(width: 42, height: 28)
                } else {
                    Image(systemName: "moon.stars.fill")
                        .font(.caption)
                        .foregroundStyle(Color(hex: "FFD700"))
                }
                Text("今晚推荐")
                    .font(.caption.bold())
                    .foregroundStyle(Color(hex: "FFF8E7"))
                if let first {
                    Text("· \(first.asterism.name)")
                        .font(.caption)
                        .foregroundStyle(Color(hex: "FFD700"))
                }
                Text("· \(count) 个可见")
                    .font(.caption)
                    .foregroundStyle(Color(hex: "B8C4E0"))
                Image(systemName: "chevron.up")
                    .font(.caption2)
                    .foregroundStyle(Color(hex: "B8C4E0"))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Color(hex: "071A3D").opacity(0.94))
            .overlay(
                Capsule()
                    .stroke(Color(hex: "1D4F8F").opacity(0.55), lineWidth: 1)
            )
            .clipShape(Capsule())
            .onboardingTarget(.tonightRecommendation)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("TonightRecommendationEntry")
    }

    private func tonightExpandedPanel(date: Date, size: CGSize) -> some View {
        ZStack(alignment: .bottom) {
            Color(hex: SkyMapVisualStyle.tonightBackdropHex)
                .opacity(SkyMapVisualStyle.tonightBackdropOpacity)
                .ignoresSafeArea()
                .onTapGesture {
                    closeTonightPanel(notify: true)
                }

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Capsule()
                        .fill(Color.white.opacity(0.35))
                        .frame(width: 40, height: 5)
                    Spacer()
                    Button {
                        closeTonightPanel(notify: true)
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.caption.bold())
                            .foregroundStyle(Color.white.opacity(0.6))
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                            .onboardingTarget(.tonightRecommendationClose)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("关闭今晚推荐")
                    .accessibilityIdentifier("TonightRecommendationCloseButton")
                }
                .padding(.top, 12)

                HStack {
                    Text("今晚推荐")
                        .font(.headline.bold())
                        .foregroundStyle(Color(hex: "FFD700"))
                    Spacer()
                    Text("\(location.cityName) · \(Self.dateText(date))")
                        .font(.caption)
                        .foregroundStyle(Color(hex: "B8C4E0"))
                }

                let items = recommendedAsterisms(date: date)
                if items.isEmpty {
                    Text("今晚暂无可见的重点星宿，晚点再来看看吧")
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: "B8C4E0"))
                        .padding(.vertical, 20)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(items) { item in
                                if isTonightOnboarding {
                                    recommendCard(item)
                                } else {
                                    NavigationLink {
                                        CardDetailView(asterism: item.asterism)
                                    } label: {
                                        recommendCard(item)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .accessibilityIdentifier("TonightRecommendationScroll")
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "071A3D").opacity(0.96))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(hex: "1D4F8F").opacity(0.5), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.4), radius: 20, y: -5)
            )
        }
        .frame(width: size.width, height: size.height, alignment: .bottom)
    }

    private func closeTonightPanel(notify: Bool) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            showTonightPanel = false
        }
        if notify {
            onTonightPanelClosed()
        }
    }

    private func recommendCard(_ item: TonightRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            asterismPreview(item.asterism, compact: false)
                .frame(height: 52)
                .frame(maxWidth: .infinity)

            PinyinLabel(
                chinese: item.asterism.name,
                pinyin: item.asterism.pinyin,
                chineseFont: .subheadline.bold(),
                pinyinFont: .caption2,
                chineseColor: Color(hex: "FFF8E7"),
                pinyinColor: Color(hex: "B8C4E0")
            )
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(item.asterism.brief ?? item.asterism.en)
                .font(.caption)
                .foregroundStyle(Color(hex: "FFF8E7"))
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)

            HStack {
                Label(
                    "\(directionName(item.azimuth)) · \(Int(item.altitude.rounded()))°",
                    systemImage: "location.north.line.fill"
                )
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                Spacer()
                Text(String(repeating: "★", count: max(1, min(3, item.asterism.difficulty ?? 1))))
            }
            .font(.caption2.bold())
            .foregroundStyle(Color(hex: "FFD700"))
        }
        .padding(12)
        .frame(width: 210, height: 184)
        .background(
            LinearGradient(
                colors: [Color(hex: "0B234A"), Color(hex: "08204A")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func asterismPreview(_ asterism: Asterism, compact: Bool) -> some View {
        AsterismLinePreview(asterism: asterism, compact: compact)
    }

    private func recommendedAsterisms(date: Date) -> [TonightRecommendation] {
        catalog.tonightRecommendations(
            latitude: location.latitude,
            longitude: location.longitude,
            date: date
        )
    }

    private func directionName(_ azimuth: Double) -> String {
        let directions = ["北方", "东北方", "东方", "东南方", "南方", "西南方", "西方", "西北方"]
        let index = Int(((azimuth + 22.5).truncatingRemainder(dividingBy: 360)) / 45)
        return directions[index]
    }

    private static func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
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
                onSkyGestureCompleted()
            }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                fieldOfView = min(120, max(30, pinchStartFOV / Double(value)))
            }
            .onEnded { _ in
                pinchStartFOV = fieldOfView
                onSkyGestureCompleted()
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
