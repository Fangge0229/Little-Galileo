//
//  LittleGalileoTests.swift
//  LittleGalileoTests
//
//  Created by 钱前 on 2026/7/4.
//

import Testing
import Foundation
import SwiftUI
import UIKit
@testable import LittleGalileo

struct LittleGalileoTests {

    @Test func polarisAltitudeMatchesObserverLatitude() async throws {
        let date = Date(timeIntervalSince1970: 1_704_067_200)

        let position = AstroMath.horizontalCoordinates(
            ra: 2.5303,
            dec: 89.2641,
            latitude: 30.25,
            longitude: 120.17,
            date: date
        )

        #expect(abs(position.altitude - 30.25) < 1.0)
        #expect(position.azimuth < 5.0 || position.azimuth > 355.0)
    }

    @Test func equatorialStarAtMeridianUsesLatitudeComplementAltitude() async throws {
        let latitude = 30.0
        let longitude = 0.0
        let date = Date(timeIntervalSince1970: 1_704_067_200)
        let jd = AstroMath.julianDay(from: date)
        let raOnMeridian = AstroMath.greenwichMeanSiderealTime(jd: jd) + longitude / 15.0

        let position = AstroMath.horizontalCoordinates(
            ra: raOnMeridian,
            dec: 0.0,
            latitude: latitude,
            longitude: longitude,
            date: date
        )

        #expect(abs(position.altitude - 60.0) < 0.001)
        #expect(abs(position.azimuth - 180.0) < 0.001)
    }

    @Test func skyProjectionProjectsCenterToScreenCenter() async throws {
        let projection = SkyProjection(
            centerAzimuth: 180,
            centerAltitude: 45,
            fieldOfView: 90,
            screenSize: CGSize(width: 300, height: 600)
        )

        let point = try #require(projection.project(azimuth: 180, altitude: 45))

        #expect(abs(point.x - 150) < 0.001)
        #expect(abs(point.y - 300) < 0.001)
    }

    @Test func skyBackgroundProjectionMovesWithSkyCenterAndZoom() async throws {
        let screenSize = CGSize(width: 390, height: 844)
        let base = SkyBackgroundProjection.layout(
            centerAzimuth: 0,
            centerAltitude: 45,
            fieldOfView: 90,
            screenSize: screenSize
        )
        let panned = SkyBackgroundProjection.layout(
            centerAzimuth: 90,
            centerAltitude: 15,
            fieldOfView: 90,
            screenSize: screenSize
        )
        let zoomed = SkyBackgroundProjection.layout(
            centerAzimuth: 0,
            centerAltitude: 45,
            fieldOfView: 45,
            screenSize: screenSize
        )

        #expect(panned.offset != base.offset)
        #expect(zoomed.scale > base.scale)
        #expect(base.tileWidth >= screenSize.width * 2)
    }

    @Test func skyBackgroundProjectionTracksVerticalAltitudeAcrossNormalRange() async throws {
        let screenSize = CGSize(width: 390, height: 844)
        let low = SkyBackgroundProjection.layout(
            centerAzimuth: 0,
            centerAltitude: 15,
            fieldOfView: 90,
            screenSize: screenSize
        )
        let middle = SkyBackgroundProjection.layout(
            centerAzimuth: 0,
            centerAltitude: 45,
            fieldOfView: 90,
            screenSize: screenSize
        )
        let high = SkyBackgroundProjection.layout(
            centerAzimuth: 0,
            centerAltitude: 75,
            fieldOfView: 90,
            screenSize: screenSize
        )

        #expect(low.offset.height < middle.offset.height)
        #expect(middle.offset.height < high.offset.height)
    }

    @Test func tonightRecommendationBackdropUsesDeepBlueStyle() async throws {
        #expect(SkyMapVisualStyle.appBackgroundHex == SkyMapVisualStyle.bottomSurfaceHex)
        #expect(SkyMapVisualStyle.tabBarBackgroundHex == SkyMapVisualStyle.bottomSurfaceHex)
        #expect(SkyMapVisualStyle.tonightBackdropHex == "071A3D")
        #expect(SkyMapVisualStyle.tonightBackdropOpacity >= 0.5)
        #expect(SkyMapVisualStyle.aiButtonBackgroundHex == "071A3D")
        #expect(SkyMapVisualStyle.aiButtonImagePadding > 0)
        #expect(SkyMapVisualStyle.bottomControlBackdropHeightRatio > 0)
        #expect(SkyMapVisualStyle.bottomControlBackdropTopOpacity <= 0.35)
        #expect(SkyMapVisualStyle.bottomControlBackdropOpacity >= 0.75)
    }

