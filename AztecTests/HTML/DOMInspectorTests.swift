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

        let inspector = DOMInspector()

        guard let leftNode = inspector.findDescendant(of: rootNode, endingAt: textNode1.length()) else {
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

        let inspector = DOMInspector()

        let leftNode = inspector.findDescendant(of: rootNode, endingAt: 0)

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

        let inspector = DOMInspector()

        guard let leftNode = inspector.findDescendant(of: rootNode, endingAt: textNode1.length() + textNode2.length()) else {
            XCTFail("Expected to find a left node here.")
            return
        }

        let rightNode = inspector.rightSibling(of: leftNode)

        XCTAssertNil(rightNode)
    }

    // MARK: - Find Children

    /// Tests `inspector.findChildren(of:spanning:)` with a zero-length range.
    ///
    /// Input HTML: <p>This is a test string.</p>
    /// Range: (5...0)
    ///
    /// Expected results:
    ///     - should find 1 matching child node (the text node)
    ///     - the range should be unchanged
    ///
    func testFindChildrenSpanningRange1() {
        let textNode = TextNode(text: "This is a test string.")
        let rangeLocation = 5
        XCTAssert(rangeLocation < textNode.length(),
                  "For this text we need to make sure the range location is inside the test node.")

        let range = NSRange(location: rangeLocation, length: 0)
        let paragraph = ElementNode(name: "p", attributes: [], children: [textNode])
        let rootNode = RootNode(children: [paragraph])
        let inspector = DOMInspector()

        let childrenAndRanges = inspector.findChildren(of: paragraph, spanning: range)

        guard childrenAndRanges.count == 1 else {
            XCTFail("Expected 1 child.")
            return
        }

        XCTAssertEqual(childrenAndRanges[0].node, textNode)
        XCTAssert(NSEqualRanges(childrenAndRanges[0].intersection, range))
    }


    /// Tests `inspector.findChildren(of:spanning:)` with a zero-length range.
    ///
    /// Input HTML: <p>This is a test string.</p>
    /// Range: (0...0)
    ///
    /// Expected results:
    ///     - should find 1 matching child node (the text node)
    ///     - the range should be unchanged
    ///
    func testFindChildrenSpanningRange2() {
        let textNode = TextNode(text: "This is a test string.")
        let rangeLocation = 0
        XCTAssert(rangeLocation < textNode.length(),
                  "For this text we need to make sure the range location is inside the test node.")

        let range = NSRange(location: rangeLocation, length: 0)
        let paragraph = ElementNode(name: "p", attributes: [], children: [textNode])
        let rootNode = RootNode(children: [paragraph])
        let inspector = DOMInspector()

        let childrenAndRanges = inspector.findChildren(of: paragraph, spanning: range)

        guard childrenAndRanges.count == 1 else {
            XCTFail("Expected 1 child.")
            return
        }

        XCTAssertEqual(childrenAndRanges[0].node, textNode)
        XCTAssert(NSEqualRanges(childrenAndRanges[0].intersection, range))
    }

    /// Tests `inspector.findChildren(of:spanning:)` with a zero-length range.
    ///
    /// Input HTML: <p><b>Hello</b><b>Hello again!</b></p>
    /// Prefer left node: true
    /// Range: (5...0)
    ///
    /// Expected results:
    ///     - should find 2 matching child nodes
    ///     - the ranges should be at the end of the first node, and the beginning of the second
    ///
    func testFindChildrenSpanningRange3() {

        let textNode1 = TextNode(text: "Hello")
        let textNode2 = TextNode(text: "Hello again!")

        let rangeLocation = 5
        XCTAssert(rangeLocation == textNode1.length(),
                  "For this text we need to make sure the range location is inside the test node.")

        let range = NSRange(location: rangeLocation, length: 0)

        let bold1 = ElementNode(name: "b", attributes: [], children: [textNode1])
        let bold2 = ElementNode(name: "b", attributes: [], children: [textNode2])
        let paragraph = ElementNode(name: "p", attributes: [], children: [bold1, bold2])
        let rootNode = RootNode(children: [paragraph])
        let inspector = DOMInspector()

        let childrenAndRanges = inspector.findChildren(of: paragraph, spanning: range)

        guard childrenAndRanges.count == 2 else {
            XCTFail("Expected 2 children.")
            return
        }

        XCTAssertEqual(childrenAndRanges[0].node, bold1)
        XCTAssertEqual(childrenAndRanges[1].node, bold2)
        XCTAssert(NSEqualRanges(childrenAndRanges[0].intersection, range))
        XCTAssert(NSEqualRanges(childrenAndRanges[1].intersection, NSRange(location: 0, length: 0)))
    }
}
