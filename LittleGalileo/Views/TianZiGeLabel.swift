import SwiftUI

struct TianZiGeLabel: View {
    let chinese: String
    let pinyin: String

    private var characters: [String] {
        chinese.map { String($0) }
    }

    private var pinyinParts: [String] {
        pinyin.split(separator: " ").map(String.init)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            ForEach(characters.indices, id: \.self) { index in
                VStack(spacing: 3) {
                    Text(pinyinParts[safe: index] ?? "")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color(hex: "B8C4E0"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)
                        .frame(width: 56)

                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "3A3A5C").opacity(0.6))

                        TianZiGridLines()
                            .stroke(
                                Color.white.opacity(0.15),
                                style: StrokeStyle(lineWidth: 0.5, dash: [4, 3])
                            )
                            .padding(5)

                        Text(characters[index])
                            .font(.system(size: 36, weight: .bold, design: .serif))
                            .foregroundStyle(Color(hex: "FFF8E7"))
                            .minimumScaleFactor(0.7)
                    }
                    .frame(width: 56, height: 56)
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

private struct TianZiGridLines: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
