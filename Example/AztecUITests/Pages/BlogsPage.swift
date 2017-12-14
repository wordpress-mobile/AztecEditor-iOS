import Foundation
import XCTest


class BlogsPage: BasePage {
    init() {
        let expectedElement = XCUIApplication().tables.staticTexts[elementStringIDs.emptyDemo]
        super.init(element: expectedElement)
    }

    @discardableResult
    func gotoEmptyDemo() -> EditorPage {
        app.staticTexts[elementStringIDs.emptyDemo].tap()
        
        return EditorPage.init(type: "rich")
    }

    @discardableResult
    func gotoDemo() -> EditorPage {
        app.staticTexts[elementStringIDs.demo].tap()
        
        return EditorPage.init(type: "rich")

    }
    
    func showOptionsStrip() -> Void {
        app.textViews[elementStringIDs.richTextField].tap()
        expandOptionsSctrip()
    }
    
    func expandOptionsSctrip() -> Void {
        let expandButton = app.children(matching: .window).element(boundBy: 1).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .button).element
        let htmlButton = app.scrollViews.otherElements.buttons[elementStringIDs.sourcecodeButton]
        
        if expandButton.exists && expandButton.isHittable && !htmlButton.exists {
            expandButton.tap()
        }
    }
}
