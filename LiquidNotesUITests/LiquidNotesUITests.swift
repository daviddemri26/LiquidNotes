import XCTest

final class LiquidNotesUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCreateNoteAndOpenSettings() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Notes"].waitForExistence(timeout: 3))
        app.tabBars.buttons["Notes"].tap()

        let newNoteButton = app.buttons["New Note"]
        XCTAssertTrue(newNoteButton.waitForExistence(timeout: 3))
        newNoteButton.tap()

        let titleField = app.textFields["Title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 3))
        titleField.tap()
        titleField.typeText("UI Test Note")

        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))

        app.staticTexts["Trash"].tap()
        XCTAssertTrue(app.navigationBars["Trash"].waitForExistence(timeout: 3))
    }
}
