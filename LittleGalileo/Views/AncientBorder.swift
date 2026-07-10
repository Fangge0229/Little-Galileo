import SwiftUI

struct AncientBorder<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(22)
            .background(Color(hex: "2A2D52").opacity(0.9))
            .overlay(borderOverlay)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    private var borderOverlay: some View {
        GeometryReader { geometry in
            ZStack {
                Image("card_border")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(Color(hex: "8890B0").opacity(0.28))
                    .opacity(0.55)
                    .allowsHitTesting(false)

                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color(hex: "8890B0").opacity(0.42), lineWidth: 1)
                    .padding(5)

                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color(hex: "8890B0").opacity(0.34), lineWidth: 0.6)
                    .padding(13)

                ForEach(Corner.allCases) { corner in
                    Rectangle()
                        .fill(Color(hex: "8890B0").opacity(0.42))
                        .frame(width: 8, height: 8)
                        .position(corner.position(in: geometry.size, inset: 9))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private enum Corner: CaseIterable, Identifiable {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight

    var id: Self { self }

    func position(in size: CGSize, inset: CGFloat) -> CGPoint {
        switch self {
        case .topLeft:
            return CGPoint(x: inset, y: inset)
        case .topRight:
            return CGPoint(x: size.width - inset, y: inset)
        case .bottomLeft:
            return CGPoint(x: inset, y: size.height - inset)
        case .bottomRight:
            return CGPoint(x: size.width - inset, y: size.height - inset)
        }
    }
}
