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
        let goodAttachment = CommentAttachment()
        let badAttachment = NSTextAttachment(data: nil, ofType: nil)
        let textView = TextViewStub()
        
        XCTAssertTrue(renderer.textView(textView, shouldRender: goodAttachment))
        XCTAssertFalse(renderer.textView(textView, shouldRender: badAttachment))
    }
    
    func testBoundsForAttachment() {
        let textView = TextView(
            defaultFont: UIFont.systemFont(ofSize: 12),
            defaultMissingImage: UIImage())
        
        textView.frame = CGRect(origin: .zero, size: CGSize(width: 100, height: 100))
        
        let attachment = CommentAttachment()
        attachment.text = "Some comment!"
        
        let renderer = CommentAttachmentRenderer(font: .systemFont(ofSize: 12))
        
        let lineFragment = CGRect(x: 0, y: 0, width: 100, height: 50)
        
        // These bounds were extracted from an initial successful run.
        let expectedBounds = CGRect(
            x: 14.0,
            y: -3.0,
            width: 72.0,
            height: 15.0)
        
        let bounds = renderer.textView(textView, boundsFor: attachment, with: lineFragment)
        
        XCTAssertEqual(bounds, expectedBounds)
    }

    func testImageForGutenbergCommentIsNil() {
        // Given
        let textView = TextViewStub()
        let gutenbergComment = CommentAttachment()
        gutenbergComment.text = "wp:paragraph"
        let renderer = CommentAttachmentRenderer(font: .systemFont(ofSize: 12))

        // When
        let image = renderer.textView(textView, imageFor: gutenbergComment, with: .init(width: 2, height: 2))

        // Then
        XCTAssertNil(image)
    }

    func testRenderingImageWithIllegalSizeReturnsNil() {
        // Given
        let textView = TextViewStub()
        let attachment = CommentAttachment()
        let renderer = CommentAttachmentRenderer(font: .systemFont(ofSize: 12))

        // When
        let image = renderer.textView(textView, imageFor: attachment, with: .init(width: -1, height: -1))

        // Then
        XCTAssertNil(image)
    }
}
