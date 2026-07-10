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
                        TianZiGeLabel(chinese: asterism.name, pinyin: asterism.pinyin)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 10)

                        Text(asterism.en)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color(hex: "B8C4E0"))

                        if let brief = asterism.brief, !brief.isEmpty {
                            Text(brief)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(Color(hex: "FFF8E7"))
                                .lineSpacing(4)
                        }

                        section(title: "星官故事", text: asterism.story ?? "数据校验中...")

                        section(title: "科学知识", text: asterism.science ?? "星图数据中...")

                        HStack(spacing: 10) {
                            tag("难度 \(String(repeating: "★", count: max(1, min(3, asterism.difficulty ?? 1))))")
                            tag(asterism.best_season ?? "全年可见")
                            tag("\(asterism.stars.count) 颗星")
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

    private func tag(_ text: String) -> some View {
        Text(text)
            .font(.caption.bold())
            .foregroundStyle(Color(hex: "FFD700"))
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
