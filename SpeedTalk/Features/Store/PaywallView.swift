import SwiftUI

/// 付费墙：一次买断，永久解锁完整版。可从「我的」主动进入，也可在功能门禁处弹出。
struct PaywallView: View {
    @Environment(StoreManager.self) private var store
    @Environment(\.dismiss) private var dismiss

    /// 门禁处弹出的功能名，用于定制标题。
    var feature: String?

    private let benefits: [(icon: String, title: String, desc: String)] = [
        ("🌍", "解锁全部 8 大场景", "免费版含「生活」场景，其余出行/餐饮/职场/校园/社交/应急/地道表达全部开放"),
        ("🗣️", "AI 对练不限次", "情景对话随便练，开口机会翻倍"),
        ("✨", "AI 精细点评", "逐句发音纠正，说得地道才罢休"),
        ("⚡", "无限速览与续学", "不限每日推进，想学多少学多少"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    hero
                    benefitsCard
                    if store.isPremium {
                        ownedCard
                    } else {
                        priceCard
                        buyButton
                        restoreButton
                    }
                    legalText
                }
                .padding(20)
                .centeredColumn()
            }
            .background(Theme.paper.ignoresSafeArea())
            .navigationTitle("完整版")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }

    private var headline: String {
        if let feature { return "「\(feature)」是完整版功能" }
        return "解锁极速口语完整版"
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("完整版")
                .font(.caption.weight(.heavy))
                .foregroundStyle(Theme.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Theme.accent.opacity(0.12), in: Capsule())
            Text(headline)
                .font(.title2.weight(.heavy))
                .foregroundStyle(Theme.ink)
            Text("一次购买，永久使用 · 非订阅")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }

    private var benefitsCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(benefits, id: \.title) { item in
                HStack(alignment: .top, spacing: 14) {
                    Text(item.icon)
                        .font(.title3)
                        .frame(width: 30)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.title)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Theme.ink)
                        Text(item.desc)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var priceCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("终身买断")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.ink)
                Text("一次付费，永久解锁")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(store.price)
                .font(.title2.weight(.heavy))
                .foregroundStyle(Theme.accent)
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .background(Theme.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var buyButton: some View {
        Button {
            Task { await store.purchase() }
        } label: {
            HStack(spacing: 8) {
                if store.loading {
                    ProgressView().tint(.white)
                } else if store.product == nil {
                    Text("内购暂不可用 · 正在连接商店…")
                } else {
                    Text("立即解锁 · \(store.price)")
                }
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(store.product == nil ? Theme.ink.opacity(0.35) : Theme.accent, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .disabled(store.loading || store.product == nil)
        .accessibilityIdentifier("paywallBuy")
    }

    private var restoreButton: some View {
        Button {
            Task {
                let owned = await store.restore()
                if !owned {
                    restoreFailed = true
                }
            }
        } label: {
            Text("恢复购买")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .accessibilityIdentifier("paywallRestore")
        .alert("未找到购买记录", isPresented: $restoreFailed) {
            Button("好", role: .cancel) {}
        } message: {
            Text("该 Apple ID 下没有可恢复的购买记录")
        }
    }

    @State private var restoreFailed = false

    private var ownedCard: some View {
        VStack(spacing: 4) {
            Text("✓ 已是完整版用户")
                .font(.headline)
                .foregroundStyle(Theme.positive)
            Text("感谢支持，所有功能已为你解锁")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Theme.positive.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var legalText: some View {
        Text("通过 App Store 完成支付。购买后永久解锁完整版功能，非订阅、无自动续费。更换设备可在「恢复购买」中找回。隐私政策与用户协议见设置页。")
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .lineSpacing(3)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
    }
}
