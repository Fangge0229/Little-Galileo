import SwiftUI

struct CardListView: View {
    @EnvironmentObject private var catalog: StarCatalog
    @EnvironmentObject private var collection: CollectionStore

    @State private var showLockedMessage = false

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 18) {
                        progressSection
                            .onboardingTarget(.cardCollectionProgress)

                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(catalog.featuredAsterisms()) { asterism in
                                if collection.isViewed(asterism.id) {
                                    NavigationLink {
                                        CardDetailView(asterism: asterism)
                                    } label: {
                                        card(asterism, locked: false)
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    Button {
                                        showLockedMessage = true
                                    } label: {
                                        card(asterism, locked: true)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        if collection.viewedCount() >= totalFeatured {
                            completionBanner
                        }
                    }
                    .padding(18)
                }
            }
            .navigationTitle("小小星官 · 图鉴")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("先在星图中点击这个星宿吧！", isPresented: $showLockedMessage) {
                Button("知道了", role: .cancel) {}
            }
        }
    }

    private var progressSection: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color(hex: "3A3A5C"), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: progressValue)
                    .stroke(
                        Color(hex: "FFD700"),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progressValue)
                Text("\(collection.viewedCount())/\(totalFeatured)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(hex: "FFF8E7"))
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text("星宿收集进度")
                    .font(.headline)
                    .foregroundStyle(Color(hex: "FFF8E7"))
                Text("已发现 \(collection.viewedCount()) 个，共 \(totalFeatured) 个星宿")
                    .font(.caption)
                    .foregroundStyle(Color(hex: "B8C4E0"))
            }

            Spacer()
        }
        .padding(16)
        .background(Color(hex: "1E2140").opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var completionBanner: some View {
        VStack(spacing: 8) {
            Text("太棒了！")
                .font(.title2.bold())
                .foregroundStyle(Color(hex: "FFD700"))
            Text("你已经认识了 \(totalFeatured) 个中国星宿！")
                .font(.subheadline)
                .foregroundStyle(Color(hex: "FFF8E7"))
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "FFD700"), lineWidth: 1.5)
        )
    }

    private func card(_ asterism: Asterism, locked: Bool) -> some View {
        VStack(spacing: 8) {
            if locked {
                Text("?")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(Color(hex: "B8C4E0"))
                Text("去星图中找到它")
                    .font(.caption.bold())
                    .foregroundStyle(Color(hex: "B8C4E0"))
                    .multilineTextAlignment(.center)
            } else {
                PinyinLabel(chinese: asterism.name, pinyin: asterism.pinyin)
                Text(String(repeating: "★", count: max(1, min(3, asterism.difficulty ?? 1))))
                    .font(.caption.bold())
                    .foregroundStyle(Color(hex: "FFD700"))
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .padding(12)
        .background(
            locked
            ? Color(hex: "3A3A5C").opacity(0.72)
            : Color(hex: "1E2140").opacity(0.95)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var totalFeatured: Int {
        max(1, catalog.featuredAsterisms().count)
    }

    private var progressValue: Double {
        min(1, Double(collection.viewedCount()) / Double(totalFeatured))
    }
}
