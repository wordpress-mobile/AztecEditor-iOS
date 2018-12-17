import Aztec
import XCTest
@testable import Aztec

class HTMLAttachmentRendererTests: XCTestCase {
    
    func testShouldRender() {
        let textView = TextView(
            defaultFont: UIFont.systemFont(ofSize: 12),
            defaultMissingImage: UIImage())
        let goodAttachment = HTMLAttachment()
        let badAttachment = NSTextAttachment(data: nil, ofType: nil)
        let renderer = HTMLAttachmentRenderer(font: UIFont.systemFont(ofSize: 12))
        
        XCTAssertTrue(renderer.textView(textView, shouldRender: goodAttachment))
        XCTAssertFalse(renderer.textView(textView, shouldRender: badAttachment))
    }
    
    func testBoundsForAttachment() {
        let textView = TextView(
            defaultFont: UIFont.systemFont(ofSize: 12),
            defaultMissingImage: UIImage())
        
        textView.frame = CGRect(origin: .zero, size: CGSize(width: 100, height: 100))
        
        let attachment = HTMLAttachment()
        attachment.rawHTML = "<p>hello</p>"
        
        let renderer = HTMLAttachmentRenderer(font: UIFont.systemFont(ofSize: 12))
        
        let lineFragment = CGRect(x: 0, y: 0, width: 100, height: 50)
        
        // These bounds were extracted from an initial successful run.
        let expectedBounds = CGRect(
            x: 41.0,
            y: -3.0,
            width: 18.0,
            height: 15.0)
        
        let bounds = renderer.textView(textView, boundsFor: attachment, with: lineFragment)
        
        XCTAssertEqual(bounds, expectedBounds)
    }
    
    func testImageForAttachmentOfWrongTypeReturnsNil() {
        let textView = TextView(
            defaultFont: UIFont.systemFont(ofSize: 12),
            defaultMissingImage: UIImage())
        let attachment = NSTextAttachment(data: nil, ofType: nil)
        let renderer = HTMLAttachmentRenderer(font: UIFont.systemFont(ofSize: 12))
        
        XCTAssertNil(renderer.textView(textView, imageFor: attachment, with: CGSize(width: 10, height: 10)))
    }
}
