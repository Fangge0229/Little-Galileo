import Foundation

@MainActor
final class OnboardingStore: ObservableObject {
    private static let completionKey = "hasCompletedBirdOnboarding.v2"
    private let defaults: UserDefaults

    @Published private(set) var isActive = false
    @Published private(set) var currentStep: OnboardingStep = .welcome

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    #if DEBUG
    static func resetCompletionForDebugLaunch(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: completionKey)
    }

    static func resetCompletionForUITestsIfRequested(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        defaults: UserDefaults = .standard
    ) {
        guard arguments.contains("UITestResetBirdOnboarding") else { return }
        resetCompletionForDebugLaunch(defaults: defaults)
    }

    static func completeForUITestsIfRequested(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        defaults: UserDefaults = .standard
    ) {
        guard arguments.contains("UITestCompleteBirdOnboarding") else { return }
        defaults.set(true, forKey: completionKey)
    }
    #endif

    var hasCompleted: Bool {
        defaults.bool(forKey: Self.completionKey)
    }

    func startIfNeeded() {
        guard !hasCompleted else { return }
        currentStep = .welcome
        isActive = true
        log("onboarding_started")
    }

    func completeCurrentStep() {
        complete(currentStep)
    }

    func complete(_ step: OnboardingStep) {
        guard isActive, currentStep == step else { return }
        log("onboarding_step_completed:\(step.rawValue)")

        guard let next = step.nextInFirstVersion else {
            finish(event: "onboarding_completed")
            return
        }

        currentStep = next
    }

    func skip() {
        finish(event: "onboarding_skipped")
    }

    func restart() {
        defaults.set(false, forKey: Self.completionKey)
        currentStep = .welcome
        isActive = true
        log("onboarding_started")
    }

    private func finish(event: String) {
        defaults.set(true, forKey: Self.completionKey)
        isActive = false
        currentStep = .welcome
        log(event)
    }

    private func log(_ event: String) {
        #if DEBUG
        print("[Onboarding] \(event)")
        #endif
    }
}

enum OnboardingStep: String, CaseIterable, Identifiable {
    case welcome
    case skyGesture
    case modeSwitch
    case starTap
    case tonightRecommendation
    case tonightBrowse
    case cardCollection
    case cardCollectionBrowse
    case assistantEntry
    case chatExplore
    case voiceInput
    case farewell

    var id: String { rawValue }

    static let firstVersionSteps: [OnboardingStep] = [
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
    ]

    var nextInFirstVersion: OnboardingStep? {
        guard let index = Self.firstVersionSteps.firstIndex(of: self) else { return nil }
        let nextIndex = Self.firstVersionSteps.index(after: index)
        guard nextIndex < Self.firstVersionSteps.endIndex else { return nil }
        return Self.firstVersionSteps[nextIndex]
    }

    var message: String {
        switch self {
        case .welcome:
            return "你好，我是星空小助手。让我带你认识今晚的星空。"
        case .skyGesture:
            return "拖动星图可以转动天空，双指缩放可以看近一点。"
        case .modeSwitch:
            return "这里可以在中国星宿和现代星座之间切换。"
        case .starTap:
            return "点亮的星官可以打开介绍，里面有故事和观测提示。"
        case .tonightRecommendation:
            return "不知道先看哪颗星？点击下方「今晚推荐」打开推荐面板。"
        case .tonightBrowse:
            return "左右滑动可以查看今晚推荐的星宿。看完后点击空白处或关闭按钮退出推荐面板。"
        case .cardCollection:
            return "点击下方「图鉴」可以查看你收集到的重点星官卡片。"
        case .cardCollectionBrowse:
            return "这里是你的 38 个重点星官图鉴。上方进度环显示收集进度，在星图中点亮星官就能解锁卡片。"
        case .assistantEntry:
            return "遇到不懂的星名、故事或观测方法，可以点我提问。"
        case .chatExplore:
            return "在下方输入框输入问题，也可以点击上方的快捷提问按钮。试着问一个关于星空的问题吧！"
        case .voiceInput:
            return "也可以按住麦克风说出问题。第一次使用时需要授权麦克风权限。"
        case .farewell:
            return "太棒啦！你已经学会了所有探索星空的方法。现在出发，去发现属于你的星星吧！"
        }
    }

    var primaryButtonTitle: String {
        switch self {
        case .welcome:
            return "开始"
        case .farewell:
            return "出发！"
        default:
            return "下一步"
        }
    }
}
