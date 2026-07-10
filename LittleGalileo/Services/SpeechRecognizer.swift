import AVFoundation
import Speech

@MainActor
final class SpeechRecognizer: ObservableObject {
    @Published var transcript = ""
    @Published var isRecording = false
    @Published var errorMessage: String?

    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    private var hasInputTap = false

    func requestAuthorization() async -> Bool {
        async let speechAllowed = requestSpeechAuthorization()
        async let microphoneAllowed = requestMicrophoneAuthorization()
        let allowed = await (speechAllowed, microphoneAllowed)
        let isAuthorized = allowed.0 && allowed.1
        if !isAuthorized {
            errorMessage = "请在设置中开启语音权限"
        }
        return isAuthorized
    }

    func startRecording() async {
        guard !isRecording else { return }
        guard await requestAuthorization() else { return }
        guard speechRecognizer?.isAvailable == true else {
            errorMessage = "当前语音识别不可用"
            return
        }

        stopAudio(cancelTask: true)
        transcript = ""
        errorMessage = nil

        do {
            try configureAudioSession()
            try startAudioRecognition()
            isRecording = true
        } catch {
            stopAudio(cancelTask: true)
            errorMessage = "语音识别启动失败"
        }
    }

    func stopRecording() -> String {
        let finalText = transcript
        stopAudio(cancelTask: true)
        transcript = ""
        return finalText
    }

    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .duckOthers])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }

    private func startAudioRecognition() throws {
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak request] buffer, _ in
            request?.append(buffer)
        }
        hasInputTap = true

        audioEngine.prepare()
        try audioEngine.start()

        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    self.transcript = result.bestTranscription.formattedString
                }
                if error != nil {
                    self.stopAudio(cancelTask: false)
                    self.errorMessage = "语音识别中断，请重试"
                }
            }
        }
    }

    private func stopAudio(cancelTask: Bool) {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        if hasInputTap {
            audioEngine.inputNode.removeTap(onBus: 0)
            hasInputTap = false
        }
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        if cancelTask {
            recognitionTask?.cancel()
        }
        recognitionTask = nil
        isRecording = false
    }

    private func requestSpeechAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    private func requestMicrophoneAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                continuation.resume(returning: allowed)
            }
        }
    }
}
