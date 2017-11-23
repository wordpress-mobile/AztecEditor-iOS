import XCTest

class FormattingTests: XCTestCase {
    
    private var app: XCUIApplication!
    private var richEditorPage: EditorPage!
    
    override func setUp() {
        super.setUp()
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIDevice.shared().orientation = .portrait
        app = XCUIApplication()
        app.launch()
        
        let blogsPage = BlogsPage.init(appInstance: app)
        richEditorPage = blogsPage.gotoEmptyDemo()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testOrderedListWithChangedStyles() {
        // TODO move to EditorPage
        app.scrollViews.otherElements.buttons[elementStringIDs.unorderedlistButton].tap()
        app.tables.staticTexts[elementStringIDs.unorderedListOption].tap()
        
        let returnButton = app.buttons["Return"]
        
        richEditorPage.enterText(text: "line 1")
        returnButton.tap()
        richEditorPage.enterText(text: "line 2")
        returnButton.tap()
        richEditorPage.enterText(text: "line 3")
        returnButton.tap()
        returnButton.tap()

        let field = app.textViews[elementStringIDs.richTextField]
        // Some magic to move caret to end of the text
        let vector = CGVector(dx:field.frame.minX + 30, dy:field.frame.minY + 30)
        field.coordinate(withNormalizedOffset:CGVector.zero).withOffset(vector).tap()

        richEditorPage.textView.press(forDuration: 1)
        app.menuItems["Select"].tap()
        
        app.scrollViews.otherElements.buttons[elementStringIDs.boldButton].tap()

        let text = richEditorPage.switchContentView().getViewContent()
        let expectedHTML = "<ul><li>line 1</li><li><strong>line</strong> 2</li><li>line 3</li></ul>"

        XCTAssertEqual(text, expectedHTML)
    }
}
