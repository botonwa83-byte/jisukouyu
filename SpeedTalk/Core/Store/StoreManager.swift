import Foundation
import StoreKit

/// 会员权益（内购）：iOS 单一「非消耗型」买断，一次付费永久解锁完整版。
///
/// 与 wordpulse 同款模式：
/// - 本地缓存秒开，启动后静默用 StoreKit 2 校准（重装 / 换机自动找回）
/// - 纯客户端校验，起步阶段够用；后期可加服务端收据验证
@MainActor
@Observable
final class StoreManager {
    static let shared = StoreManager()

    static let productID = "com.speedtalk.app.lifetime"
    static let priceFallback = "¥22"
    private static let cacheKey = "premiumOwned"

    private(set) var isPremium: Bool
    private(set) var price: String = StoreManager.priceFallback
    private(set) var loading = false
    private(set) var product: Product?

    private var updatesTask: Task<Void, Never>?

    private init() {
        let defaults = UserDefaults.standard
        isPremium = defaults.bool(forKey: Self.cacheKey)
        updatesTask = Task { [weak self] in
            await self?.listenForTransactions()
        }
        Task {
            await calibrate()
        }
    }

    // 单例常驻，Transaction.updates 监听随 App 生命周期存续，无需取消。

    /// 连接商店：拉商品价格 + 静默校准已购状态。
    func calibrate() async {
        do {
            let products = try await Product.products(for: [Self.productID])
            product = products.first
            if let price = product?.displayPrice {
                self.price = price
            }
        } catch {
            // 拉不到商店（离线/沙盒未配置）就用缓存与兜底价格
        }
        var owned = false
        for await entitlement in Transaction.currentEntitlements {
            if case .verified(let transaction) = entitlement,
               transaction.productID == Self.productID {
                owned = true
            }
        }
        setPremium(owned)
    }

    /// 发起购买；结果由交易监听统一收尾。
    func purchase() async {
        guard let product, !loading else { return }
        loading = true
        defer { loading = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    setPremium(true)
                    await transaction.finish()
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            // 用户取消或网络失败，保持原状态
        }
    }

    /// 恢复购买（重装 / 换机），返回是否找回。
    @discardableResult
    func restore() async -> Bool {
        loading = true
        defer { loading = false }
        do {
            try await AppStore.sync()
        } catch {
            // 同步失败继续读本地凭据
        }
        var owned = false
        for await entitlement in Transaction.currentEntitlements {
            if case .verified(let transaction) = entitlement,
               transaction.productID == Self.productID {
                owned = true
            }
        }
        setPremium(owned)
        return owned
    }

    private func listenForTransactions() async {
        for await update in Transaction.updates {
            if case .verified(let transaction) = update,
               transaction.productID == Self.productID {
                setPremium(true)
                await transaction.finish()
            }
        }
    }

    private func setPremium(_ owned: Bool) {
        isPremium = owned
        UserDefaults.standard.set(owned, forKey: Self.cacheKey)
    }
}
