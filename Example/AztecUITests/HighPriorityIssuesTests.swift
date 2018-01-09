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
        app.launchArguments = ["NoAnimations"]
        app.activate()
        
        let blogsPage = BlogsPage()
        richEditorPage = blogsPage.gotoEmptyDemo()
    }
    
    override func tearDown() {
        _ = richEditorPage.gotoRootPage()
        super.tearDown()
    }
        
    // Github issue https://github.com/wordpress-mobile/AztecEditor-iOS/issues/675
    func testInfiniteLoopOnAssetDownload() {
        _ = richEditorPage
            .switchContentView()
            .enterText(text: "<img src=\"https://someinvalid.url/with-an-invalid-resource\">")
            .switchContentView()
            .gotoRootPage()
            .gotoEmptyDemo()
   }
    
    // Github issue https://github.com/wordpress-mobile/AztecEditor-iOS/issues/465
    func testTypeAfterInvalidHTML() {
        let invalidHTML = "<qaz!>"
        let textAfterHTML = "Some text after invalid HTML tag"
        let expectedHTML = "<p><qaz></qaz>Some text after invalid HTML tag</p>"

        let html = richEditorPage
                    .switchContentView()
                    .enterText(text: invalidHTML)
                    .switchContentView()
                    .tapLineNumber(10)
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
        
        richEditorPage.enterText(text: "q")
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

        let text = demoEditorPage
            .selectAllText()
            .getViewContent()

        XCUIApplication().menuItems[elementStringIDs.copyButton].tap()
        demoEditorPage.textView.tap()

        demoEditorPage.textView.swipeDown()
        demoEditorPage.textView.swipeDown()
        demoEditorPage.textView.swipeDown()
        demoEditorPage.textView.swipeDown()


        demoEditorPage.textView.press(forDuration: 1)

        let pasteButton = app.menuItems[elementStringIDs.pasteButton]
        _ = pasteButton.waitForExistence(timeout: demoEditorPage.waitTimeout)
        pasteButton.tap()

        sleep(3) // to make sure everything is updated

        let newText = demoEditorPage.getViewContent()
        XCTAssertEqual(newText, text + text)
    }
}
