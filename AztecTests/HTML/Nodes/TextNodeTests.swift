import XCTest
@testable import Aztec


// MARK: - TextNodeTests
//
class TextNodeTests: XCTestCase {

    /// Verifies that two different TextNode(s) return false when equality is checked.
    ///
    func testEqualityOperatorEffectivelyReturnsFalseWhenNodesDiffer() {
        let text1 = TextNode(text: "First Children Here")
        let text2 = TextNode(text: "Second Child!")

        XCTAssert((text1 == text2) == false)
        XCTAssert(text1 != text2)
    }

    /// Verifies that two different ElementNode(s) instances, with the same name and the exact same Children array
    /// return true when equality is checked.
    ///
    func testEqualityOperatorEffectivelyReturnsTrueWhenNodesAreEqual() {
        let text1 = TextNode(text: "First Children Here")
        let text2 = TextNode(text: "First Children Here")

        XCTAssert(text1 == text2)
        XCTAssert(text1 !== text2)
    }
}
