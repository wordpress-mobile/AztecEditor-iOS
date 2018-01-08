import XCTest

class FormattingTests: XCTestCase {
    
    private var richEditorPage: EditorPage!
    
    override func setUp() {
        super.setUp()
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIDevice.shared().orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = ["NoAnimations"]
        app.activate()

        let blogsPage = BlogsPage()
        richEditorPage = blogsPage.gotoEmptyDemo()
    }
    
    override func tearDown() {
        _ = richEditorPage.gotoRootPage()
        super.tearDown()
    }
    
    func testOrderedListWithAddedStyles() {
        let values = ["line 1", "line 2", "line 3"]
        let expectedHTML = "<ol><li>line 1</li><li><strong>line</strong> 2</li><li>line 3</li></ol>"

        richEditorPage
            .addListWithLines(type: "ol", lines: values)
            .tapByCordinates(x: 30, y: 32)
            .textView.tap()
        XCUIApplication().menuItems["Select"].tap()
        
        let text = richEditorPage
            .toolbarButtonTap(locator: elementStringIDs.boldButton)
            .switchContentView()
            .getViewContent()
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
        XCUIApplication().menuItems["Select"].tap()
        
        let text = richEditorPage
            .toolbarButtonTap(locator: elementStringIDs.boldButton)
            .switchContentView()
            .getViewContent()
        XCTAssertEqual(text, expectedHTML)
    }
    
    // test behavior of highlighted style at 0 index of editor with 1 line of text (EOB marker at the 1 line)
    func testLeadingStyleHighlightInEmptyEditor() {
        let text = "some text"
        
        richEditorPage
            .toolbarButtonTap(locator: elementStringIDs.boldButton)
            .enterText(text: text)
            .toolbarButtonTap(locator: elementStringIDs.italicButton)
        XCTAssertTrue(richEditorPage.boldButton.isSelected)
        XCTAssertTrue(richEditorPage.italicButton.isSelected)
        
        richEditorPage.deleteText(chars: text.count)
        XCTAssertTrue(richEditorPage.boldButton.isSelected)
        XCTAssertFalse(richEditorPage.italicButton.isSelected)
        
        richEditorPage.deleteText(chars: 1)
        XCTAssertTrue(richEditorPage.boldButton.isSelected)
        XCTAssertFalse(richEditorPage.italicButton.isSelected)
    }
    
    func testQuotedListFormatting() {
        let text = "some text\nsome text\nsome text"
        let expectedHTML = "<blockquote><ul><li>some text</li><li>some text</li><li>some text</li></ul></blockquote>"
        
        let html = richEditorPage
            .toolbarButtonTap(locator: elementStringIDs.blockquoteButton)
            .addList(type: "ul")
            .enterText(text: text)
            .switchContentView().getViewContent()
        
        XCTAssertEqual(html, expectedHTML)
    }
    
    func testAddStylesToBlockquote() {
        let text = "some text\nsome text\nsome text"
        let expectedHTML = "<blockquote>some text</blockquote><blockquote><strong>some</strong> text</blockquote><blockquote><em>some</em> text</blockquote>"
        
        richEditorPage
            .toolbarButtonTap(locator: elementStringIDs.blockquoteButton)
            .enterText(text: text)
            .tapByCordinates(x: 30, y: 32)
            .textView.press(forDuration: 1)
        XCUIApplication().menuItems["Select"].tap()
        
        richEditorPage
            .toolbarButtonTap(locator: elementStringIDs.boldButton)
            .tapByCordinates(x: 30, y: 72)
            .textView.press(forDuration: 1)
        XCUIApplication().menuItems["Select"].tap()
            
        let html = richEditorPage
            .toolbarButtonTap(locator: elementStringIDs.italicButton)
            .switchContentView()
            .getViewContent()
        
        XCTAssertEqual(html, expectedHTML)
    }
    
    func testRemoveStylesToBlockquote() {
        let html = "<blockquote>some text</blockquote><blockquote><strong>some</strong> text</blockquote><blockquote><em>some</em> text</blockquote>"
        let expectedText = "some text\nsome text\nsome text"

        richEditorPage
            .switchContentView()
            .enterText(text: html)
            .switchContentView()
            .tapByCordinates(x: 30, y: 32)
            .textView.press(forDuration: 1)
        XCUIApplication().menuItems["Select"].tap()
        
        richEditorPage
            .toolbarButtonTap(locator: elementStringIDs.boldButton)
            .tapByCordinates(x: 30, y: 72)
            .textView.press(forDuration: 1)
        XCUIApplication().menuItems["Select"].tap()
        
        let text = richEditorPage
            .toolbarButtonTap(locator: elementStringIDs.italicButton)
            .selectAllText()
            .toolbarButtonTap(locator: elementStringIDs.blockquoteButton)
            .getViewContent()
        XCTAssertEqual(text, expectedText)
    }
    
    func testQuotedListRemoveListFormatting() {
        let text = "some text\nsome text\nsome text"
        let expectedHTML = "<blockquote><ul><li>some text</li><li>some text</li></ul></blockquote><blockquote>some text</blockquote>"
        
        let html = richEditorPage
            .toolbarButtonTap(locator: elementStringIDs.blockquoteButton)
            .addList(type: "ul")
            .enterText(text: text)
            .addList(type: "ul")
            .switchContentView()
            .getViewContent()
        
        XCTAssertEqual(html, expectedHTML)
    }
    
    func testListwithQuoteFormatting() {
        let text1 = "some text\nsome text\nsome text\n"
        let text2 = "some text"
        let expectedHTML = "<ul><li>some text</li><li>some text</li><li>some text</li><li><blockquote>some text</blockquote></li></ul>"
        
        let html = richEditorPage
            .addList(type: "ul")
            .enterText(text: text1)
            .toolbarButtonTap(locator: elementStringIDs.blockquoteButton)
            .enterText(text: text2)
            .switchContentView()
            .getViewContent()
        
        XCTAssertEqual(html, expectedHTML)
    }
}
