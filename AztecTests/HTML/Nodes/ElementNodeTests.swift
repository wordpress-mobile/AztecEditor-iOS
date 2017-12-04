import XCTest
@testable import Aztec


// MARK: - ElementNodeTests
//
class ElementNodeTests: XCTestCase {

    /// Verifies that two different ElementNode(s), with the same name, yet, different Children array, return
    /// false when equality is checked.
    ///
    func testEqualityOperatorEffectivelyReturnsFalseWhenNodesDiffer() {
        let text1 = TextNode(text: "First Children Here")
        let attribute1 = Attribute(name: "some", value: .string("value"))
        let style1 = ElementNode(name: "style", attributes: [attribute1], children: [text1])

        let text2 = TextNode(text: "Second Child!")
        let style2 = ElementNode(name: "style", attributes: [attribute1], children: [text2])

        XCTAssert((style1 == style2) == false)
        XCTAssert(style1 != style2)
        XCTAssert(style1 == style1)
    }


    /// Verifies that two different ElementNode(s) instances, with the same name and the exact same Children array
    /// return true when equality is checked.
    ///
    func testEqualityOperatorEffectivelyReturnsTrueWhenNodesAreEqual() {
        let text1 = TextNode(text: "First Children Here")
        let attribute1 = Attribute(name: "some", value: .string("value"))
        let style1 = ElementNode(name: "style", attributes: [attribute1], children: [text1])

        let text2 = TextNode(text: "First Children Here")
        let attribute2 = Attribute(name: "some", value: .string("value"))
        let style2 = ElementNode(name: "style", attributes: [attribute2], children: [text2])

        XCTAssert(style1 == style2)
        XCTAssert(style1 !== style2)
    }


    /// Verifies that `onlyChild` returns the receiver's only child, if it's type matches with the specified one.
    ///
    func testOnlyChildReturnsSingleChildrenIfItRepresentsAnImage() {
        let image = ElementNode(type: .img)
        let parent = ElementNode(type: .a, attributes: [], children: [image])

        XCTAssertEqual(parent.onlyChild(ofType: .img), image)
    }


    /// Verifies that `onlyChild` returns nil, if there is more than one children, no matter if their type match with the specified one.
    ///
    func testOnlyChildReturnsNilIfThereIsMoreThanOneChild() {
        let image = ElementNode(type: .img)
        let parent = ElementNode(type: .a, attributes: [], children: [image, image])

        XCTAssertNil(parent.onlyChild(ofType: .img))
    }


    /// Verifies that `onlyChild` returns nil, if there is at least one child, but with different type.
    ///
    func testOnlyChildReturnsNilIfThereIsNoMatchingChild() {
        let image = ElementNode(type: .img)
        let parent = ElementNode(type: .a, attributes: [], children: [image])

        XCTAssertNil(parent.onlyChild(ofType: .b))
    }
}
