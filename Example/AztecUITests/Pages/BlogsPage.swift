import Foundation
import XCTest


class BlogsPage: BasePage {
    init(appInstance: XCUIApplication) {
        let expectedElement = appInstance.tables.staticTexts[elementStringIDs.emptyDemo]
        super.init(appInstance: appInstance, element: expectedElement)
    }
    
    func gotoEmptyDemo() -> EditorPage {
        app.staticTexts[elementStringIDs.emptyDemo].tap()
        
        return EditorPage.init(appInstance: app, type: "rich")
    }
    
    func gotoDemo() -> EditorPage {
        app.staticTexts[elementStringIDs.demo].tap()
        
        return EditorPage.init(appInstance: app, type: "rich")

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
