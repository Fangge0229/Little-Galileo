import Foundation

@MainActor
final class ChatStore: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var chatService: ChatServing

    init(provider: AIProvider) {
        self.chatService = ChatService(provider: provider)
    }

    init(service: ChatServing) {
        self.chatService = service
    }

    func switchProvider(_ provider: AIProvider) {
        chatService = ChatService(provider: provider)
    }

    func send(_ text: String) async {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty, !isLoading else { return }

        let userMessage = ChatMessage(role: .user, content: trimmedText)
        messages.append(userMessage)
        isLoading = true
        errorMessage = nil

        do {
            let reply = try await chatService.send(messages: messages)
            messages.append(ChatMessage(role: .assistant, content: reply))
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func clearHistory() {
        messages.removeAll()
        errorMessage = nil
    }
}
