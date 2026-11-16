import Foundation
import Observation

/// AI 服务商配置。
///
/// 两条约束（与 hearth 一致）：
/// 1. 密钥只进钥匙串，不回显到输入框，也不进入 iCloud 备份。
/// 2. 端点与模型是公开偏好，存 UserDefaults；密钥是否已配置只暴露布尔值。
@Observable
final class AISettings {
    enum Preset: String, CaseIterable, Identifiable {
        case deepSeek
        case custom

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .deepSeek: return "DeepSeek"
            case .custom: return "自建 / 兼容端点"
            }
        }

        var defaultBaseURL: String {
            switch self {
            case .deepSeek: return "https://api.deepseek.com"
            case .custom: return ""
            }
        }

        var defaultModel: String {
            switch self {
            case .deepSeek: return "deepseek-chat"
            case .custom: return ""
            }
        }
    }

    var preset: Preset {
        didSet { UserDefaults.standard.set(preset.rawValue, forKey: "ai.preset") }
    }

    var baseURLString: String {
        didSet { UserDefaults.standard.set(baseURLString, forKey: "ai.baseURL") }
    }

    var model: String {
        didSet { UserDefaults.standard.set(model, forKey: "ai.model") }
    }

    init() {
        let defaults = UserDefaults.standard
        self.preset = Preset(rawValue: defaults.string(forKey: "ai.preset") ?? "") ?? .deepSeek
        self.baseURLString = defaults.string(forKey: "ai.baseURL") ?? Preset.deepSeek.defaultBaseURL
        self.model = defaults.string(forKey: "ai.model") ?? Preset.deepSeek.defaultModel

        if baseURLString.isEmpty {
            baseURLString = preset.defaultBaseURL
        }
        if model.isEmpty {
            model = preset.defaultModel
        }
    }

    // MARK: - 密钥

    var hasAPIKey: Bool {
        guard let key = KeychainStore.read() else { return false }
        return !key.isEmpty
    }

    func saveAPIKey(_ key: String) throws {
        try KeychainStore.save(key.trimmingCharacters(in: .whitespaces))
    }

    func deleteAPIKey() {
        KeychainStore.delete()
    }

    // MARK: - 构建请求配置

    /// 组装一次对话所需的 AIConfig；缺密钥或地址不合法时返回 nil。
    func makeConfig() -> AIConfig? {
        guard hasAPIKey,
              let url = URL(string: baseURLString),
              url.scheme == "https" || url.scheme == "http",
              let key = KeychainStore.read(),
              !model.trimmingCharacters(in: .whitespaces).isEmpty
        else { return nil }

        return AIConfig(baseURL: baseURLString, model: model, apiKey: key)
    }

    /// 校验连通性：拉取模型列表。密钥是否有效，一次请求即可确认。
    func verify() async -> Result<[String], Error> {
        guard let config = makeConfig() else {
            return .failure(AIError.notConfigured)
        }
        do {
            let models = try await OpenAIClient().models(config: config)
            return .success(models)
        } catch {
            return .failure(error)
        }
    }
}
