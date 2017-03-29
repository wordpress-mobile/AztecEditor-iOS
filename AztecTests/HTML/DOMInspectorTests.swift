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
    func testFindNode() {
        let textNode1 = TextNode(text: "bold")
        let textNode2 = TextNode(text: "italic")

        let boldNode = ElementNode(name: StandardElementType.b.rawValue, attributes: [], children: [textNode1])
        let italicNode = ElementNode(name: StandardElementType.i.rawValue, attributes: [], children: [textNode2])
        let rootNode = RootNode(children: [boldNode, italicNode])

        let inspector = DOMInspector(with: rootNode)

        guard let leftNode = inspector.findNode(endingAt: textNode1.length()) else {
            XCTFail("Expected to find a node here.")
            return
        }

        let rightNode = inspector.rightSibling(of: leftNode)

        XCTAssertEqual(leftNode, boldNode)
        XCTAssertEqual(rightNode, italicNode)
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
    func testFindNode2() {
        let textNode1 = TextNode(text: "bold")
        let textNode2 = TextNode(text: "italic")

        let boldNode = ElementNode(name: StandardElementType.b.rawValue, attributes: [], children: [textNode1])
        let italicNode = ElementNode(name: StandardElementType.i.rawValue, attributes: [], children: [textNode2])
        let rootNode = RootNode(children: [boldNode, italicNode])

        let inspector = DOMInspector(with: rootNode)

        let leftNode = inspector.findNode(endingAt: 0)

        XCTAssertNil(leftNode)
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
    func testFindNode3() {
        let textNode1 = TextNode(text: "bold")
        let textNode2 = TextNode(text: "italic")

        let boldNode = ElementNode(name: StandardElementType.b.rawValue, attributes: [], children: [textNode1])
        let italicNode = ElementNode(name: StandardElementType.i.rawValue, attributes: [], children: [textNode2])
        let rootNode = RootNode(children: [boldNode, italicNode])

        let inspector = DOMInspector(with: rootNode)

        guard let leftNode = inspector.findNode(endingAt: textNode1.length() + textNode2.length()) else {
            XCTFail("Expected to find a left node here.")
            return
        }

        let rightNode = inspector.rightSibling(of: leftNode)

        XCTAssertNil(rightNode)
    }
}
