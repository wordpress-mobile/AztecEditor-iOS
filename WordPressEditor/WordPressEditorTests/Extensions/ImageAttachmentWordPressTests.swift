import Aztec
import XCTest
@testable import WordPressEditor

class ImageAttachmentWordPressTests: XCTestCase {
    
    func testAltSetter() {
        let imageAttachment = ImageAttachment(identifier: "testing")
        let alt = "Some text"
        
        XCTAssertEqual(imageAttachment.extraAttributes["alt"], nil)
        
        imageAttachment.alt = alt
        XCTAssertEqual(imageAttachment.extraAttributes["alt"], .string(alt))
        
        imageAttachment.alt = nil
        XCTAssertEqual(imageAttachment.extraAttributes["alt"], nil)
    }
    
    func testAltGetter() {
        let imageAttachment = ImageAttachment(identifier: "testing")
        let alt = "Some text"
        
        XCTAssertEqual(imageAttachment.alt, nil)
        
        imageAttachment.extraAttributes["alt"] = .string(alt)
        XCTAssertEqual(imageAttachment.alt, alt)
        
        imageAttachment.extraAttributes["alt"] = nil
        XCTAssertEqual(imageAttachment.alt, nil)
    }
    
    func testWidthSetter() {
        let imageAttachment = ImageAttachment(identifier: "testing")
        let width = 500
        
        XCTAssertEqual(imageAttachment.extraAttributes["width"], nil)
        
        imageAttachment.width = width
        XCTAssertEqual(imageAttachment.extraAttributes["width"], .string(String(width)))
        
        imageAttachment.width = nil
        XCTAssertEqual(imageAttachment.extraAttributes["width"], nil)
    }
    
    func testWidthGetter() {
        let imageAttachment = ImageAttachment(identifier: "testing")
        let width = 500
        
        XCTAssertEqual(imageAttachment.width, nil)
        
        imageAttachment.extraAttributes["width"] = .string(String(width))
        XCTAssertEqual(imageAttachment.width, width)
        
        imageAttachment.extraAttributes["width"] = nil
        XCTAssertEqual(imageAttachment.width, nil)
    }
    
    func testHeightSetter() {
        let imageAttachment = ImageAttachment(identifier: "testing")
        let height = 500
        
        XCTAssertEqual(imageAttachment.extraAttributes["height"], nil)
        
        imageAttachment.height = height
        XCTAssertEqual(imageAttachment.extraAttributes["height"], .string(String(height)))
        
        imageAttachment.height = nil
        XCTAssertEqual(imageAttachment.extraAttributes["height"], nil)
    }
    
    func testHeightGetter() {
        let imageAttachment = ImageAttachment(identifier: "testing")
        let height = 500
        
        XCTAssertEqual(imageAttachment.height, nil)
        
        imageAttachment.extraAttributes["height"] = .string(String(height))
        XCTAssertEqual(imageAttachment.height, height)
        
        imageAttachment.extraAttributes["height"] = nil
        XCTAssertEqual(imageAttachment.height, nil)
    }
    
    func testImageIDNilWhenNotSet() {
        let imageAttachment = ImageAttachment(identifier: "testing")
        
        XCTAssertEqual(imageAttachment.imageID, nil)
    }
    
    func testImageIDChangesWhenExtraAttributeChanges() {
        let imageAttachment = ImageAttachment(identifier: "testing")
        
        XCTAssertEqual(imageAttachment.imageID, nil)
        
        imageAttachment.extraAttributes["class"] = .string("some-class")
        XCTAssertEqual(imageAttachment.imageID, nil)
        
        imageAttachment.extraAttributes["class"] = .string("wp-image-200")
        XCTAssertEqual(imageAttachment.imageID, 200)
        
        imageAttachment.extraAttributes["class"] = .string("otherclass wp-image-400 ignoredclass")
        XCTAssertEqual(imageAttachment.imageID, 400)
    }
    
    func testImageIDChangesExtraAttributes() {
        let imageAttachment = ImageAttachment(identifier: "testing")
        
        imageAttachment.extraAttributes["class"] = .string("some-attributes some-more-attributes")
        
        imageAttachment.imageID = 200
        XCTAssertEqual(imageAttachment.extraAttributes["class"], .string("some-attributes some-more-attributes wp-image-200"))
        
        imageAttachment.imageID = 400
        XCTAssertEqual(imageAttachment.extraAttributes["class"], .string("some-attributes some-more-attributes wp-image-400"))
    }
    
    func testImageIDSetToNilChangesExtraAttributes() {
        let imageAttachment = ImageAttachment(identifier: "testing")
        
        imageAttachment.extraAttributes["class"] = .string("wp-image-200")
        imageAttachment.imageID = nil
        XCTAssertEqual(imageAttachment.extraAttributes["class"], nil)
        
        imageAttachment.extraAttributes["class"] = .string("wp-image-200 some-other-class")
        imageAttachment.imageID = nil
        XCTAssertEqual(imageAttachment.extraAttributes["class"], .string("some-other-class"))
    }
}
