import SwiftUI

struct StarInfoPopup: View {
    let asterism: Asterism
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Capsule()
                .fill(Color.white.opacity(0.35))
                .frame(width: 42, height: 5)
                .padding(.top, 10)

            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(asterism.name)
                        .font(.title2.bold())
                        .foregroundStyle(Color(hex: "FFF8E7"))
                    Text("\(asterism.pinyin) · \(asterism.en)")
                        .font(.caption)
                        .foregroundStyle(Color(hex: "B8C4E0"))
                }
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.white.opacity(0.65))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("关闭")
            }

            if let brief = asterism.brief {
                Text(brief)
                    .font(.body)
                    .foregroundStyle(Color(hex: "FFF8E7"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 12) {
                Label(difficultyText, systemImage: "star.fill")
                    .labelStyle(.titleAndIcon)
                Label(asterism.best_season ?? "全年可见", systemImage: "calendar")
                    .labelStyle(.titleAndIcon)
                Spacer()
            }
            .font(.caption.bold())
            .foregroundStyle(Color(hex: "FFD700"))

            NavigationLink {
                CardDetailView(asterism: asterism)
            } label: {
                Label("了解更多", systemImage: "book.pages.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(hex: "FFD700"))
                    .foregroundStyle(Color(hex: "0A0E27"))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 18)
        .background(.ultraThinMaterial)
        .background(Color(hex: "1E2140").opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var difficultyText: String {
        String(repeating: "★", count: max(1, min(3, asterism.difficulty ?? 1)))
    }
}
