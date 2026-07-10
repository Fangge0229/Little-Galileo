import SwiftUI

enum OnboardingTargetKey: Hashable {
    case skyCanvas
    case tonightRecommendation
    case cardCollectionTab
    case cardCollectionProgress
    case assistantEntry
    case chatTextInput
    case voiceInput
    case tonightRecommendationClose
}

struct OnboardingTargetPreferenceKey: PreferenceKey {
    static var defaultValue: [OnboardingTargetKey: Anchor<CGRect>] = [:]

    static func reduce(
        value: inout [OnboardingTargetKey: Anchor<CGRect>],
        nextValue: () -> [OnboardingTargetKey: Anchor<CGRect>]
    ) {
        value.merge(nextValue(), uniquingKeysWith: { _, next in next })
    }
}

extension View {
    func onboardingTarget(_ key: OnboardingTargetKey) -> some View {
        anchorPreference(key: OnboardingTargetPreferenceKey.self, value: .bounds) { anchor in
            [key: anchor]
        }
    }
}

enum BirdOnboardingLayout {
    static func shouldDrawGuideAvatar(for step: OnboardingStep) -> Bool {
        step != .assistantEntry
    }

    static func voiceInputFallbackRect(containerSize size: CGSize) -> CGRect {
        let micY = size.height - 12 - 34 - 17
        let micX = size.width - 14 - 36 - 8 - 17
        return CGRect(x: micX - 21, y: micY - 21, width: 42, height: 42)
    }

    static func chatTextInputFallbackRect(containerSize size: CGSize) -> CGRect {
        let horizontalPadding: CGFloat = 14
        let spacing: CGFloat = 10
        let micWidth: CGFloat = 34
        let sendWidth: CGFloat = 36
        let textFieldHeight: CGFloat = 43
        let bottomPadding: CGFloat = 12 + 34
        let width = max(1, size.width - horizontalPadding * 2 - spacing * 2 - micWidth - sendWidth)
        return CGRect(
            x: horizontalPadding,
            y: size.height - bottomPadding - textFieldHeight,
            width: width,
            height: textFieldHeight
        )
    }

    static func tonightRecommendationFallbackRect(containerSize size: CGSize) -> CGRect {
        CGRect(x: 44, y: size.height - 139, width: max(1, size.width - 88), height: 40)
    }

    static func tonightRecommendationCloseFallbackRect(containerSize size: CGSize) -> CGRect {
        CGRect(x: size.width - 50, y: max(0, size.height - 292), width: 32, height: 32)
    }

    static func shouldShowTonightEntry(
        hasSelectedAsterism: Bool,
        showTonightPanel: Bool,
        isOnboardingActive: Bool,
        currentStep: OnboardingStep
    ) -> Bool {
        guard !showTonightPanel else { return false }
        return !hasSelectedAsterism
            || (isOnboardingActive && currentStep == .tonightRecommendation)
    }

    static func avoidBubbleOverlap(
        bubbleCenter: CGPoint,
        bubbleSize: CGSize,
        birdCenter: CGPoint,
        drawsBird: Bool,
        containerSize: CGSize
    ) -> CGPoint {
        guard drawsBird else { return bubbleCenter }

        let birdHalf: CGFloat = 38
        let gap: CGFloat = 12
        let bubbleRect = CGRect(
            x: bubbleCenter.x - bubbleSize.width / 2,
            y: bubbleCenter.y - bubbleSize.height / 2,
            width: bubbleSize.width,
            height: bubbleSize.height
        )
        let birdRect = CGRect(
            x: birdCenter.x - birdHalf,
            y: birdCenter.y - birdHalf,
            width: birdHalf * 2,
            height: birdHalf * 2
        )

        guard bubbleRect.intersects(birdRect) else { return bubbleCenter }

        return clampBubbleCenter(
            CGPoint(
                x: bubbleCenter.x,
                y: birdCenter.y - birdHalf - gap - bubbleSize.height / 2
            ),
            bubbleSize: bubbleSize,
            containerSize: containerSize
        )
    }

    static func clampBubbleCenter(
        _ point: CGPoint,
        bubbleSize: CGSize,
        containerSize: CGSize
    ) -> CGPoint {
        CGPoint(
            x: min(
                max(point.x, bubbleSize.width / 2 + 16),
                containerSize.width - bubbleSize.width / 2 - 16
            ),
            y: min(
                max(point.y, bubbleSize.height / 2 + 70),
                containerSize.height - bubbleSize.height / 2 - 108
            )
        )
    }
}

