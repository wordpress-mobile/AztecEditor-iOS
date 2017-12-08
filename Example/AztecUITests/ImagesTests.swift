import XCTest

class ImagesTests: XCTestCase {
    
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
    
    func testAddPhoto() {
        let regex = "<p><a href=.+><img src=.+></a></p>"
        
        let html = richEditorPage
            .addImageByOrder(id: 0)
            .switchContentView()
            .getViewContent()
        
        XCTAssert(NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: html))
    }
    
    func testAddPhotoAndText() {
        let sampleText = "sample text sample text sample text"
        let regex = "<p>.+<a href=.+><img src=.+></a></p>"

        let html = richEditorPage
            .enterText(text: sampleText)
            .addImageByOrder(id: 0)
            .switchContentView()
            .getViewContent()

        XCTAssert(NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: html))
    }

    func testAddTwoPhotos() {
        let regex = "<p>.*<img src=.+>.*<img src=.+></p>"
        let imgHTML = "<img src=\"https://examplebloge.files.wordpress.com/2017/02/3def4804-d9b5-11e6-88e6-d7d8864392e0.png\">"
        
        let html = richEditorPage
            .switchContentView()
            .enterText(text: imgHTML)
            .switchContentView()
            .addImageByOrder(id: 0)
            .switchContentView()
            .getViewContent()
        
        XCTAssert(NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: html))
    }

    // Tests the issue described in
    // https://github.com/wordpress-mobile/AztecEditor-Android/issues/196
    func testParsingOfImagesWithLink() {
        let imageHtml = "<a href=\"https://github.com/wordpress-mobile/WordPress-Aztec-Android\"><img src=\"https://examplebloge.files.wordpress.com/2017/02/3def4804-d9b5-11e6-88e6-d7d8864392e0.png\"></a>"
        let expectedHTML = "<p>" + imageHtml + "</p>"
        
        let html = richEditorPage
            .switchContentView()
            .enterText(text: imageHtml)
            .switchContentView()
            .switchContentView()
            .getViewContent()
        
        XCTAssertEqual(html, expectedHTML)
    }
}

