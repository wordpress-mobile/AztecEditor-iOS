import XCTest
@testable import Aztec


// MARK: - HTMLAttributesTests
//
class HTMLAttributesTests: XCTestCase {

    /// Verifies that HTMLAttributes's toString method properly serializes all of the named and unnamed attributes.
    ///
    func testToStringProperlySerializesHTMLAttributes() {
        let named = ["yo": "semite", "mav": "ericks"]
        let unamed = ["moo"]

        let sample = HTMLAttributes(named: named, unamed: unamed)

        let expected = "yo=\"semite\" mav=\"ericks\" moo"
        XCTAssertEqual(expected, sample.toString())
    }
}
