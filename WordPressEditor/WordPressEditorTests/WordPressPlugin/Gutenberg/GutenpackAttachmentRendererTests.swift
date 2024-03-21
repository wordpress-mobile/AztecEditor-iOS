import Aztec
import XCTest
@testable import WordPressEditor

class GutenpackAttachmentRendererTests: XCTestCase {
    
    func testShouldRender() {
        let textView = TextView(
            defaultFont: UIFont.systemFont(ofSize: 12),
            defaultMissingImage: UIImage())
        let goodAttachment = GutenpackAttachment(name: "name", content: "content")
        let badAttachment = NSTextAttachment(data: nil, ofType: nil)
        let renderer = GutenpackAttachmentRenderer()
        
        XCTAssertTrue(renderer.textView(textView, shouldRender: goodAttachment))
        XCTAssertFalse(renderer.textView(textView, shouldRender: badAttachment))
    }
    
    func testBoundsForAttachment() {
        let textView = TextView(
            defaultFont: UIFont.systemFont(ofSize: 12),
            defaultMissingImage: UIImage())
        
        textView.frame = CGRect(origin: .zero, size: CGSize(width: 100, height: 100))
        
        let attachment = GutenpackAttachment(name: "name", content: "content")
        let renderer = GutenpackAttachmentRenderer()
        
        let lineFragment = CGRect(x: 0, y: 0, width: 100, height: 50)
        let lineFragmentPadding = textView.textContainer.lineFragmentPadding
        let expectedBounds = CGRect(
            x: 0,
            y: 0,
            width: textView.frame.width - (2 * lineFragmentPadding),
            height: GutenpackAttachmentRenderer.Constants.defaultHeight)
        
        let bounds = renderer.textView(textView, boundsFor: attachment, with: lineFragment)
        
        XCTAssertEqual(bounds, expectedBounds)
    }
    
    func testImageForAttachmentOfWrongTypeReturnsNil() {
        let textView = TextView(
            defaultFont: UIFont.systemFont(ofSize: 12),
            defaultMissingImage: UIImage())
        let attachment = NSTextAttachment(data: nil, ofType: nil)
        let renderer = GutenpackAttachmentRenderer()
        
        XCTAssertNil(renderer.textView(textView, imageFor: attachment, with: CGSize(width: 10, height: 10)))
    }
    
    func testImageForAttachment() {
        let textView = TextView(
            defaultFont: UIFont.systemFont(ofSize: 12),
            defaultMissingImage: UIImage())
        let attachment = GutenpackAttachment(name: "name", content: "content")
        let renderer = GutenpackAttachmentRenderer()
        
        let fileName: String = {
            if UIScreen.main.scale == 3 {
                return "GutenpackAttachmentRender_3x"
            } else if UIScreen.main.scale == 2 {
                return "GutenpackAttachmentRender_2x"
            }
            
            // We no longer support 1x
            fatalError()
        }()
        
        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(forResource: fileName, withExtension: "png", subdirectory: nil),
            let expectedPNGRepresentation = try? Data(contentsOf: url, options: []) else {
                XCTFail()
                return
        }
        
        let desiredSize = CGSize(width: 100, height: GutenpackAttachmentRenderer.Constants.defaultHeight)
        
        guard let image = renderer.textView(textView, imageFor: attachment, with: desiredSize),
            let pngRepresentation = image.pngData() else {
                XCTFail()
                return
        }
        
        XCTAssertNotNil(pngRepresentation)
        XCTAssertEqual(pngRepresentation, expectedPNGRepresentation)
    }
}
