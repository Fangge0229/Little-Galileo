import Foundation

struct AIProvider: Equatable {
    let name: String
    let baseURL: String
    let apiKey: String
    let model: String

    static let zhipu = AIProvider(
        name: "智谱AI",
        baseURL: "https://open.bigmodel.cn/api/paas/v4",
        apiKey: "",
        model: "glm-4-flash"
    )

    static let deepseek = AIProvider(
        name: "DeepSeek",
        baseURL: "https://api.deepseek.com",
        apiKey: "",
        model: "deepseek-chat"
    )

    static let alibaba = AIProvider(
        name: "通义千问",
        baseURL: "https://dashscope.aliyuncs.com/compatible-mode/v1",
        apiKey: "",
        model: "qwen-turbo"
    )

    static let siliconflow = AIProvider(
        name: "硅基流动",
        baseURL: "https://api.siliconflow.cn/v1",
        apiKey: "",
        model: "deepseek-ai/DeepSeek-V3"
    )

    static let moonshot = AIProvider(
        name: "Kimi",
        baseURL: "https://api.moonshot.cn/v1",
        apiKey: "",
        model: "moonshot-v1-8k"
    )

    static var appDefault: AIProvider {
        loadBundledLocalConfiguration() ?? .zhipu
    }

    static func loadBundledLocalConfiguration(
        bundle: Bundle = .main,
        fileName: String = "AIProviderConfig.local"
    ) -> AIProvider? {
        guard let url = bundle.url(forResource: fileName, withExtension: "json") else {
            return nil
        }

        return try? loadLocalConfiguration(from: url)
    }

    static func loadLocalConfiguration(from url: URL) throws -> AIProvider {
        let data = try Data(contentsOf: url)
        let config = try JSONDecoder().decode(LocalConfiguration.self, from: data)
        return AIProvider(
            name: config.name,
            baseURL: config.baseURL,
            apiKey: config.apiKey,
            model: config.model
        )
    }
}

private struct LocalConfiguration: Decodable {
    let name: String
    let baseURL: String
    let apiKey: String
    let model: String
}

protocol ChatServiceTransport {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: ChatServiceTransport {
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await data(for: request, delegate: nil)
    }
}

protocol ChatServing {
    func send(messages: [ChatMessage]) async throws -> String
}

final class ChatService: ChatServing {
    private let provider: AIProvider
    private let transport: ChatServiceTransport
    private let systemPrompt: String

    init(
        provider: AIProvider,
        transport: ChatServiceTransport = URLSession.shared,
        systemPrompt: String = ChatService.defaultSystemPrompt
    ) {
        self.provider = provider
        self.transport = transport
        self.systemPrompt = systemPrompt
    }

    func send(messages: [ChatMessage]) async throws -> String {
        let apiKey = provider.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !apiKey.isEmpty else {
            throw ChatError.missingAPIKey
        }

        guard let url = chatCompletionsURL else {
            throw ChatError.invalidProviderURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            RequestBody(
                model: provider.model,
                messages: buildAPIMessages(from: messages),
                stream: false
            )
        )

        let (data, response) = try await transport.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "未知错误"
            throw ChatError.apiError(statusCode: httpResponse.statusCode, message: message)
        }

        let result = try JSONDecoder().decode(CompletionResponse.self, from: data)
        guard let content = result.choices.first?.message.content,
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ChatError.emptyResponse
        }

        return content
    }

    func sendStream(
        messages: [ChatMessage],
        onToken: @escaping (String) -> Void
    ) async throws {
        let reply = try await send(messages: messages)
        onToken(reply)
    }

    private var chatCompletionsURL: URL? {
        let base = provider.baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return URL(string: "\(base)/chat/completions")
    }

    private func buildAPIMessages(from messages: [ChatMessage]) -> [APIMessage] {
        let recentMessages = messages.filter { $0.role != .system }.suffix(20)
        return [APIMessage(role: "system", content: systemPrompt)] + recentMessages.map {
            APIMessage(role: $0.role.rawValue, content: $0.content)
        }
    }
}

enum ChatError: LocalizedError, Equatable {
    case missingAPIKey
    case invalidProviderURL
    case invalidResponse
    case emptyResponse
    case apiError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "还没有配置 AI API Key"
        case .invalidProviderURL:
            return "AI 接口地址无效"
        case .invalidResponse:
            return "网络请求失败"
        case .emptyResponse:
            return "AI 没有返回内容"
        case .apiError(let statusCode, let message):
            return "接口错误(\(statusCode))：\(message)"
        }
    }
}

private extension ChatService {
    static let defaultSystemPrompt = """
    你是“小小星官”App 里的天文助手，面向 6-12 岁的小朋友。
    你了解中国传统星宿（三垣二十八宿）和西方星座，擅长用生动有趣的语言讲解星空知识。
    回答要简短（100字以内），用小朋友能听懂的话，可以适当用比喻。
    如果用户问的不是天文相关的问题，友善地引导回星空话题。
    """
}

private struct RequestBody: Encodable {
    let model: String
    let messages: [APIMessage]
    let stream: Bool
}

private struct APIMessage: Codable {
    let role: String
    let content: String
}

private struct CompletionResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: APIMessage
    }
}
