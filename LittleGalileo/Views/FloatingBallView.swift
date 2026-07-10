import SwiftUI

struct FloatingBallView: View {
    @Binding var isChatOpen: Bool
    let containerSize: CGSize
    let safeAreaInsets: EdgeInsets
    let onOpenAssistant: () -> Void
    let isOnboardingHighlighted: Bool

    @State private var position: CGPoint?
    @State private var dragOffset: CGSize = .zero
    @State private var glowPulsing = false

    private let ballSize: CGFloat = 64

    init(
        isChatOpen: Binding<Bool>,
        containerSize: CGSize,
        safeAreaInsets: EdgeInsets,
        onOpenAssistant: @escaping () -> Void = {},
        isOnboardingHighlighted: Bool = false
    ) {
        self._isChatOpen = isChatOpen
        self.containerSize = containerSize
        self.safeAreaInsets = safeAreaInsets
        self.onOpenAssistant = onOpenAssistant
        self.isOnboardingHighlighted = isOnboardingHighlighted
    }

    var body: some View {
        Button {
            let shouldOpenAssistant = !isChatOpen
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                isChatOpen.toggle()
            }
            if shouldOpenAssistant {
                onOpenAssistant()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Color(hex: SkyMapVisualStyle.aiButtonBackgroundHex).opacity(0.94))
                    .overlay(
                        Circle()
                            .stroke(Color(hex: SkyMapVisualStyle.aiButtonStrokeHex).opacity(0.62), lineWidth: 1)
                    )

                if isOnboardingHighlighted {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: "1D4F8F").opacity(0.18),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 28,
                                endRadius: 48
                            )
                        )
                        .scaleEffect(1.3)
                        .allowsHitTesting(false)
                }

                Image("AIHelperBird")
                    .resizable()
                    .scaledToFit()
                    .padding(SkyMapVisualStyle.aiButtonImagePadding)

                if isOnboardingHighlighted {
                    Circle()
                        .stroke(
                            Color(hex: "1D4F8F").opacity(glowPulsing ? 0.6 : 0.25),
                            lineWidth: glowPulsing ? 3 : 8
                        )
                        .scaleEffect(glowPulsing ? 1.35 : 1.05)
                        .animation(
                            .easeInOut(duration: 1.4).repeatForever(autoreverses: true),
                            value: glowPulsing
                        )
                        .allowsHitTesting(false)
                }
            }
            .frame(width: ballSize, height: ballSize)
            .contentShape(Circle())
            .shadow(color: .black.opacity(0.28), radius: 10, y: 4)
        }
        .frame(width: ballSize, height: ballSize)
        .contentShape(Circle())
        .onboardingTarget(.assistantEntry)
        .position(currentPosition())
        .buttonStyle(.plain)
        .accessibilityLabel("星空小助手")
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { value in
                    let current = currentPosition()
                    let proposed = CGPoint(
                        x: current.x + value.translation.width,
                        y: current.y + value.translation.height
                    )
                    dragOffset = .zero

                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        position = snappedPosition(from: proposed)
                    }
                }
        )
        .onAppear {
            if position == nil {
                position = defaultPosition()
            }
            if isOnboardingHighlighted {
                glowPulsing = true
            }
        }
        .onChange(of: containerSize) { _ in
            if let position {
                self.position = snappedPosition(from: position)
            }
        }
        .onChange(of: isOnboardingHighlighted) { highlighted in
            glowPulsing = highlighted
        }
    }

    private func currentPosition() -> CGPoint {
        let base = position ?? defaultPosition()
        return CGPoint(
            x: base.x + dragOffset.width,
            y: base.y + dragOffset.height
        )
    }

    private func defaultPosition() -> CGPoint {
        CGPoint(
            x: containerSize.width - ballSize / 2 - 14,
            y: max(180, containerSize.height * 0.58)
        )
    }

    private func snappedPosition(from proposed: CGPoint) -> CGPoint {
        let minX = ballSize / 2 + 10
        let maxX = containerSize.width - ballSize / 2 - 10
        let minY = safeAreaInsets.top + ballSize / 2 + 12
        let maxY = containerSize.height - safeAreaInsets.bottom - ballSize / 2 - 92
        let snappedX = proposed.x < containerSize.width / 2 ? minX : maxX

        return CGPoint(
            x: snappedX,
            y: min(max(proposed.y, minY), max(minY, maxY))
        )
    }
}

#Preview {
    ZStack {
        Color(hex: "0A0E27").ignoresSafeArea()
        FloatingBallView(
            isChatOpen: .constant(false),
            containerSize: CGSize(width: 390, height: 844),
            safeAreaInsets: EdgeInsets(top: 47, leading: 0, bottom: 34, trailing: 0)
        )
    }
}
