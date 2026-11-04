import Foundation

struct WordIssue: Decodable, Hashable {
    let word: String
    let issue: String
    let fix: String
}

struct PronunciationReview: Decodable {
    let summary: String
    let tips: [String]
    let wordIssues: [WordIssue]
    let betterSayings: [String]
}

struct ChatMessage: Identifiable, Hashable {
    enum Role: String {
        case user, assistant
    }

    let id = UUID()
    let role: Role
    var text: String
}

enum TalkScene: String, CaseIterable, Identifiable {
    case coffee, interview, directions, smallTalk, complaint, clinic

    var id: String { rawValue }

    var title: String {
        switch self {
        case .coffee: return "咖啡店点单"
        case .interview: return "面试开场"
        case .directions: return "问路"
        case .smallTalk: return "同事闲聊"
        case .complaint: return "餐厅投诉"
        case .clinic: return "看医生"
        }
    }

    var symbol: String {
        switch self {
        case .coffee: return "cup.and.saucer"
        case .interview: return "person.badge.key"
        case .directions: return "map"
        case .smallTalk: return "bubble.left.and.bubble.right"
        case .complaint: return "exclamationmark.bubble"
        case .clinic: return "cross.case"
        }
    }

    var rolePrompt: String {
        switch self {
        case .coffee:
            return "You are a friendly barista at a busy US coffee shop. Take the customer's order, ask about size and milk, keep it short."
        case .interview:
            return "You are a hiring manager at a US company interviewing a candidate. Ask one simple opening question at a time, stay encouraging."
        case .directions:
            return "You are a local person on the street in the US. Give short, natural directions and ask a clarifying question if needed."
        case .smallTalk:
            return "You are a friendly American coworker making small talk by the coffee machine. Keep it light and casual."
        case .complaint:
            return "You are a restaurant manager handling a polite complaint. Apologize, offer a concrete fix, stay professional."
        case .clinic:
            return "You are a nurse at a US clinic front desk. Ask about symptoms and insurance, keep it plain and calm."
        }
    }
}

extension TalkScene {
    var opener: String {
        switch self {
        case .coffee: return "Hi! What can I get for you?"
        case .interview: return "Tell me about yourself."
        case .directions: return "Need help finding something?"
        case .smallTalk: return "Morning! How's your week going?"
        case .complaint: return "Hi, how is everything tasting?"
        case .clinic: return "Hi, what brings you in today?"
        }
    }
}

struct AIConfig {
    var baseURL: String
    var model: String
    var apiKey: String

    var isUsable: Bool {
        !baseURL.trimmingCharacters(in: .whitespaces).isEmpty
        && !model.trimmingCharacters(in: .whitespaces).isEmpty
        && !apiKey.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

enum AIError: LocalizedError {
    case notConfigured
    case badResponse
    case http(Int)
    case offline

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "还没填 API Key，去设置里填一下"
        case .badResponse: return "AI 回的内容没读懂，再试一次"
        case .http(let code) where code == 401 || code == 403: return "Key 无效或没有权限，检查设置"
        case .http(let code) where code == 429: return "请求太频繁，等一会儿再试"
        case .http(let code): return "服务异常（\(code)），稍后再试"
        case .offline: return "网络没连上，检查一下再试"
        }
    }
}

final class OpenAIClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func review(config: AIConfig, target: String, transcript: String, ipa: String) async throws -> PronunciationReview {
        let system = """
        You are a pronunciation coach for Chinese learners of American English.
        Return STRICT JSON only, no markdown, with this shape:
        {"summary":"one sentence in Chinese","tips":["tip in Chinese", "..."],
         "wordIssues":[{"word":"english word","issue":"what is wrong, in Chinese","fix":"how to fix, in Chinese"}],
         "betterSayings":["more natural American alternative in English"]}
        Keep tips to at most 3 items. Only comment on what is actually wrong.
        """
        let user = """
        Target sentence: \(target)
        Target IPA: \(ipa)
        Learner said (speech-to-text): \(transcript)
        """
        let content = try await chat(config: config, system: system, user: user, jsonMode: true)
        guard let data = content.data(using: .utf8) else { throw AIError.badResponse }
        return try JSONDecoder().decode(PronunciationReview.self, from: data)
    }

    func reply(config: AIConfig, scene: TalkScene, messages: [ChatMessage]) async throws -> String {
        let system = """
        \(scene.rolePrompt)
        You are also a patient English coach for a Chinese learner.
        Reply in English only, 1-2 short sentences, then end with a short question to keep the conversation going.
        Never use markdown.
        """
        let history = messages.map { "\($0.role == .user ? "Learner" : "You"): \($0.text)" }
            .joined(separator: "\n")
        return try await chat(config: config, system: system, user: history, jsonMode: false)
    }

    func ping(config: AIConfig) async throws {
        _ = try await chat(config: config, system: "Reply with OK only.", user: "ping", jsonMode: false)
    }

    private func chat(config: AIConfig, system: String, user: String, jsonMode: Bool) async throws -> String {
        guard config.isUsable else { throw AIError.notConfigured }
        let trimmed = config.baseURL.hasSuffix("/") ? String(config.baseURL.dropLast()) : config.baseURL
        guard let url = URL(string: trimmed + "/chat/completions") else { throw AIError.badResponse }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")

        var body: [String: Any] = [
            "model": config.model,
            "temperature": jsonMode ? 0.2 : 0.7,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": user]
            ]
        ]
        if jsonMode {
            body["response_format"] = ["type": "json_object"]
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw AIError.offline
        }
        guard let http = response as? HTTPURLResponse else { throw AIError.badResponse }
        guard (200..<300).contains(http.statusCode) else { throw AIError.http(http.statusCode) }

        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = root["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String
        else { throw AIError.badResponse }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
