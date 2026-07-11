//
//  LittleGalileoApp.swift
//  LittleGalileo
//
//  Created by 钱前 on 2026/7/4.
//

import SwiftUI

@main
struct LittleGalileoApp: App {
    @StateObject private var catalog = StarCatalog()
    @StateObject private var location = LocationManager()
    @StateObject private var collection = CollectionStore()
    @StateObject private var chatStore = ChatStore(provider: .appDefault)
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @StateObject private var speechSynthesizer = SpeechSynthesizer()

    init() {
        #if DEBUG
        OnboardingStore.resetCompletionForDebugLaunch()
        OnboardingStore.resetCompletionForUITestsIfRequested()
        OnboardingStore.completeForUITestsIfRequested()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            AppRootView(
                catalog: catalog,
                location: location,
                collection: collection,
                chatStore: chatStore,
                speechRecognizer: speechRecognizer,
                speechSynthesizer: speechSynthesizer
            )
        }
    }
}

private struct AppRootView: View {
    @ObservedObject var catalog: StarCatalog
    @ObservedObject var location: LocationManager
    @ObservedObject var collection: CollectionStore
    @ObservedObject var chatStore: ChatStore
    @ObservedObject var speechRecognizer: SpeechRecognizer
    @ObservedObject var speechSynthesizer: SpeechSynthesizer

    var body: some View {
        configuredContentView()
            .onAppear {
                collection.setFeaturedTotal(catalog.featuredAsterisms().count)
            }
    }

    private func configuredContentView() -> AnyView {
        var view = AnyView(ContentView())
        view = AnyView(view.environmentObject(catalog))
        view = AnyView(view.environmentObject(location))
        view = AnyView(view.environmentObject(collection))
        view = AnyView(view.environmentObject(chatStore))
        view = AnyView(view.environmentObject(speechRecognizer))
        view = AnyView(view.environmentObject(speechSynthesizer))
        view = AnyView(view.preferredColorScheme(.dark))
        return view
    }
}
