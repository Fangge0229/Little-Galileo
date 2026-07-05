import SwiftUI

struct StarInfoPopup: View {
    let asterism: Asterism
    let mode: ConstellationMode
    let westernConstellation: WesternConstellation?
    let onClose: () -> Void

    init(
        asterism: Asterism,
        mode: ConstellationMode = .chinese,
        westernConstellation: WesternConstellation? = nil,
        onClose: @escaping () -> Void
    ) {
        self.asterism = asterism
        self.mode = mode
        self.westernConstellation = westernConstellation
        self.onClose = onClose
    }

    var body: some View {
        VStack(spacing: 14) {
            Capsule()
                .fill(Color.white.opacity(0.35))
                .frame(width: 42, height: 5)
                .padding(.top, 10)

            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(titleText)
                        .font(.title2.bold())
                        .foregroundStyle(Color(hex: "FFF8E7"))
                    Text(subtitleText)
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

            if let brief = briefText {
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
                Label(buttonTitle, systemImage: "book.pages.fill")
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

    private var titleText: String {
        if mode == .western, let westernConstellation {
            return westernConstellation.name
        }
        return asterism.name
    }

    private var subtitleText: String {
        if mode == .western, let westernConstellation {
            return "\(westernConstellation.en) · 对应中国星官：\(asterism.name)"
        }
        return "\(asterism.pinyin) · \(asterism.en)"
    }

    private var briefText: String? {
        if mode == .western, westernConstellation != nil {
            return "这颗星也属于中国星官「\(asterism.name)」，可以继续了解它的传统故事。"
        }
        return asterism.brief
    }

    private var buttonTitle: String {
        mode == .western ? "了解中国星宿故事" : "了解更多"
    }
}

struct StarTooltip: View {
    let starName: String
    let constellation: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(starName)
                .font(.headline.bold())
                .foregroundStyle(Color(hex: "FFF8E7"))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(constellation)
                .font(.caption.bold())
                .foregroundStyle(Color(hex: "B8C4E0"))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .frame(minWidth: 104, maxWidth: 190, alignment: .leading)
        .background(.ultraThinMaterial)
        .background(Color(hex: "11183A").opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 10, y: 6)
    }
}
