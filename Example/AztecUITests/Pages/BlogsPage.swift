import Foundation
import XCTest


class BlogsPage: BasePage {
    
    init(appInstance: XCUIApplication) {
        let expectedElement = appInstance.tables.staticTexts[elementStringIDs.emptyDemo]
        super.init(appInstance: appInstance, element: expectedElement)
    }
    
    func gotoEmptyDemo() {
        app.staticTexts[elementStringIDs.emptyDemo].tap()
        
        showOptionsStrip()
    }
    
    func gotoDemo() {
        app.staticTexts[elementStringIDs.demo].tap()
        
        showOptionsStrip()
    }
    
    func showOptionsStrip() -> Void {
        app.textViews[elementStringIDs.richTextField].tap()
        expandOptionsSctrip()
    }
    
    func expandOptionsSctrip() -> Void {
        let expandButton = app.children(matching: .window).element(boundBy: 1).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .button).element
        
        if expandButton.exists && expandButton.isHittable {
            expandButton.tap()
        }
    }
}