    @Test func bundledAsterismDataDecodesFeaturedStories() async throws {
        let catalog = StarCatalog()

        #expect(catalog.featuredAsterisms().count >= 8)
        #expect(catalog.featuredAsterisms().filter { $0.story?.isEmpty == false }.count >= 8)
        #expect(catalog.star(byHIP: 11767) != nil)
    }

    @Test func catalogLoadsDualModeSkyDataAndStarNames() async throws {
        let catalog = StarCatalog()

        #expect(catalog.stars.count < 2_848)
        #expect(catalog.westernConstellations().count >= 88)
        #expect(catalog.chineseAsterisms().count >= 280)
        #expect(catalog.displayStars(for: .chinese).count > 80)
        #expect(catalog.displayStars(for: .chinese).count < 700)
        #expect(catalog.displayStars(for: .western).count > 80)
        #expect(catalog.displayStars(for: .western).count < 700)
        #expect(catalog.starName(hip: 91262, mode: .chinese) != nil)
        #expect(catalog.starName(hip: 91262, mode: .western) != nil)
        #expect(catalog.displayStars(for: .chinese).contains { $0.hip == 11767 })
    }

    @Test func catalogHasStoryMaterialForEveryChineseAsterism() async throws {
        let catalog = StarCatalog()
        let asterisms = catalog.chineseAsterisms()

        #expect(asterisms.count == 310)
        #expect(asterisms.allSatisfy { $0.brief?.isEmpty == false })
        #expect(asterisms.allSatisfy { $0.story?.isEmpty == false })
        #expect(asterisms.allSatisfy { $0.science?.isEmpty == false })
        #expect(asterisms.allSatisfy { $0.storyType?.isEmpty == false })
        #expect(asterisms.allSatisfy { $0.sourceNotes?.isEmpty == false })
    }

    @Test func displayedStarsUseChineseNamesInBothSkyModes() async throws {
        let catalog = StarCatalog()

        #expect(catalog.starName(hip: 71860, mode: .western) == "骑官十")

        for mode in ConstellationMode.allCases {
            let missingChineseNames = catalog.displayStars(for: mode).filter { star in
                guard let name = catalog.starName(hip: star.hip, mode: mode) else { return true }
                return !name.containsChineseCharacter
            }

            #expect(missingChineseNames.isEmpty)
        }
    }

