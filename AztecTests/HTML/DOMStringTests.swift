import XCTest
@testable import Aztec

class DOMStringTests: XCTestCase {

    typealias DOMString = Aztec.Libxml2.DOMString

    /// This unit test was created due to a bug we found in this method, when first adding text
    /// with `preferLeftNode == true` and then adding some more with `preferLeftNode == false`.
    ///
    /// Link to the original bug report here:
    /// https://github.com/wordpress-mobile/WordPress-Aztec-iOS/issues/319
    ///
    /// Input:
    ///     - Insert "Hello\n" with `preferLeftNode == true`
    ///     - Insert "World!" with `preferLeftNode == false`
    ///
    /// Output:
    ///     - Make sure the HTML is updated accordingly at each step.
    ///
    func testReplaceCharactersWithStringEffectivelyInsertsTheNewString() {
        let string = DOMString()

        string.replaceCharacters(inRange: NSRange.zero, withString: "Hello\n")
        XCTAssertEqual(string.getHTML(), "Hello<br>")

        string.replaceCharacters(inRange: NSRange(location: 6, length: 0), withString: "World!")
        XCTAssertEqual(string.getHTML(), "Hello<br>World!")
    }


    /// This test ensures that replace with rawHTML generates the expected HTML.
    ///
    /// Input:
    ///     - Insert "<unknown>plain</unknown>"
    ///     - Insert "<b>prepended</b>"
    ///
    /// Output:
    ///     - Verify the Updated HTML at each step.
    ///
    func testReplaceWithRawHtmlCreatesNewInternalNodes() {
        let string = DOMString()

        string.replace(NSRange.zero, withRawHTML: "<unknown>plain</unknown>")
        XCTAssertEqual(string.getHTML(), "<unknown>plain</unknown>")

        string.replace(NSRange.zero, withRawHTML: "<b>prepended</b>")
        XCTAssertEqual(string.getHTML(), "<unknown><b>prepended</b>plain</unknown>")
    }
}
