import SwiftUI
import SwiftData
import SpeedTalkCore

/// AI 服务商设置，结构对齐 hearth：
/// 服务商预设一键填充 → 密钥只写不回显 → 独立验证连通性（拉模型列表）。
struct AIConfigView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var settings = AISettings()
    @State private var apiKey = ""
    @State private var verifiedModels: [String] = []
    @State private var verificationMessage: String?
    @State private var verificationFailed = false
    @State private var isVerifying = false

    var body: some View {
        Form {
            Section {
                Picker("服务商", selection: presetBinding) {
                    ForEach(AISettings.Preset.allCases) { preset in
                        Text(preset.displayName).tag(preset)
                    }
                }
                TextField("端点地址", text: $settings.baseURLString)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                TextField("模型", text: $settings.model)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } header: {
                Text("服务商")
            } footer: {
                Text("任意 OpenAI 兼容端点均可。换预设会自动填入默认端点和模型。")
            }

            Section {
                SecureField(settings.hasAPIKey ? "已保存，输入新的可覆盖" : "粘贴你的密钥", text: $apiKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                HStack(spacing: 12) {
                    Button("保存密钥") { saveKey() }
                        .disabled(apiKey.trimmingCharacters(in: .whitespaces).isEmpty)

                    Spacer()

                    if settings.hasAPIKey {
                        Button("删除", role: .destructive) {
                            settings.deleteAPIKey()
                            apiKey = ""
                            clearVerification()
                        }
                    }
                }

                Button {
                    Task { await verify() }
                } label: {
                    if isVerifying {
                        ProgressView()
                    } else {
                        Label("验证连通性", systemImage: "checkmark.seal")
                    }
                }
                .disabled(!settings.hasAPIKey || isVerifying)

                if let verificationMessage {
                    Label(verificationMessage, systemImage: verificationFailed ? "xmark.circle.fill" : "checkmark.circle.fill")
                        .font(.footnote)
                        .foregroundStyle(verificationFailed ? Theme.danger : Theme.positive)
                }

                if !verifiedModels.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("可用模型（前 6 个）")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ForEach(verifiedModels.prefix(6), id: \.self) { name in
                            Text(name)
                                .font(.caption.monospaced())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Theme.blush.opacity(0.18), in: Capsule())
                        }
                    }
                }
            } header: {
                Text("密钥")
            } footer: {
                Text("Key 只存在本机钥匙串（不进 iCloud 备份），已保存的不会回显。验证时只拉模型列表，不消耗对话额度。AI 只收到文本，不会收到你的录音。")
            }

            Section("今日额度") {
                let profile = profiles.first
                Text("已用 \(profile?.aiQuotaUsed ?? 0) / \(profile?.aiQuotaPerDay ?? 30) 次")
                    .font(.subheadline)
            }
        }
        .warmList()
        .navigationTitle("AI 设置")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var presetBinding: Binding<AISettings.Preset> {
        Binding(
            get: { settings.preset },
            set: { newValue in
                settings.preset = newValue
                settings.baseURLString = newValue.defaultBaseURL
                settings.model = newValue.defaultModel
                clearVerification()
            }
        )
    }

    // MARK: - 动作

    private func saveKey() {
        do {
            try settings.saveAPIKey(apiKey)
            apiKey = ""
            clearVerification()
        } catch {
            verificationFailed = true
            verificationMessage = error.localizedDescription
        }
    }

    private func verify() async {
        isVerifying = true
        defer { isVerifying = false }
        let result = await settings.verify()
        switch result {
        case .success(let models):
            verifiedModels = models
            verificationFailed = false
            verificationMessage = "连接成功"
        case .failure(let error):
            clearVerification()
            verificationFailed = true
            verificationMessage = error.localizedDescription
        }
    }

    private func clearVerification() {
        verifiedModels = []
        verificationMessage = nil
        verificationFailed = false
    }
}