    @Test func catalogBuildsTonightRecommendationsFromFeaturedAsterisms() async throws {
        let catalog = StarCatalog()
        let recommendations = catalog.tonightRecommendations(
            latitude: 30.25,
            longitude: 120.17,
            date: Date(timeIntervalSince1970: 1_704_067_200)
        )

        #expect(!recommendations.isEmpty)
        #expect(recommendations.allSatisfy { $0.asterism.isFeatured })
        #expect(recommendations.count <= catalog.featuredAsterisms().count)
        #expect(zip(recommendations, recommendations.dropFirst()).allSatisfy { current, next in
            current.altitude >= next.altitude
        })
    }

    @Test func collectionStorePersistsViewedAsterisms() async throws {
        let suiteName = "LittleGalileoTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = CollectionStore(defaults: defaults)
        store.markViewed("beidou")

        let reloaded = CollectionStore(defaults: defaults)
        #expect(reloaded.isViewed("beidou"))
        #expect(reloaded.viewedCount() == 1)
        #expect(reloaded.totalFeatured() == 8)
    }

    @Test func bundledVisualAssetsLoadForSkyMapAndAIHelper() async throws {
        #expect(UIImage(named: "SkyMapBackground", in: Bundle.main, compatibleWith: nil) != nil)
        #expect(UIImage(named: "AIHelperBird", in: Bundle.main, compatibleWith: nil) != nil)
        #expect(UIImage(named: "cloud_pattern", in: Bundle.main, compatibleWith: nil) != nil)
        #expect(UIImage(named: "card_border", in: Bundle.main, compatibleWith: nil) != nil)
    }

    @Test func chatServiceRejectsMissingAPIKeyBeforeNetwork() async throws {
        let transport = CapturingChatTransport(
            data: Data(),
            response: HTTPURLResponse(
                url: URL(string: "https://example.test/v1/chat/completions")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
        )
        let provider = AIProvider(
            name: "Test",
            baseURL: "https://example.test/v1",
            apiKey: "   ",
            model: "test-model"
        )
        let service = ChatService(provider: provider, transport: transport)

        var didThrowMissingKey = false
        do {
            _ = try await service.send(messages: [
                ChatMessage(role: .user, content: "北斗七星是什么？")
            ])
        } catch ChatError.missingAPIKey {
            didThrowMissingKey = true
        } catch {
            Issue.record("Expected ChatError.missingAPIKey, got \(error)")
        }

        #expect(didThrowMissingKey)
        #expect(transport.capturedRequest == nil)
    }

    @Test func aiProviderLoadsLocalConfigurationFromJSON() async throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("AIProviderConfig-\(UUID().uuidString).json")
        let json = """
        {
          "name": "通义千问",
          "baseURL": "https://example.test/compatible-mode/v1",
          "apiKey": "local-key",
          "model": "qwen-turbo"
        }
        """
        try json.write(to: fileURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let provider = try AIProvider.loadLocalConfiguration(from: fileURL)

        #expect(provider.name == "通义千问")
        #expect(provider.baseURL == "https://example.test/compatible-mode/v1")
        #expect(provider.apiKey == "local-key")
        #expect(provider.model == "qwen-turbo")
    }

    @Test func chatServiceSendsOpenAICompatibleRequestBody() async throws {
        let replyText = "抬头看北方，像勺子的七颗星就是北斗。"
        let responseBody = """
        {
          "choices": [
            {
              "message": {
                "role": "assistant",
                "content": "\(replyText)"
              }
            }
          ]
        }
        """
        let transport = CapturingChatTransport(
            data: Data(responseBody.utf8),
            response: HTTPURLResponse(
                url: URL(string: "https://example.test/v1/chat/completions")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
        )
        let provider = AIProvider(
            name: "Test",
            baseURL: "https://example.test/v1",
            apiKey: "test-key",
            model: "test-model"
        )
        let service = ChatService(
            provider: provider,
            transport: transport,
            systemPrompt: "你是测试星空助手。"
        )

        let reply = try await service.send(messages: [
            ChatMessage(role: .system, content: "不要发送这个旧系统消息"),
            ChatMessage(role: .user, content: "怎么找到北极星？")
        ])

        #expect(reply == replyText)

        let request = try #require(transport.capturedRequest)
        #expect(request.url?.absoluteString == "https://example.test/v1/chat/completions")
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-key")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

        let bodyData = try #require(request.httpBody)
        let json = try #require(
            JSONSerialization.jsonObject(with: bodyData) as? [String: Any]
        )
        #expect(json["model"] as? String == "test-model")
        #expect(json["stream"] as? Bool == false)

        let messages = try #require(json["messages"] as? [[String: Any]])
        #expect(messages.count == 2)
        #expect(messages[0]["role"] as? String == "system")
        #expect(messages[0]["content"] as? String == "你是测试星空助手。")
        #expect(messages[1]["role"] as? String == "user")
        #expect(messages[1]["content"] as? String == "怎么找到北极星？")
    }

    @MainActor
    @Test func chatStoreAppendsAssistantReplyOnSuccess() async throws {
        let service = StubChatService(result: .success("北极星在北方天空，像小勺子柄尖。"))
        let store = ChatStore(service: service)

        await store.send("  怎么找到北极星？  ")

        #expect(store.messages.count == 2)
        #expect(store.messages[0].role == .user)
        #expect(store.messages[0].content == "怎么找到北极星？")
        #expect(store.messages[1].role == .assistant)
        #expect(store.messages[1].content == "北极星在北方天空，像小勺子柄尖。")
        #expect(store.isLoading == false)
        #expect(store.errorMessage == nil)
        #expect(service.capturedMessages?.map(\.content) == ["怎么找到北极星？"])
    }

    @MainActor
    @Test func chatStoreKeepsUserMessageAndShowsErrorOnFailure() async throws {
        let service = StubChatService(result: .failure(ChatError.missingAPIKey))
        let store = ChatStore(service: service)

        await store.send("北斗七星为什么叫北斗？")

        #expect(store.messages.count == 1)
        #expect(store.messages[0].role == .user)
        #expect(store.messages[0].content == "北斗七星为什么叫北斗？")
        #expect(store.isLoading == false)
        #expect(store.errorMessage == "还没有配置 AI API Key")
    }

    @MainActor
    @Test func birdOnboardingStartsOnlyWhenNotCompleted() async throws {
        let defaults = try onboardingDefaults()
        let store = OnboardingStore(defaults: defaults)

        store.startIfNeeded()

        #expect(store.isActive)
        #expect(store.currentStep == .welcome)

        store.skip()

        let reloaded = OnboardingStore(defaults: defaults)
        reloaded.startIfNeeded()

        #expect(reloaded.hasCompleted)
        #expect(!reloaded.isActive)
        #expect(reloaded.currentStep == .welcome)
    }

    @MainActor
    @Test func birdOnboardingStartsWhenOnlyLegacyCompletionExists() async throws {
        let defaults = try onboardingDefaults()
        defaults.set(true, forKey: "hasCompletedBirdOnboarding")

        let store = OnboardingStore(defaults: defaults)
        store.startIfNeeded()

        #expect(store.isActive)
        #expect(!store.hasCompleted)
        #expect(store.currentStep == .welcome)
    }

    #if DEBUG
    @MainActor
    @Test func birdOnboardingUITestResetClearsCurrentCompletion() async throws {
        let defaults = try onboardingDefaults()
        let store = OnboardingStore(defaults: defaults)

        store.startIfNeeded()
        store.skip()
        #expect(store.hasCompleted)

        OnboardingStore.resetCompletionForUITestsIfRequested(
            arguments: ["UITestResetBirdOnboarding"],
            defaults: defaults
        )

        let reloaded = OnboardingStore(defaults: defaults)
        reloaded.startIfNeeded()
        #expect(reloaded.isActive)
        #expect(!reloaded.hasCompleted)
    }

    @MainActor
    @Test func birdOnboardingDebugLaunchResetClearsCurrentCompletion() async throws {
        let defaults = try onboardingDefaults()
        let store = OnboardingStore(defaults: defaults)

        store.startIfNeeded()
        store.skip()
        #expect(store.hasCompleted)

        OnboardingStore.resetCompletionForDebugLaunch(defaults: defaults)

        let reloaded = OnboardingStore(defaults: defaults)
        reloaded.startIfNeeded()
        #expect(reloaded.isActive)
        #expect(reloaded.currentStep == .welcome)
        #expect(!reloaded.hasCompleted)
    }
    #endif

    @MainActor
    @Test func birdOnboardingAdvancesThroughFirstVersionStepsAndPersistsCompletion() async throws {
        let defaults = try onboardingDefaults()
        let store = OnboardingStore(defaults: defaults)

        store.startIfNeeded()
        #expect(store.currentStep == .welcome)

        store.completeCurrentStep()
        #expect(store.currentStep == .skyGesture)

        store.completeCurrentStep()
        #expect(store.currentStep == .tonightRecommendation)

        store.completeCurrentStep()
        #expect(store.currentStep == .tonightBrowse)

        store.completeCurrentStep()
        #expect(store.currentStep == .cardCollection)

        store.completeCurrentStep()
        #expect(store.currentStep == .cardCollectionBrowse)

        store.completeCurrentStep()
        #expect(store.currentStep == .assistantEntry)

        store.completeCurrentStep()
        #expect(store.currentStep == .chatExplore)

        store.completeCurrentStep()
        #expect(store.currentStep == .voiceInput)
        #expect(!store.hasCompleted)

        store.completeCurrentStep()
        #expect(store.currentStep == .farewell)
        #expect(!store.hasCompleted)

        store.completeCurrentStep()
        #expect(store.hasCompleted)
        #expect(!store.isActive)

        let reloaded = OnboardingStore(defaults: defaults)
        reloaded.startIfNeeded()
        #expect(!reloaded.isActive)
    }

    @Test func birdOnboardingFirstVersionUsesSchemeStepOrder() async throws {
        #expect(OnboardingStep.firstVersionSteps == [
            .welcome,
            .skyGesture,
            .tonightRecommendation,
            .tonightBrowse,
            .cardCollection,
            .cardCollectionBrowse,
            .assistantEntry,
            .chatExplore,
            .voiceInput,
            .farewell
        ])
        #expect(
            OnboardingStep.tonightRecommendation.message ==
            "不知道先看哪颗星？点击下方「今晚推荐」打开推荐面板。"
        )
        #expect(
            OnboardingStep.tonightBrowse.message ==
            "左右滑动可以查看今晚推荐的星宿。看完后点击空白处或关闭按钮退出推荐面板。"
        )
        #expect(
            OnboardingStep.cardCollection.message ==
            "点击下方「图鉴」可以查看你收集到的星宿卡片。"
        )
        #expect(
            OnboardingStep.cardCollectionBrowse.message ==
            "这里是你的星宿图鉴。上方进度环显示收集进度，在星图中点亮星宿就能解锁卡片。"
        )
        #expect(
            OnboardingStep.chatExplore.message ==
            "在下方输入框输入问题，也可以点击上方的快捷提问按钮。试着问一个关于星空的问题吧！"
        )
        #expect(
            OnboardingStep.voiceInput.message ==
            "也可以按住麦克风说出问题。第一次使用时需要授权麦克风权限。"
        )
        #expect(
            OnboardingStep.farewell.message ==
            "太棒啦！你已经学会了所有探索星空的方法。现在出发，去发现属于你的星星吧！"
        )
        #expect(OnboardingStep.welcome.primaryButtonTitle == "开始")
        #expect(OnboardingStep.cardCollectionBrowse.primaryButtonTitle == "下一步")
        #expect(OnboardingStep.voiceInput.primaryButtonTitle == "下一步")
        #expect(OnboardingStep.farewell.primaryButtonTitle == "出发！")
    }

    @Test func birdOnboardingBubbleAvoidsDrawnGuideAvatar() async throws {
        let bubbleSize = CGSize(width: 314, height: 132)
        let birdCenter = CGPoint(x: 343, y: 674)
        let originalCenter = CGPoint(x: 196.5, y: 678)
        let containerSize = CGSize(width: 393, height: 852)

        let avoidedCenter = BirdOnboardingLayout.avoidBubbleOverlap(
            bubbleCenter: originalCenter,
            bubbleSize: bubbleSize,
            birdCenter: birdCenter,
            drawsBird: true,
            containerSize: containerSize
        )
        let bubbleRect = CGRect(
            x: avoidedCenter.x - bubbleSize.width / 2,
            y: avoidedCenter.y - bubbleSize.height / 2,
            width: bubbleSize.width,
            height: bubbleSize.height
        )
        let birdRect = CGRect(x: birdCenter.x - 38, y: birdCenter.y - 38, width: 76, height: 76)

        #expect(!bubbleRect.intersects(birdRect))
        #expect(avoidedCenter.y < originalCenter.y)

        let unchangedCenter = BirdOnboardingLayout.avoidBubbleOverlap(
            bubbleCenter: originalCenter,
            bubbleSize: bubbleSize,
            birdCenter: birdCenter,
            drawsBird: false,
            containerSize: containerSize
        )
        #expect(unchangedCenter == originalCenter)
    }

    @Test func floatingBallAcceptsOnboardingHighlightFlag() async throws {
        let view = FloatingBallView(
            isChatOpen: .constant(false),
            containerSize: CGSize(width: 390, height: 844),
            safeAreaInsets: EdgeInsets(top: 47, leading: 0, bottom: 34, trailing: 0),
            isOnboardingHighlighted: true
        )

        #expect(view.isOnboardingHighlighted)
    }

    @Test func chatPanelAcceptsBottomSafeAreaInset() async throws {
        let view = ChatPanelView(
            isPresented: .constant(true),
            bottomSafeArea: 34
        )

        #expect(view.bottomSafeArea == 34)
    }

    @Test func birdOnboardingUsesLiveAssistantIconWhenTargetExists() async throws {
        #expect(BirdOnboardingLayout.shouldDrawGuideAvatar(for: .welcome))
        #expect(!BirdOnboardingLayout.shouldDrawGuideAvatar(for: .assistantEntry))
        #expect(BirdOnboardingLayout.shouldDrawGuideAvatar(for: .skyGesture))
        #expect(BirdOnboardingLayout.shouldDrawGuideAvatar(for: .chatExplore))
        #expect(BirdOnboardingLayout.shouldDrawGuideAvatar(for: .farewell))
    }

    @Test func birdOnboardingAssistantEntryUsesLiveTargetAnchor() async throws {
        #expect(OnboardingStep.assistantEntry.onboardingTargetKey == .assistantEntry)
        #expect(OnboardingStep.chatExplore.onboardingTargetKey == .chatTextInput)
        #expect(OnboardingStep.tonightBrowse.onboardingTargetKey == .tonightRecommendationClose)
        #expect(OnboardingStep.farewell.onboardingTargetKey == nil)
    }

    @Test func birdOnboardingFallbackRectsMatchStableControlPositions() async throws {
        let size = CGSize(width: 390, height: 844)

        #expect(
            BirdOnboardingLayout.chatTextInputFallbackRect(containerSize: size) ==
            CGRect(x: 14, y: 755, width: 272, height: 43)
        )
        #expect(
            BirdOnboardingLayout.voiceInputFallbackRect(containerSize: size) ==
            CGRect(x: 294, y: 760, width: 42, height: 42)
        )
        #expect(
            BirdOnboardingLayout.tonightRecommendationFallbackRect(containerSize: size) ==
            CGRect(x: 44, y: 705, width: 302, height: 40)
        )
        #expect(
            BirdOnboardingLayout.tonightRecommendationCloseFallbackRect(containerSize: size) ==
            CGRect(x: 340, y: 552, width: 32, height: 32)
        )
    }

    @Test func birdOnboardingForcesTonightEntryVisibleForRecommendationStep() async throws {
        #expect(
            BirdOnboardingLayout.shouldShowTonightEntry(
                hasSelectedAsterism: true,
                showTonightPanel: false,
                isOnboardingActive: true,
                currentStep: .tonightRecommendation
            )
        )
        #expect(
            BirdOnboardingLayout.shouldShowTonightEntry(
                hasSelectedAsterism: false,
                showTonightPanel: false,
                isOnboardingActive: false,
                currentStep: .welcome
            )
        )
        #expect(
            !BirdOnboardingLayout.shouldShowTonightEntry(
                hasSelectedAsterism: true,
                showTonightPanel: false,
                isOnboardingActive: false,
                currentStep: .tonightRecommendation
            )
        )
        #expect(
            !BirdOnboardingLayout.shouldShowTonightEntry(
                hasSelectedAsterism: true,
                showTonightPanel: true,
                isOnboardingActive: true,
                currentStep: .tonightRecommendation
            )
        )
    }

}

private final class CapturingChatTransport: ChatServiceTransport {
    private(set) var capturedRequest: URLRequest?
    private let data: Data
    private let response: URLResponse

    init(data: Data, response: URLResponse) {
        self.data = data
        self.response = response
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        capturedRequest = request
        return (data, response)
    }
}

private final class StubChatService: ChatServing {
    private(set) var capturedMessages: [ChatMessage]?
    private let result: Result<String, Error>

    init(result: Result<String, Error>) {
        self.result = result
    }

    func send(messages: [ChatMessage]) async throws -> String {
        capturedMessages = messages
        return try result.get()
    }
}

private func onboardingDefaults() throws -> UserDefaults {
    let suiteName = "LittleGalileoOnboardingTests-\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defaults.removePersistentDomain(forName: suiteName)
    return defaults
}

private extension String {
    var containsChineseCharacter: Bool {
        unicodeScalars.contains { scalar in
            scalar.value >= 0x4E00 && scalar.value <= 0x9FFF
        }
    }
}
