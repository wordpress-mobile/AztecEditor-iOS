import XCTest
@testable import Aztec

class CommentAttachmentRendererTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testShouldRender() {
        let renderer = CommentAttachmentRenderer(font: .systemFont(ofSize: 12))
        let commentAttachment = CommentAttachment()
        
        let textView = TextViewStub()
        
        XCTAssertTrue(renderer.textView(textView, shouldRender: commentAttachment))
    }
}
