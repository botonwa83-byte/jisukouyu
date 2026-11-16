import XCTest

extension XCUIApplication {
    /// iPhone 是底部 TabBar，iPad 会自动变成侧边栏（Cell 里的 StaticText），按标签统一点击。
    func openTab(_ title: String) {
        let tab = tabBars.buttons[title]
        if tab.waitForExistence(timeout: 2) {
            tab.tap()
            return
        }
        let row = staticTexts[title]
        guard row.waitForExistence(timeout: 5) else {
            XCTFail("找不到导航项：\(title)")
            return
        }
        row.tap()
    }
}

/// 上架前的导航冒烟：五个 Tab、我的页入口、设置与复习队列都能打开。
final class NavigationSmokeTests: XCTestCase {
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-skipOnboarding"]
        app.launch()
        return app
    }

    func testAllTabsOpen() {
        let app = launchApp()
        XCTAssertTrue(app.staticTexts["今日"].waitForExistence(timeout: 15))

        for title in ["课表", "场景", "对练", "我的", "今日"] {
            app.openTab(title)
            XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 8), "\(title) 页没打开")
        }
    }

    func testSettingsAndReviewQueueOpen() {
        let app = launchApp()
        XCTAssertTrue(app.staticTexts["今日"].waitForExistence(timeout: 15))
        app.openTab("我的")
        XCTAssertTrue(app.navigationBars["我的"].waitForExistence(timeout: 8))

        app.buttons["设置"].tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 5))
        app.navigationBars["设置"].buttons.element(boundBy: 0).tap()

        let review = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "到期复习")).firstMatch
        XCTAssertTrue(review.waitForExistence(timeout: 5))
        review.tap()
        XCTAssertTrue(app.navigationBars["复习"].waitForExistence(timeout: 5))
    }

    /// 设置里的各个子页与外观切换都不该崩，切完能正常返回。
    func testSettingsSubPagesAndAppearanceSwitch() {
        let app = launchApp()
        XCTAssertTrue(app.staticTexts["今日"].waitForExistence(timeout: 15))
        app.openTab("我的")
        app.buttons["设置"].tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 8))

        // 外观：夜间 → 白天 → 跟随系统
        for title in ["夜间", "白天", "跟随系统"] {
            let segment = app.buttons[title]
            XCTAssertTrue(segment.waitForExistence(timeout: 5), "外观选项缺失：\(title)")
            segment.tap()
        }
        XCTAssertTrue(app.navigationBars["设置"].exists, "切换外观后不应退出设置页")

        app.buttons["AI 设置"].tap()
        XCTAssertTrue(app.navigationBars["AI 设置"].waitForExistence(timeout: 5))
        app.navigationBars["AI 设置"].buttons.element(boundBy: 0).tap()

        app.buttons["每日提醒"].tap()
        XCTAssertTrue(app.navigationBars["每日提醒"].waitForExistence(timeout: 5))
        app.navigationBars["每日提醒"].buttons.element(boundBy: 0).tap()

        app.navigationBars["设置"].buttons.element(boundBy: 0).tap()
        app.buttons["隐私说明"].tap()
        XCTAssertTrue(app.navigationBars["隐私说明"].waitForExistence(timeout: 5))
    }
}
