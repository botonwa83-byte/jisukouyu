import XCTest

/// 跟读主流程回归：练完一句点「下一句」应原地载入下一句，而不是退回今日页。
final class PracticeFlowTests: XCTestCase {
    @MainActor
    private func launchInSpeakMode() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-skipOnboarding"]
        app.launch()
        let mode = app.buttons["modeToggle"]
        XCTAssertTrue(mode.waitForExistence(timeout: 10))
        if app.buttons["browseNext"].waitForExistence(timeout: 1) {
            mode.tap()
        }
        XCTAssertFalse(app.buttons["browseNext"].waitForExistence(timeout: 1), "应处于跟读模式")
        return app
    }

    @MainActor
    private func openPractice(_ app: XCUIApplication) -> String {
        let practice = app.buttons["按住说"]
        XCTAssertTrue(practice.waitForExistence(timeout: 5))
        practice.tap()
        // 跟读页目标句是除导航标题「跟读」外的第一段文本
        let en = app.staticTexts.matching(NSPredicate(format: "label != '跟读'")).firstMatch
        XCTAssertTrue(en.waitForExistence(timeout: 5))
        return en.label
    }

    @MainActor
    private func scoreWithKeyboard(_ app: XCUIApplication) {
        app.buttons["打不了字？用键盘跟读"].tap()
        let field = app.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        field.tap()
        field.typeText("hello")
        app.buttons["评分"].tap()
    }

    @MainActor
    func testNextPhraseStaysInPracticeAndShowsNewSentence() {
        let app = launchInSpeakMode()

        let firstEN = openPractice(app)
        scoreWithKeyboard(app)

        let next = app.buttons["下一句"]
        XCTAssertTrue(next.waitForExistence(timeout: 5))
        next.tap()

        // 仍停留在跟读页，并且目标句已经换成下一句
        let secondEN = app.staticTexts.matching(NSPredicate(format: "label != '跟读'")).firstMatch
        XCTAssertTrue(secondEN.waitForExistence(timeout: 5))
        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline, secondEN.label == firstEN {
            usleep(200_000)
        }
        XCTAssertNotEqual(firstEN, secondEN.label, "下一句应载入新句子，实际还是同一句")
        XCTAssertTrue(app.navigationBars["跟读"].exists, "点下一句后应留在跟读页")
        XCTAssertFalse(app.buttons["下一句"].exists, "评分报告应已关闭，回到跟读状态")

        // 退出跟读后，今日页进度应推进到 2/5
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.staticTexts["2/5"].waitForExistence(timeout: 5), "今日页应推进到 2/5")
    }
}