struct BirdOnboardingOverlay: View {
    @ObservedObject var store: OnboardingStore
    let targetRects: [OnboardingTargetKey: CGRect]
    let onPrimaryAction: (OnboardingStep) -> Void
    let onSkipAction: (OnboardingStep) -> Void

    var body: some View {
        GeometryReader { geometry in
            if store.isActive {
                overlayContent(size: geometry.size)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .accessibilityIdentifier("BirdOnboardingOverlay")
            }
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.84), value: store.currentStep)
        .animation(.spring(response: 0.34, dampingFraction: 0.84), value: store.isActive)
    }

    private func overlayContent(size: CGSize) -> some View {
        let step = store.currentStep
        let targetRect = resolvedTargetRect(for: step, size: size)
        let birdPosition = resolvedBirdPosition(for: step, targetRect: targetRect, size: size)
        let bubbleWidth = min(size.width - 32, 314)
        let bubblePosition = resolvedBubblePosition(
            for: step,
            birdPosition: birdPosition,
            targetRect: targetRect,
            bubbleWidth: bubbleWidth,
            size: size
        )

        return ZStack {
            OnboardingSpotlight(targetRect: targetRect)
                .allowsHitTesting(false)

            if step == .skyGesture {
                SkyGestureHint()
                    .position(CGPoint(x: size.width / 2, y: size.height * 0.44))
                    .allowsHitTesting(false)
            }

            if BirdOnboardingLayout.shouldDrawGuideAvatar(for: step) {
                BirdGuideAvatar(isEmphasized: step == .assistantEntry)
                    .position(birdPosition)
                    .allowsHitTesting(false)
            }

            BirdGuideBubble(
                step: step,
                onPrimary: {
                    onPrimaryAction(step)
                },
                onSkip: {
                    onSkipAction(step)
                }
            )
            .frame(width: bubbleWidth)
            .position(bubblePosition)
        }
        .frame(width: size.width, height: size.height)
    }

    private func resolvedTargetRect(for step: OnboardingStep, size: CGSize) -> CGRect? {
        if step == .welcome {
            return defaultAssistantRect(size: size)
        }

        if let key = step.onboardingTargetKey, let rect = targetRects[key], rect.width > 1, rect.height > 1 {
            return rect
        }

        switch step {
        case .skyGesture:
            return CGRect(
                x: size.width * 0.12,
                y: size.height * 0.22,
                width: size.width * 0.76,
                height: size.height * 0.42
            )
        case .tonightRecommendation:
            return BirdOnboardingLayout.tonightRecommendationFallbackRect(containerSize: size)
        case .tonightBrowse:
            return BirdOnboardingLayout.tonightRecommendationCloseFallbackRect(containerSize: size)
        case .cardCollection:
            if let rect = targetRects[.cardCollectionTab], rect.width > 1, rect.height > 1 {
                return rect
            }
            return CGRect(x: size.width / 2 + 20, y: size.height - 52, width: size.width / 2 - 40, height: 44)
        case .cardCollectionBrowse:
            if let rect = targetRects[.cardCollectionProgress], rect.width > 1, rect.height > 1 {
                return rect
            }
            return CGRect(
                x: size.width * 0.2,
                y: size.height * 0.08,
                width: size.width * 0.6,
                height: size.height * 0.16
            )
        case .assistantEntry:
            return defaultAssistantRect(size: size)
        case .chatExplore:
            return BirdOnboardingLayout.chatTextInputFallbackRect(containerSize: size)
        case .voiceInput:
            return BirdOnboardingLayout.voiceInputFallbackRect(containerSize: size)
        case .welcome, .modeSwitch, .starTap, .farewell:
            return nil
        }
    }

    private func resolvedBirdPosition(
        for step: OnboardingStep,
        targetRect: CGRect?,
        size: CGSize
    ) -> CGPoint {
        switch step {
        case .tonightRecommendation:
            return CGPoint(x: size.width - 48, y: max(164, size.height - 236))
        case .tonightBrowse:
            return CGPoint(x: size.width - 50, y: size.height * 0.36)
        case .cardCollection:
            return CGPoint(x: size.width - 50, y: max(164, size.height - 178))
        case .cardCollectionBrowse:
            return CGPoint(x: size.width - 50, y: size.height * 0.42)
        case .chatExplore:
            return CGPoint(x: size.width - 50, y: size.height * 0.32)
        case .voiceInput:
            if let targetRect {
                return CGPoint(x: size.width - 50, y: max(150, targetRect.minY - 78))
            }
            return CGPoint(x: size.width - 50, y: size.height - 168)
        case .assistantEntry, .welcome:
            if let targetRect {
                return CGPoint(x: targetRect.midX, y: targetRect.midY)
            }
            return defaultAssistantRect(size: size).center
        case .farewell:
            return CGPoint(x: size.width / 2 + 40, y: size.height * 0.48)
        case .skyGesture:
            return CGPoint(x: size.width - 50, y: size.height * 0.5)
        case .modeSwitch, .starTap:
            return CGPoint(x: size.width - 50, y: size.height * 0.42)
        }
    }

    private func resolvedBubblePosition(
        for step: OnboardingStep,
        birdPosition: CGPoint,
        targetRect: CGRect?,
        bubbleWidth: CGFloat,
        size: CGSize
    ) -> CGPoint {
        let estimatedHeight: CGFloat = switch step {
        case .tonightRecommendation, .tonightBrowse, .cardCollectionBrowse, .chatExplore, .farewell:
            156
        default:
            132
        }
        let proposed: CGPoint

        switch step {
        case .welcome:
            proposed = CGPoint(x: size.width / 2, y: max(118, birdPosition.y - 118))
        case .skyGesture:
            proposed = CGPoint(x: size.width / 2, y: max(140, size.height * 0.24))
        case .tonightRecommendation:
            proposed = CGPoint(
                x: size.width / 2,
                y: max(126, (targetRect?.minY ?? size.height - 156) - estimatedHeight / 2 - 18)
            )
        case .tonightBrowse:
            proposed = CGPoint(
                x: size.width / 2,
                y: max(140, size.height * 0.22)
            )
        case .cardCollection:
            proposed = CGPoint(
                x: size.width / 2,
                y: max(126, (targetRect?.minY ?? size.height - 52) - estimatedHeight / 2 - 18)
            )
        case .cardCollectionBrowse:
            proposed = CGPoint(
                x: size.width / 2,
                y: max(160, (targetRect?.maxY ?? size.height * 0.24) + estimatedHeight / 2 + 24)
            )
        case .assistantEntry:
            proposed = CGPoint(x: max(bubbleWidth / 2 + 16, birdPosition.x - 172), y: birdPosition.y - 92)
        case .chatExplore:
            proposed = CGPoint(
                x: size.width / 2,
                y: max(140, size.height * 0.18)
            )
        case .voiceInput:
            proposed = CGPoint(
                x: size.width / 2,
                y: max(126, (targetRect?.minY ?? size.height - 82) - estimatedHeight / 2 - 18)
            )
        case .farewell:
            proposed = CGPoint(x: size.width / 2, y: max(140, birdPosition.y - 118))
        case .modeSwitch, .starTap:
            proposed = CGPoint(x: size.width / 2, y: max(130, (targetRect?.maxY ?? 120) + 82))
        }

        let bubbleSize = CGSize(width: bubbleWidth, height: estimatedHeight)
        let clamped = clamp(
            proposed,
            bubbleSize: bubbleSize,
            in: size
        )

        return BirdOnboardingLayout.avoidBubbleOverlap(
            bubbleCenter: clamped,
            bubbleSize: bubbleSize,
            birdCenter: birdPosition,
            drawsBird: BirdOnboardingLayout.shouldDrawGuideAvatar(for: step),
            containerSize: size
        )
    }

    private func clamp(_ point: CGPoint, bubbleSize: CGSize, in size: CGSize) -> CGPoint {
        BirdOnboardingLayout.clampBubbleCenter(
            point,
            bubbleSize: bubbleSize,
            containerSize: size
        )
    }

    private func defaultAssistantRect(size: CGSize) -> CGRect {
        CGRect(x: size.width - 78, y: max(180, size.height * 0.58) - 32, width: 64, height: 64)
    }
}

