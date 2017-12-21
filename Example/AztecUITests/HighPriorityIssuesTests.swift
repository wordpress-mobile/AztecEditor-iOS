import XCTest

class HighPriorityIssuesTests: XCTestCase {
        
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
        
        let blogsPage = BlogsPage.init()
        richEditorPage = blogsPage.gotoEmptyDemo()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // Github issue https://github.com/wordpress-mobile/AztecEditor-iOS/issues/385
    func testLongTitle() {
        let longTitle = "long title in a galaxy not so far away"
        // Title heigh contains of actual textfield height + bottom line.
        // 16px - is the height of that bottom line. Its not changing with different font sizes
        let titleTextView = app.textViews[elementStringIDs.titleTextField]
        let titleLineHeight = titleTextView.frame.height - 16
        let oneLineTitleHeight = titleTextView.frame.height
        titleTextView.tap()
        
        // TODO: Move it into EditorPage
        if isIPhone() {
            titleTextView.typeText(String(repeating: "very ", count: 6) + longTitle)
        } else {
            titleTextView.typeText(String(repeating: "very ", count: 20) + longTitle)
        }
        
        let twoLineTitleHeight = titleTextView.frame.height
        XCTAssert(twoLineTitleHeight - oneLineTitleHeight >= titleLineHeight )
    }
    
    // Github issue https://github.com/wordpress-mobile/AztecEditor-iOS/issues/675
    func testInfiniteLoopOnAssetDownload() {
        let blogsPage = richEditorPage
            .switchContentView()
            .enterText(text: "<img src=\"https://someinvalid.url/with-an-invalid-resource\">")
            .switchContentView()
            .gotoRootPage()

        XCTAssert(blogsPage.isLoaded(), "blogsPage isn't loaded. Are you on the right page?")
   }
    
    // Github issue https://github.com/wordpress-mobile/AztecEditor-iOS/issues/465
    func testTypeAfterInvalidHTML() {
        let invalidHTML = "<qaz!>"
        let textAfterHTML = "Some text after invalid HTML tag"
        let expectedHTML = "<p><qaz></qaz>Some text after invalid HTML tag</p>"
        let frame = richEditorPage.textView.frame
        
        let html = richEditorPage
                    .switchContentView()
                    .enterText(text: invalidHTML)
                    .switchContentView()
                    .tapByCordinates(x: Int(frame.width), y: 0)
                    .enterText(text: textAfterHTML)
                    .switchContentView()
                    .getViewContent()

        XCTAssertEqual(html, expectedHTML)
    }
    
    // Github issue https://github.com/wordpress-mobile/AztecEditor-iOS/issues/768
    func testLooseStylesNoContent() {
        let boldButton = richEditorPage.boldButton
        let italicButton = richEditorPage.italicButton

        XCTAssert(!boldButton.isSelected && !italicButton.isSelected)
        boldButton.tap()
        italicButton.tap()
        
        enterTextInField(text: "q")
        let deleteButton = app.keys["delete"]
        deleteButton.tap()
        deleteButton.tap()
        XCTAssert(boldButton.isSelected && italicButton.isSelected)
    }
    
    // Github issue https://github.com/wordpress-mobile/AztecEditor-iOS/issues/771
    func testCopyPasteCrash() {
        let demoEditorPage = richEditorPage
            .gotoRootPage()
            .gotoDemo()
            .switchContentView()
            .selectAllText()
        
        let text = demoEditorPage.getViewContent()
        XCUIApplication().menuItems[elementStringIDs.copyButton].tap()
        demoEditorPage.textView.tap()

        demoEditorPage.textView.swipeDown()
        demoEditorPage.textView.swipeDown()
        demoEditorPage.textView.swipeDown()
        demoEditorPage.textView.swipeDown()

        demoEditorPage.textView.coordinate(withNormalizedOffset:CGVector.zero).press(forDuration: 1)
        app.menuItems[elementStringIDs.pasteButton].tap()
        sleep(3) // to make sure everything is updated
        let newText = demoEditorPage.getViewContent()
        
        XCTAssertEqual(newText, text + text)
    }
}


