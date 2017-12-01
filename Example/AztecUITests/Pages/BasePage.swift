import Foundation
import XCTest

class BasePage {
    var app: XCUIApplication!
    private var expectedElement: XCUIElement!
    var waitTimeout: Double!

    init(appInstance: XCUIApplication, element: XCUIElement) {
        app = appInstance
        expectedElement = element
        waitTimeout = 20
        waitForPage()
    }
    
    func waitForPage() {
        expectedElement.waitForExistence(timeout: waitTimeout)
    }
    
    func isLoaded() -> Bool {
        return expectedElement.exists
    }
}
