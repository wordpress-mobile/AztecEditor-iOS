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
    
    func testImageForAttachment() {
        let textView = TextView(
            defaultFont: UIFont.systemFont(ofSize: 12),
            defaultMissingImage: UIImage())
        let attachment = CommentAttachment()
        attachment.text = "Some comment!"
        let renderer = CommentAttachmentRenderer(font: UIFont.systemFont(ofSize: 12))
        
        let fileName: String = {
            if UIScreen.main.scale == 3 {
                return "CommentAttachmentRender_3x.png"
            } else if UIScreen.main.scale == 2 {
                return "CommentAttachmentRender_2x.png"
            }
            
            // We no longer support 1x
            fatalError()
        }()
        
        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(forResource: fileName, withExtension: "dat", subdirectory: nil),
            let expectedPNGRepresentation = try? Data(contentsOf: url, options: []) else {
                XCTFail()
                return
        }
        
        let desiredSize = CGSize(width: 100, height: 44.0)
        
        guard let image = renderer.textView(textView, imageFor: attachment, with: desiredSize),
            let pngRepresentation = UIImagePNGRepresentation(image) else {
                XCTFail()
                return
        }
        
        XCTAssertNotNil(pngRepresentation)
        XCTAssertEqual(pngRepresentation, expectedPNGRepresentation)
    }
}
