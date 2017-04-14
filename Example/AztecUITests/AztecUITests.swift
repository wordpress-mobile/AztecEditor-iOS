import XCTest

class AztecSimpleTextFormattingTests: XCTestCase {

    private var app: XCUIApplication!
    private var richTextField: XCUIElement!

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
        enterTextInField(text: "text")
        selectAllTextInField()

        app.scrollViews.otherElements.buttons[elementStringIDs.boldButton].tap()
        app.buttons[elementStringIDs.sourcecodeButton].tap()

        let text = getHTMLContent()
        let expected = "<strong>text</strong>"
        XCTAssertEqual(expected, text)
    }

    func testSimpleItalicText() {
        enterTextInField(text: "text")
        selectAllTextInField()

        app.scrollViews.otherElements.buttons[elementStringIDs.italicButton].tap()
        app.buttons[elementStringIDs.sourcecodeButton].tap()

        let text = getHTMLContent()
        let expected = "<em>text</em>"
        XCTAssertEqual(expected, text)
    }

    func testSimpleUnderlineText() {
        enterTextInField(text: "text")
        selectAllTextInField()

        app.scrollViews.otherElements.buttons[elementStringIDs.underlineButton].tap()
        app.buttons[elementStringIDs.sourcecodeButton].tap()

        let text = getHTMLContent()
        let expected = "<u>text</u>"
        XCTAssertEqual(expected, text)
    }

    func testSimpleStrikethroughText() {
        enterTextInField(text: "text")
        selectAllTextInField()

        app.scrollViews.otherElements.buttons[elementStringIDs.strikethroughButton].tap()
        app.buttons[elementStringIDs.sourcecodeButton].tap()

        let text = getHTMLContent()
        let expected = "<del>text</del>"
        XCTAssertEqual(expected, text)
    }

    func testSimpleBlockquoteText() {
        enterTextInField(text: "text")
        selectAllTextInField()

        app.scrollViews.otherElements.buttons[elementStringIDs.blockquoteButton].tap()
        app.buttons[elementStringIDs.sourcecodeButton].tap()

        let text = getHTMLContent()
        let expected = "<blockquote>text</blockquote>"
        XCTAssertEqual(expected, text)
    }

    // Enable this test after unordered lists are fully implemented
    func testSimpleUnorderedListText() {
        enterTextInField(text: "text")
        selectAllTextInField()

        app.scrollViews.otherElements.buttons[elementStringIDs.unorderedlistButton].tap()
        app.buttons[elementStringIDs.sourcecodeButton].tap()

        let text = getHTMLContent()
        let expected = "<ul><li>text</li></ul>"
        XCTAssertEqual(expected, text)
    }

    // Enable this test after ordered lists are fully implemented
    func testSimpleOrderedListText() {
        enterTextInField(text: "text")
        selectAllTextInField()

        app.scrollViews.otherElements.buttons[elementStringIDs.orderedlistButton].tap()
        app.buttons[elementStringIDs.sourcecodeButton].tap()

        let text = getHTMLContent()
        let expected = "<ol><li>text</li></ol>"
        XCTAssertEqual(expected, text)
    }

    func testSimpleLinkedText() {
        enterTextInField(text: "text")
        selectAllTextInField()

        // Copy link to be auto-filled in URL field
        UIPasteboard.general.string = "https://wordpress.com/"
        app.scrollViews.otherElements.buttons[elementStringIDs.linkButton].tap()
        app.alerts.buttons[elementStringIDs.insertLinkConfirmButton].tap()
        app.buttons[elementStringIDs.sourcecodeButton].tap()

        let text = getHTMLContent()
        let expected = "<a href=\"https://wordpress.com/\">text</a>"
        XCTAssertEqual(expected, text)
    }

    func testHorizontalRuler() {
        let richTextField = app.textViews[elementStringIDs.richTextField]
        richTextField.tap()

        app.scrollViews.otherElements.buttons[elementStringIDs.horizontalrulerButton].tap()
        app.buttons[elementStringIDs.sourcecodeButton].tap()

        let text = getHTMLContent()
        let expected = "<hr>"
        XCTAssertEqual(expected, text)
    }

    func testMoreTag() {
        let richTextField = app.textViews[elementStringIDs.richTextField]
        richTextField.tap()

        app.scrollViews.otherElements.buttons[elementStringIDs.moreButton].tap()
        app.buttons[elementStringIDs.sourcecodeButton].tap()

        let text = getHTMLContent()
        let expected = "<!--more-->"
        XCTAssertEqual(expected, text)
    }

    func testHeadingOneText() {
        enterTextInField(text: "text")
        selectAllTextInField()

        app.scrollViews.otherElements.buttons[elementStringIDs.headerButton].tap()
        app.tables.staticTexts[elementStringIDs.header1Button].tap()
        app.buttons[elementStringIDs.sourcecodeButton].tap()

        let text = getHTMLContent()
        let expected = "<h1>text</h1>"
        XCTAssertEqual(expected, text)
    }

    func testHeadingTwoText() {
        enterTextInField(text: "text")
        selectAllTextInField()

        app.scrollViews.otherElements.buttons[elementStringIDs.headerButton].tap()
        app.tables.staticTexts[elementStringIDs.header2Button].tap()
        app.buttons[elementStringIDs.sourcecodeButton].tap()

        let text = getHTMLContent()
        let expected = "<h2>text</h2>"
        XCTAssertEqual(expected, text)
    }

    func testHeadingThreeText() {
        enterTextInField(text: "text")
        selectAllTextInField()

        app.scrollViews.otherElements.buttons[elementStringIDs.headerButton].tap()
        app.tables.staticTexts[elementStringIDs.header3Button].tap()
        app.buttons[elementStringIDs.sourcecodeButton].tap()

        let text = getHTMLContent()
        let expected = "<h3>text</h3>"
        XCTAssertEqual(expected, text)
    }

    func testHeadingFourText() {
        enterTextInField(text: "text")
        selectAllTextInField()

        app.scrollViews.otherElements.buttons[elementStringIDs.headerButton].tap()
        app.tables.element(boundBy: 0).swipeUp()
        app.tables.staticTexts[elementStringIDs.header4Button].tap()
        app.buttons[elementStringIDs.sourcecodeButton].tap()

        let text = getHTMLContent()
        let expected = "<h4>text</h4>"
        XCTAssertEqual(expected, text)
    }

    func testHeadingFiveText() {
        enterTextInField(text: "text")
        selectAllTextInField()

        app.scrollViews.otherElements.buttons[elementStringIDs.headerButton].tap()
        app.tables.element(boundBy: 0).swipeUp()
        app.tables.staticTexts[elementStringIDs.header5Button].tap()
        app.buttons[elementStringIDs.sourcecodeButton].tap()

        let text = getHTMLContent()
        let expected = "<h5>text</h5>"
        XCTAssertEqual(expected, text)
    }

    func testHeadingSixText() {
        enterTextInField(text: "text")
        selectAllTextInField()

        app.scrollViews.otherElements.buttons[elementStringIDs.headerButton].tap()
        app.tables.element(boundBy: 0).swipeUp()
        app.tables.staticTexts[elementStringIDs.header6Button].tap()
        app.buttons[elementStringIDs.sourcecodeButton].tap()

        let text = getHTMLContent()
        let expected = "<h6>text</h6>"
        XCTAssertEqual(expected, text)
    }
}
