import SwiftUI

struct CardDetailView: View {
    let asterism: Asterism
    @EnvironmentObject private var collection: CollectionStore

    var body: some View {
        ZStack {
            Color(hex: "1A1D3A")
                .ignoresSafeArea()

            cloudDecorations

            ScrollView {
                AncientBorder {
                    VStack(alignment: .leading, spacing: 20) {
                        headerSection

                        section(title: "星官故事", text: asterism.story ?? "数据校验中...")

                        section(title: "科学知识", text: asterism.science ?? "星图数据中...")

                        if let lore = asterism.lore, !lore.isEmpty {
                            section(title: "人文典故", text: lore)
                        }

                        ViewThatFits(in: .horizontal) {
                            tagRow
                            VStack(alignment: .leading, spacing: 8) {
                                if let symbol = asterism.symbol, !symbol.isEmpty {
                                    tag("象征: \(symbol)")
                                }
                                HStack(spacing: 10) {
                                    tag("难度 \(String(repeating: "★", count: max(1, min(3, asterism.difficulty ?? 1))))")
                                    tag(asterism.best_season ?? "全年可见")
                                    tag("\(asterism.stars.count) 颗星")
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 34)
                .frame(maxWidth: 460)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(asterism.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            collection.markViewed(asterism.id)
        }
    }

    private var headerSection: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 16) {
                titleInfo
                headerPreview
            }

            ZStack(alignment: .topTrailing) {
                titleInfo
                headerPreview
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    private var headerPreview: some View {
        AsterismLinePreview(asterism: asterism)
            .frame(width: 130, height: 130)
            .offset(y: -4)
    }

    private var titleInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            TianZiGeLabel(chinese: asterism.name, pinyin: asterism.pinyin)
                .padding(.top, 10)

            if let childTitle = asterism.childTitle {
                Text(childTitle)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color(hex: "FFD700"))
            }

            Text(asterism.en)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color(hex: "B8C4E0"))

            if let brief = asterism.brief, !brief.isEmpty {
                Text(brief)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(Color(hex: "FFF8E7"))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var cloudDecorations: some View {
        ZStack {
            VStack {
                HStack {
                    Spacer()
                    Image("cloud_pattern")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 128)
                        .opacity(0.34)
                }
                Spacer()
            }
            .padding(.top, 18)
            .padding(.trailing, 8)

            VStack {
                Spacer()
                HStack {
                    Image("cloud_pattern")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140)
                        .scaleEffect(x: -1, y: -1)
                        .opacity(0.3)
                    Spacer()
                }
            }
            .padding(.leading, -8)
            .padding(.bottom, 10)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private func section(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(Color(hex: "FFD700"))
            Text(text)
                .font(.body)
                .lineSpacing(6)
                .foregroundStyle(Color(hex: "FFF8E7"))
        }
    }

    private var tagRow: some View {
        HStack(spacing: 10) {
            if let symbol = asterism.symbol, !symbol.isEmpty {
                tag("象征: \(symbol)")
            }
            tag("难度 \(String(repeating: "★", count: max(1, min(3, asterism.difficulty ?? 1))))")
            tag(asterism.best_season ?? "全年可见")
            tag("\(asterism.stars.count) 颗星")
        }
    }

    private func tag(_ text: String) -> some View {
        Text(text)
            .font(.caption.bold())
            .foregroundStyle(Color(hex: "FFD700"))
            .lineLimit(2)
            .minimumScaleFactor(0.72)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color(hex: "1A1D3A").opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct AppBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color(hex: "0A0E27"), Color(hex: "1A1A3E")],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
