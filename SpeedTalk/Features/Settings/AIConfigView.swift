import SwiftUI
import SwiftData
import SpeedTalkCore

struct AIConfigView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var baseURL = "https://api.openai.com/v1"
    @State private var model = "gpt-4o-mini"
    @State private var apiKey = ""
    @State private var status = ""
    @State private var testing = false

    var body: some View {
        Form {
            Section("接口") {
                TextField("Base URL", text: $baseURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("模型", text: $model)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                SecureField("API Key", text: $apiKey)
            }

            Section {
                Button(testing ? "测试中…" : "保存并测试") { saveAndTest() }
                    .disabled(testing)
                if !status.isEmpty {
                    Text(status).font(.footnote).foregroundStyle(.secondary)
                }
            } footer: {
                Text("Key 只存在系统钥匙串。AI 只收到文本，不会收到你的录音。")
            }

            Section("今日额度") {
                let profile = profiles.first
                Text("已用 \(profile?.aiQuotaUsed ?? 0) / \(profile?.aiQuotaPerDay ?? 30) 次")
                    .font(.subheadline)
            }
        }
        .navigationTitle("AI 设置")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: load)
    }

    private func load() {
        let profile = profiles.first
        baseURL = profile?.aiBaseURL ?? baseURL
        model = profile?.aiModel ?? model
        apiKey = KeychainStore.read() ?? ""
    }

    private func saveAndTest() {
        let profile = profiles.first ?? {
            let created = UserProfile()
            modelContext.insert(created)
            return created
        }()
        profile.aiBaseURL = baseURL
        profile.aiModel = model
        KeychainStore.save(apiKey)
        try? modelContext.save()

        testing = true
        status = ""
        Task {
            do {
                try await OpenAIClient().ping(config: AIConfig(baseURL: baseURL, model: model, apiKey: apiKey))
                status = "连接成功，可以用了"
            } catch {
                status = (error as? LocalizedError)?.errorDescription ?? "连接失败，检查地址和 Key"
            }
            testing = false
        }
    }
}
