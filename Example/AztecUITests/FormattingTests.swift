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
        super.tearDown()
    }
    
    func testOrderedListWithAddedStyles() {
        let values = ["line 1", "line 2", "line 3"]
        let expectedHTML = "<ol><li>line 1</li><li><strong>line</strong> 2</li><li>line 3</li></ol>"

        richEditorPage.addListWithLines(type: "ol", lines: values)
        richEditorPage.tapByCordinates(x: 32, y: 30)
        
        sleep(1)
        richEditorPage.textView.tap()
        app.menuItems["Select"].tap()
        
        richEditorPage.toolbarButtonTap(locator: elementStringIDs.boldButton)
        let text = richEditorPage.switchContentView().getViewContent()
        XCTAssertEqual(text, expectedHTML)
    }
    
    func testUnorderedListWithRemovedStyles() {
        let htmlList = "<ul><li>line 1</li><li><strong>line</strong> 2</li><li>line 3</li></ul>"
        let expectedHTML = "<ul><li>line 1</li><li>line 2</li><li>line 3</li></ul>"

        richEditorPage.switchContentView()
            .enterText(text: htmlList)
            .switchContentView()
            .tapByCordinates(x: 30, y: 32)
            .textView.press(forDuration: 1)
        app.menuItems["Select"].tap()
        
        richEditorPage.toolbarButtonTap(locator: elementStringIDs.boldButton)
        let text = richEditorPage.switchContentView().getViewContent()
        XCTAssertEqual(text, expectedHTML)
    }
}
