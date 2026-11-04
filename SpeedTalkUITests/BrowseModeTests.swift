import XCTest

final class BrowseModeTests: XCTestCase {
    func testBrowseNextPhrase() {
        let app = XCUIApplication()
        app.launchArguments = ["-skipOnboarding", "-resetAdvanceBudget"]
        app.launch()

        let mode = app.buttons["modeToggle"]
        XCTAssertTrue(mode.waitForExistence(timeout: 10))
        let next = app.buttons["browseNext"]
        if !next.waitForExistence(timeout: 2) { mode.tap() }
        XCTAssertTrue(next.waitForExistence(timeout: 5))
        for _ in 0..<5 { next.tap() }

        XCTAssertTrue(app.staticTexts["1/5"].waitForExistence(timeout: 8))
    }
}