import SwiftUI

struct CollectionView: View {
    @EnvironmentObject private var catalog: StarCatalog
    @EnvironmentObject private var collection: CollectionStore

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 24) {
                        Text("我的星空收藏")
                            .font(.title.bold())
                            .foregroundStyle(Color(hex: "FFF8E7"))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        progressRing

                        VStack(spacing: 10) {
                            ForEach(catalog.featuredAsterisms()) { asterism in
                                row(for: asterism)
                            }
                        }

                        if collection.viewedCount() == collection.totalFeatured() {
                            Text("太棒了！你已经认识了 8 个中国星宿！")
                                .font(.headline)
                                .foregroundStyle(Color(hex: "FFD700"))
                                .padding()
                                .frame(maxWidth: .infinity)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(hex: "FFD700"), lineWidth: 1)
                                )
                        }
                    }
                    .padding(18)
                }
            }
            .navigationTitle("收藏")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(Color(hex: "3A3A5C"), lineWidth: 16)
            Circle()
                .trim(from: 0, to: collection.progress())
                .stroke(Color(hex: "FFD700"), style: StrokeStyle(lineWidth: 16, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: collection.progress())
            VStack(spacing: 4) {
                Text("\(collection.viewedCount())/8")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(Color(hex: "FFF8E7"))
                Text("已发现 \(collection.viewedCount()) 个星宿")
                    .font(.caption.bold())
                    .foregroundStyle(Color(hex: "B8C4E0"))
            }
        }
        .frame(width: 190, height: 190)
    }

    @ViewBuilder
    private func row(for asterism: Asterism) -> some View {
        let viewed = collection.isViewed(asterism.id)
        if viewed {
            NavigationLink {
                CardDetailView(asterism: asterism)
            } label: {
                rowContent(asterism: asterism, viewed: true)
            }
            .buttonStyle(.plain)
        } else {
            rowContent(asterism: asterism, viewed: false)
        }
    }

    private func rowContent(asterism: Asterism, viewed: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: viewed ? "sparkle" : "circle")
                .font(.title3)
                .foregroundStyle(viewed ? Color(hex: "FFD700") : Color(hex: "B8C4E0"))
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(viewed ? asterism.name : "???")
                    .font(.headline)
                    .foregroundStyle(Color(hex: "FFF8E7"))
                Text(viewed ? asterism.pinyin : "未发现")
                    .font(.caption)
                    .foregroundStyle(Color(hex: "B8C4E0"))
            }
            Spacer()
            Text(viewed ? "已发现" : "未发现")
                .font(.caption.bold())
                .foregroundStyle(viewed ? Color(hex: "7ED321") : Color(hex: "B8C4E0"))
        }
        .padding(14)
        .background(Color(hex: "1E2140").opacity(viewed ? 0.92 : 0.55))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
