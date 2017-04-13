import XCTest

class AztecSimpleTextFormattingTests: XCTestCase {

    private var app: XCUIApplication!
    private var htmlContentTextView: XCUIElement!
    private var richContentTextView: XCUIElement!

    override func setUp() {
        super.setUp()

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIDevice.shared().orientation = .portrait
        app = XCUIApplication()
        app.launch()

        let tablesQuery = app.tables
        tablesQuery.staticTexts[elementStringIDs.emptyDemo].tap()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testSimpleBoldText() {
        richContentTextView = app.textViews[elementStringIDs.richTextField]
        richContentTextView.tap()
        richContentTextView.enterAndSelectText(text: "text")

        app.scrollViews.otherElements.buttons[elementStringIDs.boldButton].tap()
        app.buttons[elementStringIDs.sourcecodeButton].tap()

        htmlContentTextView = app.textViews[elementStringIDs.htmlTextField]
        let text: String = htmlContentTextView.value as! String
        let expected = "<strong>text</strong>"
        XCTAssertEqual(expected, text)
    }

    func testSimpleItalicText() {
        richContentTextView = app.textViews[elementStringIDs.richTextField]
        richContentTextView.tap()
        richContentTextView.enterAndSelectText(text: "text")

        app.scrollViews.otherElements.buttons[elementStringIDs.italicButton].tap()
        app.buttons[elementStringIDs.sourcecodeButton].tap()

        htmlContentTextView = app.textViews[elementStringIDs.htmlTextField]
        let text: String = htmlContentTextView.value as! String
        let expected = "<em>text</em>"
        XCTAssertEqual(expected, text)
    }

    func testSimpleUnderlineText() {
        richContentTextView = app.textViews[elementStringIDs.richTextField]
        richContentTextView.tap()
        richContentTextView.enterAndSelectText(text: "text")

        app.scrollViews.otherElements.buttons[elementStringIDs.underlineButton].tap()
        app.buttons[elementStringIDs.sourcecodeButton].tap()

        htmlContentTextView = app.textViews[elementStringIDs.htmlTextField]
        let text: String = htmlContentTextView.value as! String
        let expected = "<u>text</u>"
        XCTAssertEqual(expected, text)
    }

    func testSimpleStrikethroughText() {
        richContentTextView = app.textViews[elementStringIDs.richTextField]
        richContentTextView.tap()
        richContentTextView.enterAndSelectText(text: "text")

        app.scrollViews.otherElements.buttons[elementStringIDs.strikethroughButton].tap()
        app.buttons[elementStringIDs.sourcecodeButton].tap()

        htmlContentTextView = app.textViews[elementStringIDs.htmlTextField]
        let text: String = htmlContentTextView.value as! String
        let expected = "<del>text</del>"
        XCTAssertEqual(expected, text)
    }

    func testSimpleBlockquoteText() {
        richContentTextView = app.textViews[elementStringIDs.richTextField]
        richContentTextView.tap()
        richContentTextView.enterAndSelectText(text: "text")

        app.scrollViews.otherElements.buttons[elementStringIDs.blockquoteButton].tap()
        app.buttons[elementStringIDs.sourcecodeButton].tap()

        htmlContentTextView = app.textViews[elementStringIDs.htmlTextField]
        let text: String = htmlContentTextView.value as! String
        let expected = "<blockquote>text</blockquote>"
        XCTAssertEqual(expected, text)
    }

    // Enable this test after unordered lists are fully implemented
    func testSimpleUnorderedListText() {
        richContentTextView = app.textViews[elementStringIDs.richTextField]
        richContentTextView.tap()
        richContentTextView.enterAndSelectText(text: "text")

        app.scrollViews.otherElements.buttons[elementStringIDs.unorderedlistButton].tap()
        app.buttons[elementStringIDs.sourcecodeButton].tap()

        htmlContentTextView = app.textViews[elementStringIDs.htmlTextField]
        let text: String = htmlContentTextView.value as! String
        let expected = "<ul><li>text</li></ul>"
        XCTAssertEqual(expected, text)
    }

    // Enable this test after ordered lists are fully implemented
    func testSimpleOrderedListText() {
        richContentTextView = app.textViews[elementStringIDs.richTextField]
        richContentTextView.tap()
        richContentTextView.enterAndSelectText(text: "text")

        app.scrollViews.otherElements.buttons[elementStringIDs.orderedlistButton].tap()
        app.buttons[elementStringIDs.sourcecodeButton].tap()

        htmlContentTextView = app.textViews[elementStringIDs.htmlTextField]
        let text: String = htmlContentTextView.value as! String
        let expected = "<ol><li>text</li></ol>"
        XCTAssertEqual(expected, text)
    }

    func testSimpleLinkedText() {
        richContentTextView = app.textViews[elementStringIDs.richTextField]
        richContentTextView.tap()
        richContentTextView.enterAndSelectText(text: "text")

        // Copy link to be auto-filled in URL field
        UIPasteboard.general.string = "https://wordpress.com/"
        app.scrollViews.otherElements.buttons[elementStringIDs.linkButton].tap()
        app.alerts.buttons.element(boundBy: 3).tap()
        app.buttons[elementStringIDs.sourcecodeButton].tap()

        htmlContentTextView = app.textViews[elementStringIDs.htmlTextField]
        let text: String = htmlContentTextView.value as! String
        let expected = "<a href=\"https://wordpress.com/\">text</a>"
        XCTAssertEqual(expected, text)
    }

    func testHorizontalRuler() {
        richContentTextView = app.textViews[elementStringIDs.richTextField]
        richContentTextView.tap()

        app.scrollViews.otherElements.buttons[elementStringIDs.horizontalrulerButton].tap()
        app.buttons[elementStringIDs.sourcecodeButton].tap()

        htmlContentTextView = app.textViews[elementStringIDs.htmlTextField]
        let tex: String = htmlContentTextView.value as! String
        let expected = "<hr>"
        XCTAssertEqual(expected, text)
    }

    func testMoreTag() {
        richContentTextView = app.textViews[elementStringIDs.richTextField]
        richContentTextView.tap()

        app.scrollViews.otherElements.buttons[elementStringIDs.moreButton].tap()
        app.buttons[elementStringIDs.sourcecodeButton].tap()

        htmlContentTextView = app.textViews[elementStringIDs.htmlTextField]
        let text: String = htmlContentTextView.value as! String
        let expected = "<!--more-->"
        XCTAssertEqual(expected, text)
    }

    func testHeadingOneText() {
        richContentTextView = app.textViews[elementStringIDs.richTextField]
        richContentTextView.tap()
        richContentTextView.enterAndSelectText(text: "text")

        app.scrollViews.otherElements.buttons[elementStringIDs.headerButton].tap()
        app.tables.staticTexts[elementStringIDs.header1Button].tap()
        app.buttons[elementStringIDs.sourcecodeButton].tap()

        htmlContentTextView = app.textViews[elementStringIDs.htmlTextField]
        let text: String = htmlContentTextView.value as! String
        let expected = "<h1>text</h1>"
        XCTAssertEqual(expected, text)
    }

    func testHeadingTwoText() {
        richContentTextView = app.textViews[elementStringIDs.richTextField]
        richContentTextView.tap()
        richContentTextView.enterAndSelectText(text: "text")

        app.scrollViews.otherElements.buttons[elementStringIDs.headerButton].tap()
        app.tables.staticTexts[elementStringIDs.header2Button].tap()
        app.buttons[elementStringIDs.sourcecodeButton].tap()

        htmlContentTextView = app.textViews[elementStringIDs.htmlTextField]
        let text: String = htmlContentTextView.value as! String
        let expected = "<h2>text</h2>"
        XCTAssertEqual(expected, text)
    }

    func testHeadingThreeText() {
        richContentTextView = app.textViews[elementStringIDs.richTextField]
        richContentTextView.tap()
        richContentTextView.enterAndSelectText(text: "text")

        app.scrollViews.otherElements.buttons[elementStringIDs.headerButton].tap()
        app.tables.staticTexts[elementStringIDs.header3Button].tap()
        app.buttons[elementStringIDs.sourcecodeButton].tap()

        htmlContentTextView = app.textViews[elementStringIDs.htmlTextField]
        let text: String = htmlContentTextView.value as! String
        let expected = "<h3>text</h3>"
        XCTAssertEqual(expected, text)
    }

    func testHeadingFourText() {
        richContentTextView = app.textViews[elementStringIDs.richTextField]
        richContentTextView.tap()
        richContentTextView.enterAndSelectText(text: "text")

        app.scrollViews.otherElements.buttons[elementStringIDs.headerButton].tap()
        app.tables.element(boundBy: 0).swipeUp()
        app.tables.staticTexts[elementStringIDs.header4Button].tap()
        app.buttons[elementStringIDs.sourcecodeButton].tap()

        htmlContentTextView = app.textViews[elementStringIDs.htmlTextField]
        let text: String = htmlContentTextView.value as! String
        let expected = "<h4>text</h4>"
        XCTAssertEqual(expected, text)
    }

    func testHeadingFiveText() {
        richContentTextView = app.textViews[elementStringIDs.richTextField]
        richContentTextView.tap()
        richContentTextView.enterAndSelectText(text: "text")

        app.scrollViews.otherElements.buttons[elementStringIDs.headerButton].tap()
        app.tables.element(boundBy: 0).swipeUp()
        app.tables.staticTexts[elementStringIDs.header5Button].tap()
        app.buttons[elementStringIDs.sourcecodeButton].tap()

        htmlContentTextView = app.textViews[elementStringIDs.htmlTextField]
        let text: String = htmlContentTextView.value as! String
        let expected = "<h5>text</h5>"
        XCTAssertEqual(expected, text)
    }

    func testHeadingSixText() {
        richContentTextView = app.textViews[elementStringIDs.richTextField]
        richContentTextView.tap()
        richContentTextView.enterAndSelectText(text: "text")

        app.scrollViews.otherElements.buttons[elementStringIDs.headerButton].tap()
        app.tables.element(boundBy: 0).swipeUp()
        app.tables.staticTexts[elementStringIDs.header6Button].tap()
        app.buttons[elementStringIDs.sourcecodeButton].tap()

        htmlContentTextView = app.textViews[elementStringIDs.htmlTextField]
        let text: String = htmlContentTextView.value as! String
        let expected = "<h6>text</h6>"
        XCTAssertEqual(expected, text)
    }
}
