import XCTest
@testable import Aztec

class ShortcodeAttributeSerializerTests: XCTestCase {

    /// Verifies that HTMLAttributes's toString method properly serializes all of the named and unnamed attributes.
    ///
    func testSerialization() {
        let shortcodeAttributeSerializer = ShortcodeAttributeSerializer()
        
        let attributes: [String: ShortcodeAttributeValue] = [
            "yo": .string("semite"),
            "moo": .nil,
            "mav": .string("ericks"),
        ]
        
        let output = shortcodeAttributeSerializer.serialize(attributes)
        let expected = "yo=\"semite\" moo mav=\"ericks\""
        
        XCTAssertEqual(output, expected)
    }
}
