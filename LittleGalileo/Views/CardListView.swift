import SwiftUI

struct CardListView: View {
    @EnvironmentObject private var catalog: StarCatalog
    @EnvironmentObject private var collection: CollectionStore

    @State private var selectedCategory: AsterismCategory = .all
    @State private var expandedId: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 18) {
                        progressSection
                            .onboardingTarget(.cardCollectionProgress)

                        categoryBar

                        LazyVStack(spacing: 12) {
                            ForEach(filteredAsterisms) { asterism in
                                AsterismCardRow(
                                    asterism: asterism,
                                    isExpanded: expandedId == asterism.id,
                                    isUnlocked: collection.isViewed(asterism.id)
                                ) {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                        expandedId = expandedId == asterism.id ? nil : asterism.id
                                    }
                                }
                            }
                        }

                        if unlockedFeaturedCount >= totalFeatured {
                            completionBanner
                        }
                    }
                    .padding(18)
                }
            }
            .navigationTitle("小小星官 · 图鉴")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                collection.setFeaturedTotal(catalog.featuredAsterisms().count)
            }
        }
    }

    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(AsterismCategory.allCases, id: \.self) { category in
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedCategory = category
                            expandedId = nil
                        }
                    } label: {
                        Text(category.rawValue)
                            .font(.subheadline.bold())
                            .foregroundStyle(
                                selectedCategory == category
                                    ? Color(hex: "FFD700")
                                    : Color(hex: "B8C4E0")
                            )
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                selectedCategory == category
                                    ? Color(hex: "FFD700").opacity(0.15)
                                    : Color(hex: "1E2140").opacity(0.72)
                            )
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(
                                    selectedCategory == category
                                        ? Color(hex: "FFD700").opacity(0.5)
                                        : Color.clear,
                                    lineWidth: 1
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }
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
                Text("\(unlockedFeaturedCount)/\(totalFeatured)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(hex: "FFF8E7"))
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text("星官收集进度")
                    .font(.headline)
                    .foregroundStyle(Color(hex: "FFF8E7"))
                Text("已发现 \(unlockedFeaturedCount) 个，共 \(totalFeatured) 个重点星官")
                    .font(.caption)
                    .foregroundStyle(Color(hex: "B8C4E0"))
            }

            Spacer()
        }
        .padding(16)
        .background(Color(hex: "1E2140").opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var completionBanner: some View {
        VStack(spacing: 8) {
            Text("太棒了！")
                .font(.title2.bold())
                .foregroundStyle(Color(hex: "FFD700"))
            Text("你已经认识了 \(totalFeatured) 个重点星官！")
                .font(.subheadline)
                .foregroundStyle(Color(hex: "FFF8E7"))
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(hex: "FFD700"), lineWidth: 1.5)
        )
    }

    private var filteredAsterisms: [Asterism] {
        let all = catalog.featuredAsterisms()
        guard let key = selectedCategory.filterKey else { return all }
        return all.filter { $0.category == key }
    }

    private var unlockedFeaturedCount: Int {
        catalog.featuredAsterisms().filter { collection.isViewed($0.id) }.count
    }

    private var totalFeatured: Int {
        max(1, catalog.featuredAsterisms().count)
    }

    private var progressValue: Double {
        min(1, Double(unlockedFeaturedCount) / Double(totalFeatured))
    }
}

private enum AsterismCategory: String, CaseIterable {
    case all = "全部"
    case starter = "新手核心"
    case ershiba = "二十八宿"
    case artifact = "器物建筑"
    case mythical = "神兽人物"

    var filterKey: String? {
        switch self {
        case .all: return nil
        case .starter: return "starter"
        case .ershiba: return "ershiba"
        case .artifact: return "artifact"
        case .mythical: return "mythical"
        }
    }
}

private struct AsterismCardRow: View {
    let asterism: Asterism
    let isExpanded: Bool
    let isUnlocked: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: 14) {
                    iconView

                    VStack(alignment: .leading, spacing: 3) {
                        Text(asterism.displayTitle)
                            .font(.headline)
                            .foregroundStyle(
                                isUnlocked
                                    ? Color(hex: "FFF8E7")
                                    : Color(hex: "B8C4E0").opacity(0.62)
                            )
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)

                        Text(asterism.categoryLabel)
                            .font(.caption2.bold())
                            .foregroundStyle(Color(hex: "FFD700").opacity(isUnlocked ? 0.85 : 0.42))
                    }

                    Spacer(minLength: 8)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.bold())
                        .foregroundStyle(Color(hex: "B8C4E0").opacity(0.55))
                        .frame(width: 24, height: 24)
                }
                .padding(14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                expandedContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "1E2140").opacity(isExpanded ? 0.95 : 0.78))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isExpanded
                        ? Color(hex: "FFD700").opacity(0.3)
                        : Color(hex: "3A3A5C").opacity(0.5),
                    lineWidth: isExpanded ? 1.5 : 0.5
                )
        )
    }

    private var iconView: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "2A2D52").opacity(0.8))
                .frame(width: 48, height: 48)

            if let iconName = asterism.iconName {
                Image(iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .opacity(isUnlocked ? 1 : 0.38)
            } else {
                Image(systemName: "star.fill")
                    .foregroundStyle(Color(hex: "B8C4E0").opacity(0.5))
            }
        }
    }

    @ViewBuilder
    private var expandedContent: some View {
        if isUnlocked {
            VStack(alignment: .leading, spacing: 14) {
                Divider()
                    .background(Color(hex: "3A3A5C"))

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 16) {
                        introText
                        expandedPreview
                    }

                    ZStack(alignment: .topTrailing) {
                        introText
                        expandedPreview
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }

                if let story = asterism.story, !story.isEmpty {
                    cardSection(title: "星官故事", text: story)
                }

                if let science = asterism.science, !science.isEmpty {
                    cardSection(title: "科学知识", text: science)
                }

                HStack(spacing: 8) {
                    miniTag("难度 \(String(repeating: "★", count: max(1, min(3, asterism.difficulty ?? 1))))")
                    miniTag(asterism.best_season ?? "全年可见")
                    miniTag("\(asterism.stars.count) 颗星")
                }

                NavigationLink {
                    CardDetailView(asterism: asterism)
                } label: {
                    Text("查看完整图鉴")
                        .font(.caption.bold())
                        .foregroundStyle(Color(hex: "FFD700"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(hex: "FFD700").opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        } else {
            VStack(spacing: 8) {
                Divider()
                    .background(Color(hex: "3A3A5C"))
                Text("先在星图中找到这个星官，\n就能解锁它的知识卡片")
                    .font(.caption)
                    .foregroundStyle(Color(hex: "B8C4E0").opacity(0.62))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
    }

    private var introText: some View {
        VStack(alignment: .leading, spacing: 10) {
            TianZiGeLabel(chinese: asterism.name, pinyin: asterism.pinyin)

            if let brief = asterism.brief, !brief.isEmpty {
                Text(brief)
                    .font(.caption)
                    .foregroundStyle(Color(hex: "B8C4E0"))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var expandedPreview: some View {
        AsterismLinePreview(asterism: asterism)
            .frame(width: 110, height: 110)
            .offset(y: -4)
    }

    private func cardSection(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(Color(hex: "FFD700"))
            Text(text)
                .font(.caption)
                .foregroundStyle(Color(hex: "FFF8E7"))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func miniTag(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(Color(hex: "FFD700"))
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(hex: "1A1D3A").opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
