# iPad 适配测试报告

测试日期：2026-11-16 · 设备：iPad Air 11-inch (M4) 模拟器 · 版本 1.9 (11)

## 结论

App 已支持 iPad（TARGETED_DEVICE_FAMILY = 1,2），可随 iPhone 版本一起上架，无需单建 iPad 应用。

## 测试项与结果

| 项目 | 结果 |
|---|---|
| 工程配置 DEVICE_FAMILY 1,2 | ✅ |
| iPad 四向旋转声明 | ✅ |
| 侧边栏导航（iPadOS 自动） | ✅ 五个入口可点，高亮正确 |
| 竖屏布局 | ✅ 内容 720pt 居中，不拉伸 |
| 横屏布局 | ✅ 侧边栏在左，内容自适应 |
| UI 测试 6/6（iPad） | ✅ 导航、设置子页、外观切换、跟读换句 |
| 跟读页宽度上限 760 | ✅ |

## 本轮修复的问题

1. 内容拉满全宽显得空洞 → 新增 `centeredColumn(720)` 应用到 7 个页面。
2. UI 测试定位依赖 iPhone 底部 TabBar → 新增 `openTab()` 双端适配。
3. 返回键误点 "Hide Sidebar" → 测试改用 `BackButton` 标识。

## 已知差异（非缺陷）

- iPhone 底部 TabBar，iPad 自动变为侧边栏（iPadOS 18+ 系统行为）。
- 横屏截图需用 `simctl spawn booted defaults write com.apple.springui orientation -int 3` 真旋转，`XCUIDevice.orientation` 在模拟器不生效。
