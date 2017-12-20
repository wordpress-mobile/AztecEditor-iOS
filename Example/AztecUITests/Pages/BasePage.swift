import Foundation
import XCTest

class BasePage {
    var app: XCUIApplication!
    var expectedElement: XCUIElement!
    var waitTimeout: Double!

    //init(appInstance: XCUIApplication, element: XCUIElement) {
    init(element: XCUIElement) {
        app = XCUIApplication() // appInstance
        expectedElement = element
        waitTimeout = 20
        _ = waitForPage()
    }
    
    func waitForPage() -> BasePage {
        _ = expectedElement.waitForExistence(timeout: waitTimeout)
        Logger.log(message: "Page \(self) is loaded", event: .i)
        return self
    }
    
    func waitFor(element: XCUIElement, predicate: String, timeout: Int? = nil) {
        let timeoutValue = timeout ?? 5
        
        let elementPredicate = XCTNSPredicateExpectation(predicate: NSPredicate(format: predicate), object: element)
        _ = XCTWaiter.wait(for: [elementPredicate], timeout: TimeInterval(timeoutValue))
    }
    
    func isLoaded() -> Bool {
        return expectedElement.exists
    }
}
