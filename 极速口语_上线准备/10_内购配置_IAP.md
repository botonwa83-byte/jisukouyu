# 内购配置 IAP

买断模式：一次性 ¥22，永久解锁完整版。与 wordpulse 同款。

## 一、ASC 后台配置

1. App Store Connect → 你的 App → 「App 内购买项目」→ 新增
2. 类型：**非消耗型（Non-Consumable）**
3. 产品 ID：`com.speedtalk.app.lifetime`
4. 参考名称：`终身完整版`
5. 价格：**¥22 档**
6. 本地化（简体中文）：
   - 名称：`终身完整版`
   - 描述：`一次买断，永久解锁全部 8 场景、AI 对练与点评、无限续学`

## 二、随版本提交（关键）

在 App 的版本页里，把该内购**勾选随版本一起提交**，否则审核时内购不可用会被拒。

## 三、App 内对应关系

| 项 | 值 |
|---|---|
| 产品 ID | `StoreManager.productID` = `com.speedtalk.app.lifetime` |
| 兜底价格 | `StoreManager.priceFallback` = `¥22`（拉不到商店时展示） |
| 类型 | StoreKit 2 非消耗型 |
| 解锁判断 | `Transaction.currentEntitlements`（Apple ID 绑定） |
| 恢复购买 | `AppStore.sync()` |
| 本地缓存 | UserDefaults key `premiumOwned` |

## 四、付费门禁（免费版范围）

| 功能 | 免费 | 完整版 |
|---|---|---|
| 「生活」场景 | ✅ | ✅ |
| 其余 7 场景（出行/餐饮/职场/校园/社交/应急/地道表达） | ❌ 锁 + 弹付费墙 | ✅ |
| AI 精细点评 | ❌ | ✅ |
| AI 对练（对练 Tab） | ❌ | ✅ |
| 无限续学 / 速览 | ✅ | ✅（暂无额外限制） |

## 五、测试步骤

**沙盒（模拟器）**
1. 挂 `SpeedTalk.storekit`：Product → Scheme → Edit Scheme → Run → Options → StoreKit Configuration 选 `SpeedTalk.storekit`
2. 沙盒账号：Settings → App Store → Sandbox Account 登录测试账号
3. 验证：购买后解锁、恢复购买、取消不扣费、免费版只开放「生活」场景

**真机 / TestFlight**
1. 用 TestFlight 内测组，或真机 + 沙盒账号
2. 走一遍：购买 → 解锁 → 删除重装 → 恢复购买