extension OnboardingStep {
    var onboardingTargetKey: OnboardingTargetKey? {
        switch self {
        case .skyGesture:
            return .skyCanvas
        case .tonightRecommendation:
            return .tonightRecommendation
        case .cardCollection:
            return .cardCollectionTab
        case .cardCollectionBrowse:
            return .cardCollectionProgress
        case .voiceInput:
            return .voiceInput
        case .chatExplore:
            return .chatTextInput
        case .tonightBrowse:
            return .tonightRecommendationClose
        case .assistantEntry:
            return .assistantEntry
        case .welcome, .modeSwitch, .starTap, .farewell:
            return nil
        }
    }
}

private struct BirdGuideAvatar: View {
    let isEmphasized: Bool
    @State private var isFloating = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: SkyMapVisualStyle.aiButtonBackgroundHex).opacity(0.96))
                .overlay(
                    Circle()
                        .stroke(Color(hex: SkyMapVisualStyle.aiButtonStrokeHex).opacity(0.66), lineWidth: 1)
                )

            if isEmphasized {
                Circle()
                    .stroke(Color(hex: "1D4F8F").opacity(0.34), lineWidth: 8)
                    .scaleEffect(isFloating ? 1.18 : 1.03)
                    .opacity(isFloating ? 0.28 : 0.52)
            }

            Image("AIHelperBird")
                .resizable()
                .scaledToFit()
                .padding(SkyMapVisualStyle.aiButtonImagePadding)
        }
        .frame(width: 68, height: 68)
        .shadow(color: Color.black.opacity(0.32), radius: 12, y: 5)
        .offset(y: isFloating ? -4 : 4)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                isFloating = true
            }
        }
    }
}

