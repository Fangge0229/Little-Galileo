import SwiftUI

struct ChatPanelView: View {
    @EnvironmentObject private var chatStore: ChatStore
    @EnvironmentObject private var speechRecognizer: SpeechRecognizer
    @Binding var isPresented: Bool
    let canDismiss: Bool
    let bottomSafeArea: CGFloat
    let onSpeechInputTapped: () -> Void
    @State private var inputText = ""
    @State private var showSpeechAlert = false
    @FocusState private var isInputFocused: Bool

    init(
        isPresented: Binding<Bool>,
        canDismiss: Bool = true,
        bottomSafeArea: CGFloat = 0,
        onSpeechInputTapped: @escaping () -> Void = {}
    ) {
        self._isPresented = isPresented
        self.canDismiss = canDismiss
        self.bottomSafeArea = bottomSafeArea
        self.onSpeechInputTapped = onSpeechInputTapped
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()
                .overlay(Color.white.opacity(0.12))

            messagesList

            if let error = chatStore.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Color(hex: "FF8A8A"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }

            if speechRecognizer.isRecording, !speechRecognizer.transcript.isEmpty {
                Text(speechRecognizer.transcript)
                    .font(.caption)
                    .foregroundStyle(Color(hex: "B8C4E0"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }

            Divider()
                .overlay(Color.white.opacity(0.12))

            inputBar
        }
        .background(Color(hex: "0F1530"))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.45), radius: 22, y: -6)
        .alert("语音权限", isPresented: $showSpeechAlert) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text(speechRecognizer.errorMessage ?? "请在设置中开启语音权限")
        }
        .onDisappear {
            if speechRecognizer.isRecording {
                _ = speechRecognizer.stopRecording()
            }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color(hex: "FFD700"))

            Text("星空小助手")
                .font(.headline)
                .foregroundStyle(Color(hex: "FFF8E7"))

            if chatStore.isLoading {
                ProgressView()
                    .controlSize(.small)
                    .tint(Color(hex: "FFD700"))
            }

            Spacer()

            Button {
                chatStore.clearHistory()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color(hex: "B8C4E0"))
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("清空对话")
            .disabled(chatStore.messages.isEmpty && chatStore.errorMessage == nil)
            .opacity(chatStore.messages.isEmpty && chatStore.errorMessage == nil ? 0.35 : 1)

            Button {
                guard canDismiss else { return }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    isPresented = false
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.64))
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("关闭")
            .opacity(canDismiss ? 1 : 0.3)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if chatStore.messages.isEmpty {
                        welcomeView
                    }

                    ForEach(chatStore.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .onChange(of: chatStore.messages.count) { _ in
                scrollToLatest(with: proxy)
            }
            .onChange(of: chatStore.messages.last?.content) { _ in
                scrollToLatest(with: proxy)
            }
        }
    }

    private var welcomeView: some View {
        VStack(spacing: 12) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Color(hex: "FFD700"))

            VStack(spacing: 4) {
                Text("你好！我是星空小助手")
                    .font(.headline)
                    .foregroundStyle(Color(hex: "FFF8E7"))

                Text("有什么关于星星的问题，尽管问我吧！")
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: "B8C4E0"))
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 8) {
                quickQuestion("北斗七星为什么叫北斗？")
                quickQuestion("怎么找到北极星？")
                quickQuestion("织女星和牛郎星真的会相会吗？")
            }
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
    }

    private func quickQuestion(_ text: String) -> some View {
        Button {
            inputText = text
            sendMessage()
        } label: {
            Text(text)
                .font(.caption)
                .foregroundStyle(Color(hex: "4A90D9"))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color(hex: "4A90D9").opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(chatStore.isLoading)
    }

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField(
                "",
                text: $inputText,
                prompt: Text(inputPrompt).foregroundColor(Color(hex: "B8C4E0").opacity(0.7)),
                axis: .vertical
            )
                .lineLimit(1...4)
                .textFieldStyle(.plain)
                .foregroundStyle(Color(hex: "FFF8E7"))
                .tint(Color(hex: "FFD700"))
                .padding(.horizontal, 13)
                .padding(.vertical, 10)
                .background(Color(hex: "1E2140"))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .onboardingTarget(.chatTextInput)
                .accessibilityIdentifier("ChatTextInput")
                .focused($isInputFocused)
                .submitLabel(.send)
                .onSubmit {
                    sendMessage()
                }

            Button {
                onSpeechInputTapped()
                toggleRecording()
            } label: {
                Image(systemName: speechRecognizer.isRecording ? "mic.fill" : "mic")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(speechRecognizer.isRecording ? Color(hex: "FF6B6B") : Color(hex: "B8C4E0"))
                    .frame(width: 34, height: 34)
                    .background(
                        Circle()
                            .fill(speechRecognizer.isRecording ? Color(hex: "FF6B6B").opacity(0.16) : Color(hex: "1E2140"))
                    )
                    .scaleEffect(speechRecognizer.isRecording ? 1.12 : 1)
                    .animation(
                        speechRecognizer.isRecording
                        ? .easeInOut(duration: 0.7).repeatForever(autoreverses: true)
                        : .default,
                        value: speechRecognizer.isRecording
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(speechRecognizer.isRecording ? "停止录音" : "语音输入")
            .accessibilityIdentifier("SpeechInputButton")
            .onboardingTarget(.voiceInput)
            .disabled(chatStore.isLoading)

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(sendButtonColor)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("发送")
            .accessibilityIdentifier("ChatSendButton")
            .disabled(!canSend)
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 12 + bottomSafeArea)
        .background(Color(hex: "0F1530"))
    }

    private var canSend: Bool {
        !effectiveInputText.isEmpty && !chatStore.isLoading
    }

    private var sendButtonColor: Color {
        canSend ? Color(hex: "4A90D9") : Color(hex: "3A3A5C")
    }

    private var inputPrompt: String {
        if speechRecognizer.isRecording {
            return speechRecognizer.transcript.isEmpty ? "正在听你说..." : speechRecognizer.transcript
        }
        return "问点星空的事儿..."
    }

    private var effectiveInputText: String {
        let typedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !typedText.isEmpty { return typedText }
        return speechRecognizer.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func toggleRecording() {
        if speechRecognizer.isRecording {
            let text = speechRecognizer.stopRecording().trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                inputText = text
            }
        } else {
            Task {
                await speechRecognizer.startRecording()
                if speechRecognizer.errorMessage != nil {
                    showSpeechAlert = true
                }
            }
        }
    }

    private func sendMessage() {
        if speechRecognizer.isRecording {
            let recognizedText = speechRecognizer.stopRecording().trimmingCharacters(in: .whitespacesAndNewlines)
            if inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                inputText = recognizedText
            }
        }

        let text = effectiveInputText
        guard !text.isEmpty, !chatStore.isLoading else { return }
        inputText = ""

        Task {
            await chatStore.send(text)
        }
    }

    private func scrollToLatest(with proxy: ScrollViewProxy) {
        guard let lastID = chatStore.messages.last?.id else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo(lastID, anchor: .bottom)
        }
    }
}

