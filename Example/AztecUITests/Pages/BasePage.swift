import Foundation
import XCTest

class BasePage {
    var app: XCUIApplication!
    var expectedElement: XCUIElement!
    var waitTimeout: Double!

    init(appInstance: XCUIApplication, element: XCUIElement) {
        app = appInstance
        expectedElement = element
        waitTimeout = 20
        waitForPage()
    }
    
    func waitForPage() -> BasePage {
        expectedElement.waitForExistence(timeout: waitTimeout)
        Logger.log(message: "Page \(self) is loaded", event: .i)
        return self
    }
    
    func isLoaded() -> Bool {
        return expectedElement.exists
    }
}
