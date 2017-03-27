import XCTest
@testable import Aztec

class DOMInspectorTests: XCTestCase {

    typealias DOMInspector = Libxml2.DOMInspector
    typealias ElementNode = Libxml2.ElementNode
    typealias RootNode = Libxml2.RootNode
    typealias StandardElementType = Libxml2.StandardElementType
    typealias TextNode = Libxml2.TextNode

    /// Tests that `findSiblings(separatedAt:)` works properly.
    ///
    /// - Input:
    ///     - HTML: "<root><strong>bold</strong><em>italic</em></root>"
    ///     - Separation location: 4
    ///
    /// - Expected results:
    ///     - Both the bold and italic nodes should be returned.
    ///
    func testFindSiblings() {
        let textNode1 = TextNode(text: "bold")
        let textNode2 = TextNode(text: "italic")

        let boldNode = ElementNode(name: StandardElementType.b.rawValue, attributes: [], children: [textNode1])
        let italicNode = ElementNode(name: StandardElementType.i.rawValue, attributes: [], children: [textNode2])
        let rootNode = RootNode(children: [boldNode, italicNode])

        let inspector = DOMInspector(with: rootNode)

        let siblings = inspector.findSiblings(separatedAt: textNode1.length())

        XCTAssertNotNil(siblings)
        XCTAssertEqual(siblings?.leftSibling, boldNode)
        XCTAssertEqual(siblings?.rightSibling, italicNode)
    }

    /// Tests that `findSiblings(separatedAt:)` works properly.
    ///
    /// - Input:
    ///     - HTML: "<root><strong>bold</strong><em>italic</em></root>"
    ///     - Separation location: first position in the DOM
    ///
    /// - Expected results:
    ///     - Should return `nil`
    ///
    func testFindSiblings2() {
        let textNode1 = TextNode(text: "bold")
        let textNode2 = TextNode(text: "italic")

        let boldNode = ElementNode(name: StandardElementType.b.rawValue, attributes: [], children: [textNode1])
        let italicNode = ElementNode(name: StandardElementType.i.rawValue, attributes: [], children: [textNode2])
        let rootNode = RootNode(children: [boldNode, italicNode])

        let inspector = DOMInspector(with: rootNode)

        let siblings = inspector.findSiblings(separatedAt: 0)

        XCTAssertNil(siblings)
    }


    /// Tests that `findSiblings(separatedAt:)` works properly.
    ///
    /// - Input:
    ///     - HTML: "<root><strong>bold</strong><em>italic</em></root>"
    ///     - Separation location: last position in the DOM
    ///
    /// - Expected results:
    ///     - Should return `nil`
    ///
    func testFindSiblings3() {
        let textNode1 = TextNode(text: "bold")
        let textNode2 = TextNode(text: "italic")

        let boldNode = ElementNode(name: StandardElementType.b.rawValue, attributes: [], children: [textNode1])
        let italicNode = ElementNode(name: StandardElementType.i.rawValue, attributes: [], children: [textNode2])
        let rootNode = RootNode(children: [boldNode, italicNode])

        let inspector = DOMInspector(with: rootNode)

        let siblings = inspector.findSiblings(separatedAt: textNode1.length() + textNode2.length())

        XCTAssertNil(siblings)
    }
}
