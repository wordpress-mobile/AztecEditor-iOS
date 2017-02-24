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
    func testReplaceCharacters() {
        let string = DOMString()

        string.replaceCharacters(inRange: NSRange.zero, withString: "Hello\n", preferLeftNode: true)
        XCTAssertEqual(string.getHTML(), "Hello<br>")

        string.replaceCharacters(inRange: NSRange(location: 13, length: 0), withString: "World!", preferLeftNode: false)
        XCTAssertEqual(string.getHTML(), "Hello<br>World!")
    }
}
