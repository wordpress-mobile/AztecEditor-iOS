import Foundation
import XCTest


// MARK: - BasePage
//
class BasePage {
    let app = XCUIApplication()
    let expectedElement: XCUIElement
    let waitTimeout = Double(20)

    init(element: XCUIElement) {
        expectedElement = element
        waitForPage()
    }

    /// Waits (synchronously) until the current Edition Page is loaded.
    ///
    @discardableResult
    func waitForPage() -> BasePage {
        _ = expectedElement.waitForExistence(timeout: waitTimeout)
        Logger.log(message: "Page \(self) is loaded", event: .i)
        return self
    }

    /// Waits (synchronously) until a given MenuItem pops into existance. When that happens, the onExistance callback gets called.
    ///
    func waitForMenuItem(with identifier: String, onExistance: (XCUIElement) -> ()) {
        let item = app.menuItems[identifier]
        _ = item.waitForExistence(timeout: waitTimeout)
        onExistance(item)
    }

    /// Waits (synchronously) until a given XCUIElement fulfills a given predicate. (With timeout!).
    ///
    func waitFor(element: XCUIElement, predicate: String, timeout: Int? = nil) {
        let timeoutValue = timeout ?? 5
        
        let elementPredicate = XCTNSPredicateExpectation(predicate: NSPredicate(format: predicate), object: element)
        _ = XCTWaiter.wait(for: [elementPredicate], timeout: TimeInterval(timeoutValue))
    }

    /// Indicates if the current page is loaded.
    ///
    func isLoaded() -> Bool {
        return expectedElement.exists
    }
}
