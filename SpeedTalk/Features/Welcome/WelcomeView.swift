import SwiftUI
import SpeedTalkCore

/// 打开 App 的品牌首页：Logo + 卖点 + 数据 + 开发者介绍，点「立即开始学习」进入。
struct WelcomeView: View {
    @Environment(AppContainer.self) private var container
    let onStart: () -> Void

    @State private var appeared = false

    private let features: [(icon: String, title: String, desc: String)] = [
        ("🎤", "跟读评分 · 开口就知道", "语音识别逐词比对，发音差距看得见"),
        ("🗣️", "AI 对练 · 情景对话", "连接你自己的 AI，随时练口语对话"),
        ("💬", "场景句子 · 学了就能用", "生活、出行、职场等真实场景地道表达"),
        ("🔁", "记忆曲线 · 越练越牢", "说过的句子自动安排复习，告别背了就忘"),
        ("⚡", "速览模式 · 通勤神器", "零操作快速过句，时间紧也能天天进步"),
        ("🔒", "隐私优先 · 录音不留存", "录音只在本机评分，评完即删不上传"),
    ]

    private var phraseCount: Int { container.content.library.all.count }
    private var sceneCount: Int { SpeedTalkCore.Scene.allCases.count }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    logoSection
                    heroSection
                    featuresSection
                    statsSection
                    developerSection
                    footer
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 120)
                .centeredColumn()
            }
            .background(Theme.paper.ignoresSafeArea())

            startButton
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 24)
        .animation(.easeOut(duration: 0.5), value: appeared)
        .onAppear { appeared = true }
    }

    // MARK: - 区块

    private var logoSection: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(LinearGradient(colors: [Theme.accent, Theme.blush], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 84, height: 84)
                    .shadow(color: Theme.accent.opacity(0.35), radius: 14, y: 8)
                Text("说")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            }
            Text("极速口语")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)
            Text("让开口成为习惯")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 56)
    }

    private var heroSection: some View {
        VStack(spacing: 10) {
            Text("装上极速口语，练到敢开口")
                .font(.title3.weight(.bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text("场景句子 × 跟读评分 × AI 纠错\n每天 5 句，三分钟，开口说英语")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }

    private var featuresSection: some View {
        VStack(spacing: 12) {
            ForEach(features, id: \.title) { item in
                HStack(alignment: .center, spacing: 14) {
                    Text(item.icon)
                        .font(.title3)
                        .frame(width: 44, height: 44)
                        .background(Theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.title)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Theme.ink)
                        Text(item.desc)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .padding(16)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private var statsSection: some View {
        HStack(spacing: 0) {
            stat("\(phraseCount)+", "地道句子")
            divider
            stat("\(sceneCount)", "生活场景")
            divider
            stat("3 分钟", "每日任务")
        }
        .padding(.vertical, 20)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var divider: some View {
        Rectangle()
            .fill(Theme.ink.opacity(0.10))
            .frame(width: 1, height: 32)
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.weight(.heavy))
                .foregroundStyle(Theme.accent)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var developerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Theme.accent, Theme.blush], startPoint: .top, endPoint: .bottom))
                        .frame(width: 48, height: 48)
                    Text("K")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("King Top")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Theme.ink)
                    Text("独立开发者 / 教育科技探索者")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Text("专注教育类 App 开发。极速口语与 WordPulse 同系列，希望帮每一位学习者迈过「不敢开口」这道坎。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
            Text("更多教育应用，敬请期待")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.accent)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
        }
        .padding(20)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var footer: some View {
        VStack(spacing: 2) {
            Text("极速口语 v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
            Text("© 2024-2026 King Top. All rights reserved.")
        }
        .font(.caption2)
        .foregroundStyle(.tertiary)
        .frame(maxWidth: .infinity)
    }

    private var startButton: some View {
        Button(action: onStart) {
            Text("立即开始学习")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(Theme.accent, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Theme.accent.opacity(0.35), radius: 10, y: 5)
        }
        .accessibilityIdentifier("welcomeStart")
    }
}
