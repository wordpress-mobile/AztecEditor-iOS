import XCTest

class LinkTests: XCTestCase {
        
    private var richEditorPage: EditorPage!
    
    override func setUp() {
        super.setUp()
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIDevice.shared().orientation = .portrait
        XCUIApplication().launch()
        
        let blogsPage = BlogsPage.init()
        richEditorPage = blogsPage.gotoEmptyDemo()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testAddLink() {
        let text = "sample link"
        let url = "https://github.com/wordpress-mobile/AztecEditor-iOS"
        let expectedHTML = "<p><a href=\"\(url)\">\(text)</a></p>"
        
        let html = richEditorPage
            .makeLink()
            .updateURL(url: url)
            .updateName(text: text)
            .ok()
            .switchContentView()
            .getViewContent()

        XCTAssertEqual(html, expectedHTML)
    }
    
    func testMixedLinkFormatting() {
        let text1 = "sample "
        let text2 = "link"
        let url = "https://github.com/wordpress-mobile/AztecEditor-iOS"
        let expectedHTML = "<p>\(text1)<a href=\"\(url)\">\(text2)</a></p>"
        
        let html = richEditorPage
            .enterText(text: text1)
            .makeLink()
            .updateURL(url: url)
            .updateName(text: text2)
            .ok()
            .switchContentView()
            .getViewContent()
        
        XCTAssertEqual(html, expectedHTML)
    }
    
    func testEditLinkURL() {
    let text = "sample link"
    let url1 = "https://github.com/wordpress-mobile"
    let url2 = "https://github.com/wordpress-mobile/AztecEditor-iOS"
    let link = "<a href=\"\(url1)\">\(text)</a>"
    let expectedHTML = "<p><a href=\"\(url2)\">\(text)</a></p>"

    let html = richEditorPage
        .switchContentView()
        .enterText(text: link)
        .switchContentView()
        .makeLink()
        .updateURL(url: url2)
        .ok()
        .switchContentView()
        .getViewContent()
        
        XCTAssertEqual(html, expectedHTML)
    }
    
    func testEditLinkName() {
        let text1 = "sample link"
        let text2 = "updated link"
        let url = "https://github.com/wordpress-mobile/AztecEditor-iOS"
        let link = "<a href=\"\(url)\">\(text1)</a>"
        let expectedHTML = "<p><a href=\"\(url)\">\(text2)</a></p>"

        let html = richEditorPage
            .switchContentView()
            .enterText(text: link)
            .switchContentView()
            .makeLink()
            .updateName(text: text2)
            .ok()
            .switchContentView()
            .getViewContent()
        
        XCTAssertEqual(html, expectedHTML)
    }
    
    func testRemoveLink() {
        let text = "sample link"
        let url = "https://github.com/wordpress-mobile/AztecEditor-iOS"
        let link = "<a href=\"\(url)\">\(text)</a>"
        let expectedText = "<p>\(text)</p>"
        
        let textWithoutLink = richEditorPage
            .switchContentView()
            .enterText(text: link)
            .switchContentView()
            .makeLink()
            .remove()
            .switchContentView()
            .getViewContent()

        XCTAssertEqual(textWithoutLink, expectedText)
    }
    
    func testToggleLinkUnderLine() {
        let text = "sample link"
        let url = "https://github.com/wordpress-mobile/AztecEditor-iOS"
        let link = "<a href=\"\(url)\">\(text)</a>"
        let expectedHTML = "<p><a href=\"\(url)\"><u>\(text)</u></a></p>"

        
        let html = richEditorPage
            .switchContentView()
            .enterText(text: link)
            .switchContentView()
            .selectAllText()
            .toolbarButtonTap(locator: elementStringIDs.underlineButton)
            .switchContentView()
            .getViewContent()
        
        XCTAssertEqual(html, expectedHTML)
    }
}
