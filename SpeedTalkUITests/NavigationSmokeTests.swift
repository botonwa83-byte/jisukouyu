import XCTest

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
        let tabs = app.tabBars.buttons
        XCTAssertTrue(tabs["今日"].waitForExistence(timeout: 15))

        for title in ["课表", "场景", "对练", "我的", "今日"] {
            let tab = tabs[title]
            XCTAssertTrue(tab.exists, "缺少 Tab：\(title)")
            tab.tap()
            XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 8), "\(title) 页没打开")
        }
    }

    func testSettingsAndReviewQueueOpen() {
        let app = launchApp()
        let meTab = app.tabBars.buttons["我的"]
        XCTAssertTrue(meTab.waitForExistence(timeout: 15))
        meTab.tap()
        XCTAssertTrue(app.navigationBars["我的"].waitForExistence(timeout: 8))

        app.buttons["设置"].tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 5))
        app.navigationBars["设置"].buttons.element(boundBy: 0).tap()

        let review = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "到期复习")).firstMatch
        XCTAssertTrue(review.waitForExistence(timeout: 5))
        review.tap()
        XCTAssertTrue(app.navigationBars["复习"].waitForExistence(timeout: 5))
    }
}
