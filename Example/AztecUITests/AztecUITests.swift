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

        let richTextField = app.textViews[elementStringIDs.richTextField]
        richTextField.tap()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testSimpleBoldText() {
        enterTextInField(text: "1")
        selectAllTextInField()

        app.scrollViews.otherElements.buttons[elementStringIDs.boldButton].tap()

        let text = getHTMLContent()
        let expected = "<strong>1</strong>"
        XCTAssertEqual(expected, text)
    }

    func testSimpleItalicText() {
        enterTextInField(text: "1")
        selectAllTextInField()

        app.scrollViews.otherElements.buttons[elementStringIDs.italicButton].tap()

        let text = getHTMLContent()
        let expected = "<em>1</em>"
        XCTAssertEqual(expected, text)
    }

    func testSimpleUnderlineText() {
        enterTextInField(text: "1")
        selectAllTextInField()

        app.scrollViews.otherElements.buttons[elementStringIDs.underlineButton].tap()

        let text = getHTMLContent()
        let expected = "<u>1</u>"
        XCTAssertEqual(expected, text)
    }

    func testSimpleStrikethroughText() {
        enterTextInField(text: "1")
        selectAllTextInField()

        app.scrollViews.otherElements.buttons[elementStringIDs.strikethroughButton].tap()

        let text = getHTMLContent()
        let expected = "<del>1</del>"
        XCTAssertEqual(expected, text)
    }

    func testSimpleBlockquoteText() {
        enterTextInField(text: "1")
        selectAllTextInField()

        app.scrollViews.otherElements.buttons[elementStringIDs.blockquoteButton].tap()

        let text = getHTMLContent()
        let expected = "<blockquote>1</blockquote>"
        XCTAssertEqual(expected, text)
    }

    // Enable this test after unordered lists are fully implemented
    /*
    func testSimpleUnorderedListText() {
        enterTextInField(text: "1")
        selectAllTextInField()

        app.scrollViews.otherElements.buttons[elementStringIDs.unorderedlistButton].tap()

        let text = getHTMLContent()
        let expected = "<ul><li>1</li></ul>"
        XCTAssertEqual(expected, text)
    }
    */

    // Enable this test after ordered lists are fully implemented
    /*
    func testSimpleOrderedListText() {
        enterTextInField(text: "1")
        selectAllTextInField()

        app.scrollViews.otherElements.buttons[elementStringIDs.orderedlistButton].tap()

        let text = getHTMLContent()
        let expected = "<ol><li>1</li></ol>"
        XCTAssertEqual(expected, text)
    }
    */

    func testSimpleLinkedText() {
        enterTextInField(text: "1")
        selectAllTextInField()

        // Copy link to be auto-filled in URL field
        UIPasteboard.general.string = "https://wordpress.com/"
        app.scrollViews.otherElements.buttons[elementStringIDs.linkButton].tap()
        app.alerts.buttons[elementStringIDs.insertLinkConfirmButton].tap()

        let text = getHTMLContent()
        let expected = "<a href=\"https://wordpress.com/\">1</a>"
        XCTAssertEqual(expected, text)
    }

    func testSimpleUnderlineLinkedText() {
        enterTextInField(text: "1")
        selectAllTextInField()

        // Copy link to be auto-filled in URL field
        UIPasteboard.general.string = "https://wordpress.com/"
        app.scrollViews.otherElements.buttons[elementStringIDs.linkButton].tap()
        app.alerts.buttons[elementStringIDs.insertLinkConfirmButton].tap()

        let text = getHTMLContent()
        let expected = "<a href=\"https://wordpress.com/\"><u>1</u></a>"
        XCTAssertEqual(expected, text)
    }


    func testHorizontalRuler() {
        app.scrollViews.otherElements.buttons[elementStringIDs.horizontalrulerButton].tap()

        let text = getHTMLContent()
        let expected = "<hr>"
        XCTAssertEqual(expected, text)
    }

    func testHorizontalRulerWithText() {
        enterTextInField(text: "1\n")
        app.scrollViews.otherElements.buttons[elementStringIDs.horizontalrulerButton].tap()
        enterTextInField(text: "\n2")

        let text = getHTMLContent()
        let expected = "1<br><hr><br>2"
        XCTAssertEqual(expected, text)
    }

    func testMoreTag() {
        app.scrollViews.otherElements.buttons[elementStringIDs.moreButton].tap()

        let text = getHTMLContent()
        let expected = "<!--more-->"
        XCTAssertEqual(expected, text)
    }

    func testMoreTagWithText() {
        enterTextInField(text: "1\n")
        app.scrollViews.otherElements.buttons[elementStringIDs.moreButton].tap()
        enterTextInField(text: "\n2")

        let text = getHTMLContent()
        let expected = "1<br><!--more--><br>2"
        XCTAssertEqual(expected, text)
    }

    func testHeadingOneText() {
        enterTextInField(text: "1")
        selectAllTextInField()

        app.scrollViews.otherElements.buttons[elementStringIDs.headerButton].tap()
        app.tables.staticTexts[elementStringIDs.header1Button].tap()

        let text = getHTMLContent()
        let expected = "<h1>1</h1>"
        XCTAssertEqual(expected, text)
    }

    func testHeadingTwoText() {
        enterTextInField(text: "1")
        selectAllTextInField()

        app.scrollViews.otherElements.buttons[elementStringIDs.headerButton].tap()
        app.tables.staticTexts[elementStringIDs.header2Button].tap()

        let text = getHTMLContent()
        let expected = "<h2>1</h2>"
        XCTAssertEqual(expected, text)
    }

    func testHeadingThreeText() {
        enterTextInField(text: "1")
        selectAllTextInField()

        app.scrollViews.otherElements.buttons[elementStringIDs.headerButton].tap()
        app.tables.staticTexts[elementStringIDs.header3Button].tap()

        let text = getHTMLContent()
        let expected = "<h3>1</h3>"
        XCTAssertEqual(expected, text)
    }

    func testHeadingFourText() {
        enterTextInField(text: "1")
        selectAllTextInField()

        app.scrollViews.otherElements.buttons[elementStringIDs.headerButton].tap()
        app.tables.element(boundBy: 0).swipeUp()
        app.tables.staticTexts[elementStringIDs.header4Button].tap()

        let text = getHTMLContent()
        let expected = "<h4>1</h4>"
        XCTAssertEqual(expected, text)
    }

    func testHeadingFiveText() {
        enterTextInField(text: "1")
        selectAllTextInField()

        app.scrollViews.otherElements.buttons[elementStringIDs.headerButton].tap()
        app.tables.element(boundBy: 0).swipeUp()
        app.tables.staticTexts[elementStringIDs.header5Button].tap()

        let text = getHTMLContent()
        let expected = "<h5>1</h5>"
        XCTAssertEqual(expected, text)
    }

    func testHeadingSixText() {
        enterTextInField(text: "1")
        selectAllTextInField()

        app.scrollViews.otherElements.buttons[elementStringIDs.headerButton].tap()
        app.tables.element(boundBy: 0).swipeUp()
        app.tables.staticTexts[elementStringIDs.header6Button].tap()

        let text = getHTMLContent()
        let expected = "<h6>1</h6>"
        XCTAssertEqual(expected, text)
    }
}