private struct MessageBubble: View {
    @EnvironmentObject private var speechSynthesizer: SpeechSynthesizer
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom) {
            if message.role == .user {
                Spacer(minLength: 58)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
                Text(message.content.isEmpty ? "思考中..." : message.content)
                    .font(.subheadline)
                    .foregroundStyle(foregroundColor)
                    .lineSpacing(2)
                    .multilineTextAlignment(message.role == .user ? .trailing : .leading)

                if message.role == .assistant && !message.content.isEmpty {
                    HStack {
                        Spacer(minLength: 0)
                        Button {
                            toggleSpeaking()
                        } label: {
                            Image(systemName: isSpeakingThisMessage ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color(hex: "FFD700"))
                                .frame(width: 26, height: 22)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(isSpeakingThisMessage ? "停止朗读" : "朗读回复")
                        .accessibilityIdentifier("SpeechPlaybackButton")
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(message.content.isEmpty ? 0.65 : 1)

            if message.role == .assistant {
                Spacer(minLength: 58)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var foregroundColor: Color {
        message.role == .user ? Color(hex: "FFF8E7") : Color(hex: "E8EAF0")
    }

    private var backgroundColor: Color {
        message.role == .user ? Color(hex: "4A90D9") : Color(hex: "1E2140")
    }

    private var isSpeakingThisMessage: Bool {
        speechSynthesizer.isSpeaking && speechSynthesizer.speakingMessageID == message.id
    }

    private func toggleSpeaking() {
        if isSpeakingThisMessage {
            speechSynthesizer.stop()
        } else {
            speechSynthesizer.speak(message.content, messageID: message.id)
        }
    }
}

#Preview {
    ChatPanelView(isPresented: .constant(true))
        .environmentObject(ChatStore(provider: .zhipu))
        .environmentObject(SpeechRecognizer())
        .environmentObject(SpeechSynthesizer())
        .padding()
        .background(Color(hex: "0A0E27"))
}
