import XCTest
@testable import Aztec


// MARK: - PreFormatterTests Tests
//
class PreFormatterTests: XCTestCase {

    /// Verifies that the PreFormatter is not interacting with NSTextAttachment Attributes, that are unrelated
    /// to the formatter's behavior.
    ///
    func testPreFormatterDoesNotLooseAttachmentAttribuesOnRemove() {
        let placeholderAttributes: [String: Any] = [
            NSFontAttributeName: "Value",
            NSParagraphStyleAttributeName: NSParagraphStyle()
        ]

        let stringAttributes: [String: Any] = [
            NSAttachmentAttributeName: NSTextAttachment(),
        ]

        let formatter = PreFormatter(placeholderAttributes: placeholderAttributes)
        let updated = formatter.remove(from: stringAttributes)

        let expectedValue = stringAttributes[NSAttachmentAttributeName] as! NSTextAttachment
        let updatedValue = updated[NSAttachmentAttributeName] as! NSTextAttachment

        XCTAssert(updatedValue == expectedValue)
    }
}
