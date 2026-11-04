import XCTest

final class BrowseModeTests: XCTestCase {
    func testBrowseNextPhrase() {
        let app = XCUIApplication()
        app.launchArguments = ["-skipOnboarding"]
        app.launch()

        let mode = app.buttons["modeToggle"]
        XCTAssertTrue(mode.waitForExistence(timeout: 10))
        mode.tap()

        let next = app.buttons["browseNext"]
        XCTAssertTrue(next.waitForExistence(timeout: 5))
        for _ in 0..<5 { next.tap() }

        let day2 = app.staticTexts["Day 2"]
        XCTAssertTrue(day2.waitForExistence(timeout: 8))
    }
}