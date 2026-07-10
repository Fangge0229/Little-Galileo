//
//  ContentView.swift
//  LittleGalileo
//
//  Created by 钱前 on 2026/7/4.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var onboardingStore = OnboardingStore()
    @State private var isChatOpen = false
    @State private var didScheduleOnboarding = false
    @State private var selectedTab = 0

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundEffect = nil
        appearance.backgroundColor = UIColor(hex: SkyMapVisualStyle.tabBarBackgroundHex)
        appearance.shadowColor = UIColor(red: 29 / 255, green: 79 / 255, blue: 143 / 255, alpha: 0.35)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        GeometryReader { rootGeometry in
            ZStack(alignment: .topLeading) {
                Color(hex: SkyMapVisualStyle.appBackgroundHex)
                    .ignoresSafeArea()

                TabView(selection: $selectedTab) {
                    SkyMapView(
                        onboardingStore: onboardingStore,
                        onSkyGestureCompleted: {
                            onboardingStore.complete(.skyGesture)
                        },
                        onTonightRecommendationOpened: {
                            onboardingStore.complete(.tonightRecommendation)
                        },
                        onTonightPanelClosed: {
                            onboardingStore.complete(.tonightBrowse)
                        }
                    )
                        .tabItem {
                            Label("星图", systemImage: "star.circle.fill")
                        }
                        .tag(0)

                    CardListView()
                        .tabItem {
                            Label("图鉴", systemImage: "book.fill")
                        }
                        .tag(1)
                }
                .tint(Color(hex: "FFD700"))
                .background(Color(hex: SkyMapVisualStyle.tabBarBackgroundHex).ignoresSafeArea())
                .toolbarBackground(Color(hex: SkyMapVisualStyle.tabBarBackgroundHex), for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
                .onChange(of: selectedTab) { newValue in
                    if newValue == 1 && onboardingStore.isActive && onboardingStore.currentStep == .cardCollection {
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 350_000_000)
                            onboardingStore.complete(.cardCollection)
                        }
                    }
                }

                if isChatOpen {
                    Color.black.opacity(0.34)
                        .ignoresSafeArea()
                        .onTapGesture {
                            guard canDismissChat else { return }
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                isChatOpen = false
                            }
                        }

                    VStack {
                        Spacer()
                        ChatPanelView(
                            isPresented: $isChatOpen,
                            canDismiss: canDismissChat,
                            bottomSafeArea: rootGeometry.safeAreaInsets.bottom,
                            onSpeechInputTapped: {
                                completeVoiceInputFromOnboarding()
                            }
                        )
                            .frame(
                                maxWidth: .infinity,
                                maxHeight: min(rootGeometry.size.height * 0.72, 640)
                            )
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea(.container, edges: .bottom)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if !isChatOpen && (!onboardingStore.isActive || onboardingStore.currentStep == .assistantEntry) {
                    FloatingBallView(
                        isChatOpen: $isChatOpen,
                        containerSize: rootGeometry.size,
                        safeAreaInsets: rootGeometry.safeAreaInsets,
                        onOpenAssistant: {
                            if onboardingStore.isActive && onboardingStore.currentStep == .assistantEntry {
                                completeAssistantEntryAfterChatSettles()
                            }
                        },
                        isOnboardingHighlighted: onboardingStore.isActive
                            && onboardingStore.currentStep == .assistantEntry
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .overlayPreferenceValue(OnboardingTargetPreferenceKey.self) { targets in
                GeometryReader { proxy in
                    BirdOnboardingOverlay(
                        store: onboardingStore,
                        targetRects: targets.mapValues { proxy[$0] },
                        onPrimaryAction: handleOnboardingPrimaryAction,
                        onSkipAction: handleOnboardingSkip
                    )
                }
            }
        }
        .preferredColorScheme(.dark)
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: isChatOpen)
        .task {
            guard !didScheduleOnboarding else { return }
            didScheduleOnboarding = true
            try? await Task.sleep(nanoseconds: 600_000_000)
            onboardingStore.startIfNeeded()
        }
    }

    private func handleOnboardingPrimaryAction(_ step: OnboardingStep) {
        if step == .cardCollection {
            withAnimation {
                selectedTab = 1
            }
            return
        }
        if step == .cardCollectionBrowse {
            withAnimation {
                selectedTab = 0
            }
        }
        if step == .assistantEntry {
            completeAssistantEntryAfterChatSettles()
            return
        }
        if step == .voiceInput {
            completeVoiceInputFromOnboarding()
            return
        }
        onboardingStore.complete(step)
    }

    private func handleOnboardingSkip(_ step: OnboardingStep) {
        if selectedTab != 0 {
            withAnimation {
                selectedTab = 0
            }
        }
        if isChatOpen {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                isChatOpen = false
            }
        }
        onboardingStore.skip()
    }

    private func openChatFromOnboarding() {
        guard !isChatOpen else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            isChatOpen = true
        }
    }

    private func completeAssistantEntryAfterChatSettles() {
        openChatFromOnboarding()
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 400_000_000)
            onboardingStore.complete(.assistantEntry)
        }
    }

    private func completeVoiceInputFromOnboarding() {
        if isChatOpen {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                isChatOpen = false
            }
        }
        onboardingStore.complete(.voiceInput)
    }

    private var canDismissChat: Bool {
        guard onboardingStore.isActive else { return true }
        return onboardingStore.currentStep != .chatExplore
            && onboardingStore.currentStep != .voiceInput
    }
}

private extension UIColor {
    convenience init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")))
        var value: UInt64 = 0
        scanner.scanHexInt64(&value)

        self.init(
            red: CGFloat((value >> 16) & 0xFF) / 255.0,
            green: CGFloat((value >> 8) & 0xFF) / 255.0,
            blue: CGFloat(value & 0xFF) / 255.0,
            alpha: 1
        )
    }
}

#Preview {
    ContentView()
        .environmentObject(StarCatalog())
        .environmentObject(LocationManager())
        .environmentObject(CollectionStore())
        .environmentObject(ChatStore(provider: .zhipu))
}
