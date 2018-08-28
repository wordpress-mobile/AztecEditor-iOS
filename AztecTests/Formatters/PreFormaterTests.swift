import XCTest
@testable import Aztec


// MARK: - PreFormatterTests Tests
//
class PreFormatterTests: XCTestCase {

    /// Verifies that the PreFormatter is not interacting with NSTextAttachment Attributes, that are unrelated
    /// to the formatter's behavior.
    ///
    func testPreFormatterDoesNotLooseAttachmentAttribuesOnRemove() {
        let placeholderAttributes: [NSAttributedString.Key: Any] = [
            .font: "Value",
            .paragraphStyle: NSParagraphStyle()
        ]

        let stringAttributes: [NSAttributedString.Key: Any] = [
            .attachment: NSTextAttachment(),
        ]

        let formatter = PreFormatter(placeholderAttributes: placeholderAttributes)
        let updated = formatter.remove(from: stringAttributes)

        let expectedValue = stringAttributes[.attachment] as! NSTextAttachment
        let updatedValue = updated[.attachment] as! NSTextAttachment

        XCTAssert(updatedValue == expectedValue)
    }
    
    /// Tests that the Pre formatter doesn't drop the inherited ParagraphStyle.
    ///
    /// Issue:
    /// https://github.com/wordpress-mobile/AztecEditor-iOS/issues/993
    ///
    func testPreFormatterDoesNotDropInheritedParagraphStyle(){
        let placeholderAttributes: [NSAttributedString.Key: Any] = [
            .font: "Value",
            .paragraphStyle: NSParagraphStyle()
        ]
        
        let div = HTMLDiv(with: nil)
        let paragraphStyle = ParagraphStyle()
        
        paragraphStyle.appendProperty(div)
        
        let previousAttributes: [NSAttributedString.Key: Any] = [.paragraphStyle: paragraphStyle]
        
        let formatter = PreFormatter(placeholderAttributes: placeholderAttributes)
        let newAttributes = formatter.apply(to: previousAttributes, andStore: nil)
        
        guard let newParagraphStyle = newAttributes[.paragraphStyle] as? ParagraphStyle else {
            XCTFail()
            return
        }
        
        XCTAssert(newParagraphStyle.hasProperty(where: { property -> Bool in
            return property === div
        }))
    }
}
