import Foundation
import XCTest


class BlogsPage: BasePage {
    init() {
        let expectedElement = XCUIApplication().tables.staticTexts[elementStringIDs.emptyDemo]
        super.init(element: expectedElement)
    }
    
    func gotoEmptyDemo() -> EditorPage {
        app.staticTexts[elementStringIDs.emptyDemo].tap()
        
        return EditorPage.init(type: "rich")
    }
    
    func gotoDemo() -> EditorPage {
        app.staticTexts[elementStringIDs.demo].tap()
        
        return EditorPage.init(type: "rich")

    }
    
    func showOptionsStrip() -> Void {
        app.textViews[elementStringIDs.richTextField].tap()
        expandOptionsSctrip()
    }
    
    // TODO: Dirty solution. ask / add some nice locator
    func expandOptionsSctrip() -> Void {
        let expandButton = app.children(matching: .window).element(boundBy: 1).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .button).element
        
        if expandButton.exists && expandButton.isHittable {
            expandButton.tap()
        }
    }
}
