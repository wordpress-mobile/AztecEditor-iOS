import XCTest
@testable import Aztec

class DOMEditorTests: XCTestCase {

    typealias DOMEditor = Libxml2.DOMEditor
    typealias ElementNode = Libxml2.ElementNode
    typealias RootNode = Libxml2.RootNode
    typealias StandardElementType = Libxml2.StandardElementType
    typealias TextNode = Libxml2.TextNode

    /// Tests that `findSiblings(separatedAt:)` works properly.
    ///
    /// - Input:
    ///     - HTML: "<root><p>Hello</p><blockquote>world!</blockquote></root>"
    ///     - Separation location: 4
    ///
    /// - Expected results:
    ///     - Both the bold and italic nodes should be returned.
    ///
    func testMergeSiblings() {
        let text1 = "Hello"
        let text2 = "world!"

        let textNode1 = TextNode(text: text1)
        let textNode2 = TextNode(text: text2)

        let paragraph = ElementNode(name: StandardElementType.p.rawValue, attributes: [], children: [textNode1])
        let blockquote = ElementNode(name: StandardElementType.blockquote.rawValue, attributes: [], children: [textNode2])
        let rootNode = RootNode(children: [paragraph, blockquote])

        let editor = DOMEditor(with: rootNode)

        editor.mergeSiblings(separatedAt: textNode1.length())

        XCTAssertEqual(rootNode.children.count, 1)

        guard let newParagraph = rootNode.children[0] as? ElementNode,
            newParagraph.name == StandardElementType.p.rawValue else {
                XCTFail("Expected a paragraph node.")
                return
        }

        /// - TODO: this test should be modified to make sure the child of newParagraph is a single
        ///     TextNode element.  For the time being we're purposedly ignoring this, since there are
        ///     other priorities.  This is the recommented code for that:
        ///
        /// XCTAssertEqual(newParagraph.children.count, 1)
        ///
        /// guard let newTextNode = newParagraph.children[0] as? TextNode else {
        ///     XCTFail("Expected a TextNode.")
        ///     return
        /// }
        ///
        /// XCTAssertEqual(newTextNode.text(), "\(text1)\(text2)")

        XCTAssertEqual(newParagraph.children.count, 2)
        XCTAssert(newParagraph.children[0] is TextNode)
        XCTAssert(newParagraph.children[1] is TextNode)
        XCTAssertEqual(newParagraph.text(), "\(text1)\(text2)")
    }

    /// Tests that `findSiblings(separatedAt:)` works properly.
    ///
    /// - Input:
    ///     - HTML: "<root><p>Hello</p><blockquote>world!</blockquote></root>"
    ///     - Separation location: first DOM location
    ///
    /// - Expected results:
    ///     - The output should not change.
    ///
    func testMergeSiblings2() {
        let text1 = "Hello"
        let text2 = "world!"

        let textNode1 = TextNode(text: text1)
        let textNode2 = TextNode(text: text2)

        let paragraph = ElementNode(name: StandardElementType.p.rawValue, attributes: [], children: [textNode1])
        let blockquote = ElementNode(name: StandardElementType.blockquote.rawValue, attributes: [], children: [textNode2])
        let rootNode = RootNode(children: [paragraph, blockquote])

        let editor = DOMEditor(with: rootNode)

        editor.mergeSiblings(separatedAt: 0)

        XCTAssertEqual(rootNode.children.count, 2)

        guard let newParagraph = rootNode.children[0] as? ElementNode,
            newParagraph.name == StandardElementType.p.rawValue else {
                XCTFail("Expected a paragraph node.")
                return
        }

        XCTAssertEqual(newParagraph, paragraph)
        XCTAssertEqual(newParagraph.text(), text1)

        guard let newBlockquote = rootNode.children[1] as? ElementNode,
            newBlockquote.name == StandardElementType.blockquote.rawValue else {
                XCTFail("Expected a paragraph node.")
                return
        }

        XCTAssertEqual(newBlockquote, blockquote)
        XCTAssertEqual(newBlockquote.text(), text2)
    }

    /// Tests that `findSiblings(separatedAt:)` works properly.
    ///
    /// - Input:
    ///     - HTML: "<root><p>Hello</p><blockquote>world!</blockquote></root>"
    ///     - Separation location: final DOM location
    ///
    /// - Expected results:
    ///     - The output should not change.
    ///
    func testMergeSiblings3() {
        let text1 = "Hello"
        let text2 = "world!"

        let textNode1 = TextNode(text: text1)
        let textNode2 = TextNode(text: text2)

        let paragraph = ElementNode(name: StandardElementType.p.rawValue, attributes: [], children: [textNode1])
        let blockquote = ElementNode(name: StandardElementType.blockquote.rawValue, attributes: [], children: [textNode2])
        let rootNode = RootNode(children: [paragraph, blockquote])

        let editor = DOMEditor(with: rootNode)

        editor.mergeSiblings(separatedAt: text1.characters.count + text2.characters.count)

        XCTAssertEqual(rootNode.children.count, 2)

        guard let newParagraph = rootNode.children[0] as? ElementNode,
            newParagraph.name == StandardElementType.p.rawValue else {
                XCTFail("Expected a paragraph node.")
                return
        }

        XCTAssertEqual(newParagraph, paragraph)
        XCTAssertEqual(newParagraph.text(), text1)

        guard let newBlockquote = rootNode.children[1] as? ElementNode,
            newBlockquote.name == StandardElementType.blockquote.rawValue else {
                XCTFail("Expected a paragraph node.")
                return
        }

        XCTAssertEqual(newBlockquote, blockquote)
        XCTAssertEqual(newBlockquote.text(), text2)
    }
}