private struct BirdGuideBubble: View {
    let step: OnboardingStep
    let onPrimary: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(step.message)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(hex: "FFF8E7"))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                Button("跳过") {
                    onSkip()
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(hex: "B8C4E0").opacity(0.8))
                .buttonStyle(.plain)
                .accessibilityIdentifier("BirdOnboardingSkipButton")

                Spacer()

                Button(step.primaryButtonTitle) {
                    onPrimary()
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(Color(hex: "FFD700"))
                .buttonStyle(.plain)
                .accessibilityIdentifier("BirdOnboardingPrimaryButton")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(Color(hex: "071A3D").opacity(0.96))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color(hex: "1D4F8F").opacity(0.55), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .shadow(color: Color.black.opacity(0.34), radius: 14, y: 6)
        .accessibilityIdentifier("BirdOnboardingBubble")
    }
}

private struct OnboardingSpotlight: View {
    let targetRect: CGRect?

    var body: some View {
        if let targetRect {
            let padding: CGFloat = 9
            let rect = targetRect.insetBy(dx: -padding, dy: -padding)

            RoundedRectangle(cornerRadius: min(18, max(10, rect.height / 4)), style: .continuous)
                .fill(Color(hex: "1D4F8F").opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: min(18, max(10, rect.height / 4)), style: .continuous)
                        .stroke(Color(hex: "1D4F8F").opacity(0.68), lineWidth: 1.2)
                )
                .shadow(color: Color(hex: "1D4F8F").opacity(0.34), radius: 10)
                .frame(width: rect.width, height: rect.height)
                .position(CGPoint(x: rect.midX, y: rect.midY))
                .onboardingSpotlightAccessibility()
        }
    }
}

private extension View {
    @ViewBuilder
    func onboardingSpotlightAccessibility() -> some View {
        #if DEBUG
        self
            .accessibilityElement(children: .ignore)
            .accessibilityIdentifier("OnboardingSpotlight")
            .accessibilityLabel("OnboardingSpotlight")
        #else
        self.accessibilityHidden(true)
        #endif
    }
}

private struct SkyGestureHint: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(hex: "071A3D").opacity(0.58))
                .frame(width: 132, height: 54)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(hex: "1D4F8F").opacity(0.48), lineWidth: 1)
                )

            Image(systemName: "hand.draw.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Color(hex: "FFF8E7"))
                .offset(x: isAnimating ? 28 : -28)

            HStack(spacing: 70) {
                Image(systemName: "arrow.left")
                Image(systemName: "arrow.right")
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(Color(hex: "FFD700").opacity(0.72))
        }
        .scaleEffect(isAnimating ? 1.04 : 0.98)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
        .accessibilityHidden(true)
    }
}

private extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}
