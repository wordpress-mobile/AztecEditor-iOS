import XCTest
@testable import Aztec


// MARK: - PreFormatterTests Tests
//
class PreFormatterTests: XCTestCase {

    /// Verifies that the PreFormatter is not interacting with NSTextAttachment Attributes, that are unrelated
    /// to the formatter's behavior.
    ///
    func testPreFormatterDoesNotLooseAttachmentAttribuesOnRemove() {
        let placeholderAttributes: [AttributedStringKey: Any] = [
            .font: "Value",
            .paragraphStyle: NSParagraphStyle()
        ]

        let stringAttributes: [AttributedStringKey: Any] = [
            .attachment: NSTextAttachment(),
        ]

        let formatter = PreFormatter(placeholderAttributes: placeholderAttributes)
        let updated = formatter.remove(from: stringAttributes)

        let expectedValue = stringAttributes[.attachment] as! NSTextAttachment
        let updatedValue = updated[.attachment] as! NSTextAttachment

        XCTAssert(updatedValue == expectedValue)
    }
}
