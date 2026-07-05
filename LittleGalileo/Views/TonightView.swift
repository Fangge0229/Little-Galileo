import SwiftUI

struct TonightView: View {
    @EnvironmentObject private var catalog: StarCatalog
    @EnvironmentObject private var location: LocationManager
    @EnvironmentObject private var collection: CollectionStore

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        header
                        Text("今晚推荐")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Color(hex: "FFD700"))
                            .padding(.horizontal, 18)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                ForEach(recommendedAsterisms) { item in
                                    NavigationLink {
                                        CardDetailView(asterism: item.asterism)
                                    } label: {
                                        recommendationCard(item)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 18)
                        }

                        progressPanel
                            .padding(.horizontal, 18)
                    }
                    .padding(.vertical, 18)
                }
            }
            .navigationTitle("小小星官")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                location.requestLocation()
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(location.cityName) · \(Self.dateText(Date()))")
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: "B8C4E0"))
                Text("小小星官")
                    .font(.title.bold())
                    .foregroundStyle(Color(hex: "FFF8E7"))
            }
            Spacer()
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 30))
                .foregroundStyle(Color(hex: "FFD700"))
        }
        .padding(.horizontal, 18)
    }

    private var recommendedAsterisms: [Recommendation] {
        let now = Date()
        let items = catalog.featuredAsterisms().compactMap { asterism -> Recommendation? in
            guard let hip = asterism.stars.first,
                  let star = catalog.star(byHIP: hip) else { return nil }
            let position = AstroMath.horizontalCoordinates(
                ra: star.ra,
                dec: star.dec,
                latitude: location.latitude,
                longitude: location.longitude,
                date: now
            )
            return Recommendation(asterism: asterism, azimuth: position.azimuth, altitude: position.altitude)
        }
        let visible = items.filter { $0.altitude > 15 }.sorted { $0.altitude > $1.altitude }
        return visible.isEmpty ? items.sorted { $0.altitude > $1.altitude } : Array(visible.prefix(5))
    }

    private func recommendationCard(_ item: Recommendation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            PinyinLabel(
                chinese: item.asterism.name,
                pinyin: item.asterism.pinyin,
                chineseFont: .title2.bold(),
                pinyinFont: .caption,
                chineseColor: Color(hex: "FFF8E7"),
                pinyinColor: Color(hex: "B8C4E0")
            )
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(item.asterism.brief ?? item.asterism.en)
                .font(.body)
                .foregroundStyle(Color(hex: "FFF8E7"))
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            Spacer()

            HStack {
                Label("\(directionName(item.azimuth)) · 抬头约 \(Int(item.altitude.rounded()))°", systemImage: "location.north.line.fill")
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer()
                Text(String(repeating: "★", count: max(1, min(3, item.asterism.difficulty ?? 1))))
            }
            .font(.caption.bold())
            .foregroundStyle(Color(hex: "FFD700"))
        }
        .padding(16)
        .frame(width: 280, height: 180)
        .background(
            LinearGradient(colors: [Color(hex: "1E2140"), Color(hex: "2A2459")], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var progressPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("收集进度")
                    .font(.headline)
                    .foregroundStyle(Color(hex: "FFF8E7"))
                Spacer()
                Text("已浏览 \(collection.viewedCount()) / 共 \(totalFeatured)")
                    .font(.caption.bold())
                    .foregroundStyle(Color(hex: "B8C4E0"))
            }
            ProgressView(value: progressValue)
                .tint(Color(hex: "FFD700"))
        }
        .padding(16)
        .background(Color(hex: "1E2140").opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var totalFeatured: Int {
        max(1, catalog.featuredAsterisms().count)
    }

    private var progressValue: Double {
        min(1, Double(collection.viewedCount()) / Double(totalFeatured))
    }

    private static func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }

    private func directionName(_ azimuth: Double) -> String {
        let directions = ["北方", "东北方", "东方", "东南方", "南方", "西南方", "西方", "西北方"]
        let index = Int(((azimuth + 22.5).truncatingRemainder(dividingBy: 360)) / 45)
        return directions[index]
    }
}

private struct Recommendation: Identifiable {
    let asterism: Asterism
    let azimuth: Double
    let altitude: Double

    var id: String { asterism.id }
}
