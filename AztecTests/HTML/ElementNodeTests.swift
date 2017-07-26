import XCTest
@testable import Aztec


// MARK: ElementNodeTests
//
class ElementNodeTests: XCTestCase {

    /// Verifies that two different ElementNode(s), with the same name, yet, different Children array, return
    /// false when equality is checked.
    ///
    func testEqualityOperatorEffectivelyReturnsFalseWhenNodesDiffer() {
        let text1 = TextNode(text: "First Children Here")
        let style1 = ElementNode(name: "style", attributes: [], children: [text1])

        let text2 = TextNode(text: "Second Child!")
        let style2 = ElementNode(name: "style", attributes: [], children: [text2])

        XCTAssert((style1 == style2) == false)
        XCTAssert(style1 != style2)
    }
}
