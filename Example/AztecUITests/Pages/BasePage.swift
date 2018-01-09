import Foundation
import XCTest

class BasePage {
    let app = XCUIApplication()
    let expectedElement: XCUIElement
    let waitTimeout = Double(20)

    init(element: XCUIElement) {
        expectedElement = element
        waitForPage()
    }

    @discardableResult
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
