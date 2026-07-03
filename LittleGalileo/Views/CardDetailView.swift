import SwiftUI

struct CardDetailView: View {
    let asterism: Asterism
    @EnvironmentObject private var collection: CollectionStore
    @State private var isFlipped = false

    var body: some View {
        ZStack {
            AppBackground()
            VStack {
                Spacer(minLength: 24)
                ZStack {
                    cardFront
                        .opacity(isFlipped ? 0 : 1)
                        .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                    cardBack
                        .opacity(isFlipped ? 1 : 0)
                        .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
                }
                .frame(maxWidth: 420)
                .frame(minHeight: 520)
                .padding(.horizontal, 18)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        isFlipped.toggle()
                    }
                }
                Spacer(minLength: 24)
            }
        }
        .navigationTitle(asterism.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            collection.markViewed(asterism.id)
        }
    }

    private var cardFront: some View {
        VStack(spacing: 22) {
            Spacer()
            PinyinLabel(
                chinese: asterism.name,
                pinyin: asterism.pinyin,
                chineseFont: .system(size: 40, weight: .bold),
                pinyinFont: .headline
            )
            Text(asterism.en)
                .font(.headline)
                .foregroundStyle(Color(hex: "B8C4E0"))
            Text("由 \(asterism.stars.count) 颗星组成")
                .font(.subheadline)
                .foregroundStyle(Color(hex: "FFD700"))
            if let brief = asterism.brief {
                Text(brief)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color(hex: "FFF8E7"))
                    .padding(.horizontal)
            }
            Spacer()
            Text("点击翻转查看故事 →")
                .font(.footnote.bold())
                .foregroundStyle(Color(hex: "B8C4E0"))
        }
        .padding(26)
        .background(cardBackground)
    }

    private var cardBack: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                section(title: "神话故事", text: asterism.story ?? "暂无故事")
                Divider().overlay(Color.white.opacity(0.25))
                section(title: "科学知识", text: asterism.science ?? "暂无科学知识")
                HStack(spacing: 10) {
                    tag("难度 \(String(repeating: "★", count: max(1, min(3, asterism.difficulty ?? 1))))")
                    tag(asterism.best_season ?? "全年可见")
                }
                .padding(.top, 4)
            }
            .padding(24)
        }
        .background(cardBackground)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(Color(hex: "1E2140").opacity(0.96))
            .shadow(color: .black.opacity(0.35), radius: 18, y: 12)
    }

    private func section(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
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
            .background(Color(hex: "0A0E27").opacity(0.65))
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
