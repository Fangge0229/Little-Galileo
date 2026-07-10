//
//  LittleGalileoUITests.swift
//  LittleGalileoUITests
//
//  Created by 钱前 on 2026/7/4.
//

import XCTest

final class LittleGalileoUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    private func dismissBirdOnboardingIfVisible(in app: XCUIApplication) {
        let skipButton = app.buttons["BirdOnboardingSkipButton"]
        if skipButton.waitForExistence(timeout: 3) {
            skipButton.tap()
            XCTAssertTrue(
                skipButton.waitForNonExistence(timeout: 2),
                "非新手教程测试需要先跳过 Debug 启动时自动出现的教程"
            )
        }
    }

    private func assertSpotlight(
        in app: XCUIApplication,
        alignsWith target: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let spotlight = app.otherElements["OnboardingSpotlight"]
        XCTAssertTrue(spotlight.waitForExistence(timeout: 2), "应该能定位到聚光灯元素", file: file, line: line)
        XCTAssertTrue(target.waitForExistence(timeout: 2), "应该能定位到被高亮目标", file: file, line: line)

        let spotlightFrame = spotlight.frame
        let targetFrame = target.frame
        let dx = abs(spotlightFrame.midX - targetFrame.midX)
        let dy = abs(spotlightFrame.midY - targetFrame.midY)
        let expectedSpotlightPadding: CGFloat = 9
        let widthDelta = abs(spotlightFrame.width - (targetFrame.width + expectedSpotlightPadding * 2))
        let heightDelta = abs(spotlightFrame.height - (targetFrame.height + expectedSpotlightPadding * 2))

        XCTAssertLessThanOrEqual(dx, 2, "聚光灯 X 偏移 \(dx)，spotlight=\(spotlightFrame)，target=\(targetFrame)", file: file, line: line)
        XCTAssertLessThanOrEqual(dy, 2, "聚光灯 Y 偏移 \(dy)，spotlight=\(spotlightFrame)，target=\(targetFrame)", file: file, line: line)
        XCTAssertLessThanOrEqual(widthDelta, 3, "聚光灯宽度偏差 \(widthDelta)，spotlight=\(spotlightFrame)，target=\(targetFrame)", file: file, line: line)
        XCTAssertLessThanOrEqual(heightDelta, 3, "聚光灯高度偏差 \(heightDelta)，spotlight=\(spotlightFrame)，target=\(targetFrame)", file: file, line: line)
    }

    private func assertSpotlightAlignsWithChatTextInput(
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let spotlight = app.otherElements["OnboardingSpotlight"]
        let input = app.textFields["ChatTextInput"]
        XCTAssertTrue(spotlight.waitForExistence(timeout: 2), "应该能定位到聚光灯元素", file: file, line: line)
        XCTAssertTrue(input.waitForExistence(timeout: 2), "应该能定位到 AI 输入框", file: file, line: line)

        let spotlightFrame = spotlight.frame
        let visualInputFrame = input.frame.insetBy(dx: -13, dy: -10)
        let expectedSpotlightFrame = visualInputFrame.insetBy(dx: -9, dy: -9)

        XCTAssertLessThanOrEqual(abs(spotlightFrame.midX - expectedSpotlightFrame.midX), 2, "AI 输入框聚光灯 X 偏移，spotlight=\(spotlightFrame)，expected=\(expectedSpotlightFrame)", file: file, line: line)
        XCTAssertLessThanOrEqual(abs(spotlightFrame.midY - expectedSpotlightFrame.midY), 2, "AI 输入框聚光灯 Y 偏移，spotlight=\(spotlightFrame)，expected=\(expectedSpotlightFrame)", file: file, line: line)
        XCTAssertLessThanOrEqual(abs(spotlightFrame.width - expectedSpotlightFrame.width), 3, "AI 输入框聚光灯宽度偏差，spotlight=\(spotlightFrame)，expected=\(expectedSpotlightFrame)", file: file, line: line)
        XCTAssertLessThanOrEqual(abs(spotlightFrame.height - expectedSpotlightFrame.height), 3, "AI 输入框聚光灯高度偏差，spotlight=\(spotlightFrame)，expected=\(expectedSpotlightFrame)", file: file, line: line)
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testSkyMapExpandsTonightRecommendationsAfterTap() throws {
        let app = XCUIApplication()
        app.launch()
        dismissBirdOnboardingIfVisible(in: app)

        XCTAssertTrue(
            app.buttons["TonightRecommendationEntry"].waitForExistence(timeout: 5),
            "星图页底部应该默认渲染今晚推荐入口"
        )
        XCTAssertFalse(
            app.scrollViews["TonightRecommendationScroll"].exists,
            "推荐卡片默认不应该展开"
        )

        app.buttons["TonightRecommendationEntry"]
            .coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .tap()

        XCTAssertTrue(
            app.scrollViews["TonightRecommendationScroll"].waitForExistence(timeout: 3),
            "点击今晚推荐后应该渲染推荐卡片列表"
        )
    }

    @MainActor
    func testChatPanelShowsSpeechInputButton() throws {
        let app = XCUIApplication()
        app.launch()
        dismissBirdOnboardingIfVisible(in: app)

        XCTAssertTrue(
            app.buttons["星空小助手"].waitForExistence(timeout: 5),
            "星图页应该显示 AI 助手入口"
        )
        app.buttons["星空小助手"].tap()

        XCTAssertTrue(
            app.buttons["SpeechInputButton"].waitForExistence(timeout: 3),
            "AI 对话面板应该显示语音输入按钮"
        )
    }

    @MainActor
    func testBirdOnboardingAppearsOnFirstLaunchForCurrentGuideVersion() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITestResetBirdOnboarding"]
        app.launch()

        XCTAssertTrue(
            app.staticTexts["你好，我是星空小助手。让我带你认识今晚的星空。"]
                .waitForExistence(timeout: 5),
            "当前版本教程未完成时，首次进入应该显示欢迎文案"
        )
        XCTAssertTrue(
            app.buttons["开始"].waitForExistence(timeout: 2),
            "新手指引浮层应该显示开始按钮"
        )
    }

    @MainActor
    func testBirdOnboardingIncludesCardCollectionStep() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITestResetBirdOnboarding"]
        app.launch()

        XCTAssertTrue(app.buttons["开始"].waitForExistence(timeout: 5))
        app.buttons["开始"].tap()

        XCTAssertTrue(app.buttons["下一步"].waitForExistence(timeout: 2))
        app.buttons["下一步"].tap()

        XCTAssertTrue(
            app.staticTexts["不知道先看哪颗星？点击下方「今晚推荐」打开推荐面板。"]
                .waitForExistence(timeout: 2)
        )
        app.buttons["下一步"].tap()

        XCTAssertTrue(
            app.staticTexts["左右滑动可以查看今晚推荐的星宿。看完后点击空白处或关闭按钮退出推荐面板。"]
                .waitForExistence(timeout: 2),
            "今晚推荐入口步骤之后应该出现推荐面板浏览教学"
        )
        XCTAssertTrue(
            app.scrollViews["TonightRecommendationScroll"].waitForExistence(timeout: 2),
            "进入推荐浏览教学时应该自动打开今晚推荐面板"
        )
        app.buttons["下一步"].tap()

        XCTAssertTrue(
            app.staticTexts["点击下方「图鉴」可以查看你收集到的星宿卡片。"]
                .waitForExistence(timeout: 2),
            "今晚推荐浏览后应该出现图鉴教学步骤"
        )
    }

    @MainActor
    func testBirdOnboardingSpotlightAlignsWithTonightEntry() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITestResetBirdOnboarding"]
        app.launch()

        XCTAssertTrue(app.buttons["开始"].waitForExistence(timeout: 5))
        app.buttons["开始"].tap()
        XCTAssertTrue(app.buttons["下一步"].waitForExistence(timeout: 2))
        app.buttons["下一步"].tap()
        XCTAssertTrue(
            app.staticTexts["不知道先看哪颗星？点击下方「今晚推荐」打开推荐面板。"]
                .waitForExistence(timeout: 2)
        )

        assertSpotlight(in: app, alignsWith: app.buttons["TonightRecommendationEntry"])
    }

    @MainActor
    func testBirdOnboardingSpotlightAlignsWithTonightCloseButton() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITestResetBirdOnboarding"]
        app.launch()

        XCTAssertTrue(app.buttons["开始"].waitForExistence(timeout: 5))
        app.buttons["开始"].tap()
        XCTAssertTrue(app.buttons["下一步"].waitForExistence(timeout: 2))
        app.buttons["下一步"].tap()
        XCTAssertTrue(
            app.staticTexts["不知道先看哪颗星？点击下方「今晚推荐」打开推荐面板。"]
                .waitForExistence(timeout: 2)
        )

        app.buttons["下一步"].tap()

        XCTAssertTrue(
            app.staticTexts["左右滑动可以查看今晚推荐的星宿。看完后点击空白处或关闭按钮退出推荐面板。"]
                .waitForExistence(timeout: 2)
        )
        assertSpotlight(in: app, alignsWith: app.buttons["TonightRecommendationCloseButton"])
    }

    @MainActor
    func testBirdOnboardingDisablesTonightRecommendationCardNavigation() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITestResetBirdOnboarding"]
        app.launch()

        XCTAssertTrue(app.buttons["开始"].waitForExistence(timeout: 5))
        app.buttons["开始"].tap()
        XCTAssertTrue(app.buttons["下一步"].waitForExistence(timeout: 2))
        app.buttons["下一步"].tap()
        XCTAssertTrue(
            app.staticTexts["不知道先看哪颗星？点击下方「今晚推荐」打开推荐面板。"]
                .waitForExistence(timeout: 2)
        )

        app.buttons["下一步"].tap()

        XCTAssertTrue(
            app.staticTexts["左右滑动可以查看今晚推荐的星宿。看完后点击空白处或关闭按钮退出推荐面板。"]
                .waitForExistence(timeout: 2)
        )

        let recommendationScroll = app.scrollViews["TonightRecommendationScroll"]
        XCTAssertTrue(recommendationScroll.waitForExistence(timeout: 2))
        recommendationScroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        XCTAssertTrue(
            app.staticTexts["左右滑动可以查看今晚推荐的星宿。看完后点击空白处或关闭按钮退出推荐面板。"]
                .waitForExistence(timeout: 1),
            "今晚推荐教学期间点击卡片不应该跳转离开引导"
        )
        XCTAssertTrue(
            app.navigationBars["小小星官 · 星图"].exists,
            "今晚推荐教学期间点击卡片后仍应停留在星图页"
        )
    }

    @MainActor
    func testBirdOnboardingSpotlightAlignsWithAssistantAndVoiceInput() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITestResetBirdOnboarding"]
        app.launch()

        XCTAssertTrue(app.buttons["开始"].waitForExistence(timeout: 5))
        app.buttons["开始"].tap()
        XCTAssertTrue(app.buttons["下一步"].waitForExistence(timeout: 2))
        app.buttons["下一步"].tap()
        XCTAssertTrue(app.buttons["下一步"].waitForExistence(timeout: 2))
        app.buttons["下一步"].tap()
        XCTAssertTrue(app.buttons["下一步"].waitForExistence(timeout: 2))
        app.buttons["下一步"].tap()
        XCTAssertTrue(app.buttons["下一步"].waitForExistence(timeout: 2))
        app.buttons["下一步"].tap()
        XCTAssertTrue(app.buttons["下一步"].waitForExistence(timeout: 2))
        app.buttons["下一步"].tap()

        XCTAssertTrue(
            app.staticTexts["遇到不懂的星名、故事或观测方法，可以点我提问。"]
                .waitForExistence(timeout: 2)
        )
        assertSpotlight(in: app, alignsWith: app.buttons["星空小助手"])

        app.buttons["下一步"].tap()

        XCTAssertTrue(
            app.staticTexts["在下方输入框输入问题，也可以点击上方的快捷提问按钮。试着问一个关于星空的问题吧！"]
                .waitForExistence(timeout: 3)
        )
        assertSpotlightAlignsWithChatTextInput(in: app)
        app.buttons["下一步"].tap()

        XCTAssertTrue(
            app.staticTexts["也可以按住麦克风说出问题。第一次使用时需要授权麦克风权限。"]
                .waitForExistence(timeout: 2)
        )
        assertSpotlight(in: app, alignsWith: app.buttons["SpeechInputButton"])

        app.buttons["下一步"].tap()

        XCTAssertTrue(
            app.staticTexts["太棒啦！你已经学会了所有探索星空的方法。现在出发，去发现属于你的星星吧！"]
                .waitForExistence(timeout: 2),
            "语音输入教学后应该进入结尾鼓励步骤"
        )
        XCTAssertFalse(
            app.buttons["SpeechInputButton"].exists,
            "进入结尾步骤前应该关闭聊天面板"
        )
        XCTAssertFalse(
            app.otherElements["OnboardingSpotlight"].exists,
            "结尾步骤不应该显示聚光灯"
        )
        XCTAssertTrue(app.buttons["出发！"].waitForExistence(timeout: 2))
        app.buttons["出发！"].tap()
        XCTAssertFalse(
            app.staticTexts["太棒啦！你已经学会了所有探索星空的方法。现在出发，去发现属于你的星星吧！"].exists,
            "点击出发后应该结束新手引导"
        )
    }

    @MainActor
    func testBirdOnboardingBrowsesCardCollectionAndChatBeforeVoiceStep() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITestResetBirdOnboarding"]
        app.launch()

        XCTAssertTrue(app.buttons["开始"].waitForExistence(timeout: 5))
        app.buttons["开始"].tap()
        XCTAssertTrue(app.buttons["下一步"].waitForExistence(timeout: 2))
        app.buttons["下一步"].tap()
        XCTAssertTrue(app.buttons["下一步"].waitForExistence(timeout: 2))
        app.buttons["下一步"].tap()
        XCTAssertTrue(app.buttons["下一步"].waitForExistence(timeout: 2))
        app.buttons["下一步"].tap()
        XCTAssertTrue(app.buttons["下一步"].waitForExistence(timeout: 2))
        app.buttons["下一步"].tap()

        XCTAssertTrue(
            app.navigationBars["小小星官 · 图鉴"].waitForExistence(timeout: 2),
            "图鉴入口步骤点下一步后应该自动切到图鉴页"
        )
        XCTAssertTrue(
            app.staticTexts["这里是你的星宿图鉴。上方进度环显示收集进度，在星图中点亮星宿就能解锁卡片。"]
                .waitForExistence(timeout: 2),
            "自动切到图鉴页后应该出现图鉴浏览教学"
        )

        app.buttons["下一步"].tap()

        XCTAssertTrue(
            app.staticTexts["遇到不懂的星名、故事或观测方法，可以点我提问。"]
                .waitForExistence(timeout: 2),
            "图鉴浏览完成后应该回到星图并进入星鸟助手步骤"
        )

        app.buttons["下一步"].tap()

        XCTAssertTrue(
            app.staticTexts["在下方输入框输入问题，也可以点击上方的快捷提问按钮。试着问一个关于星空的问题吧！"]
                .waitForExistence(timeout: 2),
            "打开聊天后应该先进入文字输入和快捷提问教学"
        )
        XCTAssertTrue(
            app.buttons["SpeechInputButton"].waitForExistence(timeout: 2),
            "聊天教学时聊天面板应该保持打开"
        )

        app.buttons["关闭"].tap()
        XCTAssertTrue(
            app.staticTexts["在下方输入框输入问题，也可以点击上方的快捷提问按钮。试着问一个关于星空的问题吧！"]
                .waitForExistence(timeout: 1),
            "chatExplore 期间关闭按钮不应该关闭聊天面板"
        )

        app.buttons["下一步"].tap()

        XCTAssertTrue(
            app.staticTexts["也可以按住麦克风说出问题。第一次使用时需要授权麦克风权限。"]
                .waitForExistence(timeout: 2),
            "聊天探索后应该进入语音输入教学"
        )
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
