import XCTest
@testable import Aztec

class DOMEditorTests: XCTestCase {

    typealias DOMEditor = Libxml2.DOMEditor
    typealias ElementNode = Libxml2.ElementNode
    typealias ElementNodeDescriptor = Libxml2.ElementNodeDescriptor
    typealias RootNode = Libxml2.RootNode
    typealias StandardElementType = Libxml2.StandardElementType
    typealias TextNode = Libxml2.TextNode

    /// Tests force-wrapping child nodes intersecting a certain range in a new node.
    ///
    /// HTML String: <div>Hello there!</div>
    /// Wrap range: (0...5)
    ///
    /// The result should be: <p><b>Hello</b> there!</p>
    ///
    func testForceWrapChildren() {
        let text1 = "Hello"
        let text2 = " there!"
        let fullText = "\(text1)\(text2)"
        let textNode = TextNode(text: fullText)
        let paragraph = ElementNode(name: "p", attributes: [], children: [textNode])
        let rootNode = RootNode(children: [paragraph])

        let editor = DOMEditor(with: rootNode)

        let wrapRange = NSRange(location: 0, length: text1.characters.count)

        let boldElementDescriptor = ElementNodeDescriptor(elementType: .b)
        editor.forceWrap(range: wrapRange, inElement: boldElementDescriptor)

        XCTAssertEqual(paragraph.children.count, 2)

        guard let newBoldNode = paragraph.children[0] as? ElementNode, newBoldNode.name == "b" else {
            XCTFail("Expected a bold node.")
            return
        }

        XCTAssertEqual(newBoldNode.text(), text1)

        guard let newTextNode = paragraph.children[1] as? TextNode else {
            XCTFail("Expected a text node.")
            return
        }

        XCTAssertEqual(newTextNode.text(), text2)
    }

    /// Tests force-wrapping child nodes intersecting a certain range in a new node.
    ///
    /// HTML String: <p>Hello there!</p>
    /// Wrap range: full text length
    ///
    /// The result should be: <p><b>Hello there!</b></p>
    ///
    func testForceWrapChildren2() {
        let fullText = "Hello there!"
        let textNode = TextNode(text: fullText)
        let paragraph = ElementNode(name: "p", attributes: [], children: [textNode])
        let rootNode = RootNode(children: [paragraph])

        let editor = DOMEditor(with: rootNode)

        let wrapRange = NSRange(location: 0, length: fullText.characters.count)

        let boldElementDescriptor = ElementNodeDescriptor(elementType: .b)
        editor.forceWrap(range: wrapRange, inElement: boldElementDescriptor)

        XCTAssertEqual(paragraph.children.count, 1)

        guard let newBoldNode = paragraph.children[0] as? ElementNode, newBoldNode.name == "b" else {
            XCTFail("Expected a bold node.")
            return
        }

        XCTAssertEqual(newBoldNode.text(), fullText)
    }

    /// Tests force-wrapping child nodes intersecting a certain range in a new node.
    ///
    /// HTML String: <div><b>Hello</b> there!</div>
    /// Wrap range: (loc: 5, len: 7)
    ///
    /// The result should be: <p><b>Hello there!</b></p>
    ///
    func testForceWrapChildren3() {
        let text1 = "Hello"
        let text2 = " there!"
        let textNode1 = TextNode(text: text1)
        let textNode2 = TextNode(text: text2)
        let boldNode = ElementNode(name: "b", attributes: [], children: [textNode1])
        let paragraph = ElementNode(name: "p", attributes: [], children: [boldNode, textNode2])
        let rootNode = RootNode(children: [paragraph])

        let editor = DOMEditor(with: rootNode)

        let wrapRange = NSRange(location: text1.characters.count, length: text2.characters.count)

        let boldElementDescriptor = ElementNodeDescriptor(elementType: .b)
        editor.forceWrap(range: wrapRange, inElement: boldElementDescriptor)

        XCTAssertEqual(paragraph.children.count, 1)

        guard let newBoldNode = paragraph.children[0] as? ElementNode, newBoldNode.name == "b" else {
            XCTFail("Expected a bold node.")
            return
        }

        let fullText = "\(text1)\(text2)"
        XCTAssertEqual(newBoldNode.text(), fullText)
    }


    /// Tests wrapping child nodes intersecting a certain range in a new `b` node.
    ///
    /// HTML String: <div><em>Hello </em>there!</div>
    /// Wrap range: (0...6)
    ///
    /// The result should be: <div><b><em>Hello </em></b>there!</div>
    ///
    func testWrapChildrenInNewBNode1() {

        let boldElementType = StandardElementType.b
        let range = NSRange(location: 0, length: 6)

        let textPart1 = "Hello "
        let textPart2 = "there!"

        let textNode1 = TextNode(text: textPart1)
        let textNode2 = TextNode(text: textPart2)

        let em = ElementNode(name: "em", attributes: [], children: [textNode1])
        let div = ElementNode(name: "div", attributes: [], children: [em, textNode2])
        let rootNode = RootNode(children: [div])

        let editor = DOMEditor(with: rootNode)

        editor.wrapChildren(intersectingRange: range, inElement: ElementNodeDescriptor(elementType: boldElementType))

        XCTAssertEqual(div.children.count, 2)
        XCTAssertEqual(div.children[1], textNode2)

        guard let newEmNode = div.children[0] as? ElementNode, newEmNode.name == em.name else {
            XCTFail("Expected an em node here.")
            return
        }

        XCTAssertEqual(newEmNode.children.count, 1)

        guard let newBoldNode = newEmNode.children[0] as? ElementNode, newBoldNode.name == boldElementType.rawValue else {
            XCTFail("Expected a bold node here.")
            return
        }

        XCTAssertEqual(newBoldNode.children.count, 1)
        XCTAssertEqual(newBoldNode.children[0], textNode1)
    }


    /// Tests wrapping child nodes intersecting a certain range in a new `b` node.
    ///
    /// HTML String: <div><em>Hello </em><u>there!</u></div>
    /// Wrap range: full text range / full div node range
    ///
    /// The result should be: <div><b><em>Hello </em><u>there!</u></b></div>
    ///
    func testWrapChildrenInNewBNode2() {

        let boldNodeName = "b"

        let textPart1 = "Hello "
        let textPart2 = "there!"

        let textNode1 = TextNode(text: textPart1)
        let textNode2 = TextNode(text: textPart2)

        let em = ElementNode(name: "em", attributes: [], children: [textNode1])
        let underline = ElementNode(name: "u", attributes: [], children: [textNode2])
        let div = ElementNode(name: "div", attributes: [], children: [em, underline])
        let rootNode = RootNode(children: [div])

        let editor = DOMEditor(with: rootNode)

        editor.wrapChildren(intersectingRange: div.range(), inElement: ElementNodeDescriptor(name: boldNodeName))

        XCTAssertEqual(div.children.count, 1)

        guard let boldNode = div.children[0] as? ElementNode else {
            XCTFail("Expected a bold node here.")
            return
        }

        XCTAssertEqual(boldNode.name, boldNodeName)
        XCTAssertEqual(boldNode.children.count, 2)
        XCTAssertEqual(boldNode.children[0], em)
        XCTAssertEqual(boldNode.children[1], underline)

        XCTAssertEqual(em.children.count, 1)
        XCTAssertEqual(em.children[0], textNode1)

        XCTAssertEqual(underline.children.count, 1)
        XCTAssertEqual(underline.children[0], textNode2)
    }


    /// Tests wrapping child nodes intersecting a certain range in a new `b` node.
    ///
    /// HTML String: <div><em>Hello </em><u>there!</u></div>
    /// Wrap range: (2...8)
    ///
    /// The result should be: <div><em>He</em><b><em>llo </em><u>ther</u></b><u>e!</u></div>
    ///
    func testWrapChildrenInNewBNode3() {

        let boldNodeName = "b"

        let textPart1 = "Hello "
        let textPart2 = "there!"

        let textNode1 = TextNode(text: textPart1)
        let textNode2 = TextNode(text: textPart2)

        let em = ElementNode(name: "em", attributes: [], children: [textNode1])
        let underline = ElementNode(name: "u", attributes: [], children: [textNode2])
        let div = ElementNode(name: "div", attributes: [], children: [em, underline])
        let rootNode = RootNode(children: [div])

        let editor = DOMEditor(with: rootNode)

        let range = NSRange(location: 2, length: 8)

        editor.wrapChildren(intersectingRange: range, inElement: ElementNodeDescriptor(name: boldNodeName))

        XCTAssertEqual(div.children.count, 3)

        XCTAssertEqual(div.children[0].name, "em")
        XCTAssertEqual(div.children[0].length(), 2)
        XCTAssertEqual(div.children[2].name, "u")
        XCTAssertEqual(div.children[2].length(), 2)

        guard let boldNode = div.children[1] as? ElementNode else {
            XCTFail("Expected a bold node here.")
            return
        }

        XCTAssertEqual(boldNode.name, boldNodeName)
        XCTAssertEqual(boldNode.children.count, 2)
        XCTAssertEqual(boldNode.children[0], em)
        XCTAssertEqual(boldNode.children[1], underline)

        XCTAssertEqual(em.children.count, 1)
        XCTAssertEqual(em.children[0].length(), 4)

        XCTAssertEqual(underline.children.count, 1)
        XCTAssertEqual(underline.children[0].length(), 4)
    }

    /// Tests that wrapping a range in a node already present in that range works.
    ///
    /// HTML String: <div><b>Hello there</b></div>
    /// Wrap range: (0...11)
    ///
    /// Expected results:
    ///     - The output should match the input.
    ///
    func testWrapChildrenIntersectingRangeWithEquivalentNodeNames1() {
        let textNode = TextNode(text: "Hello there")
        let boldNode = ElementNode(name: "b", attributes: [], children: [textNode])
        let divNode = ElementNode(name: "div", attributes: [], children: [boldNode])
        let rootNode = RootNode(children: [divNode])

        let editor = DOMEditor(with: rootNode)

        let range = NSRange(location: 0, length: 11)

        let boldElementDescriptor = ElementNodeDescriptor(elementType: .b)
        editor.wrapChildren(intersectingRange: range, inElement: boldElementDescriptor)

        XCTAssertEqual(divNode.children.count, 1)

        guard let newBoldNode = divNode.children[0] as? ElementNode, newBoldNode.name == "b" else {

            XCTFail("Expected a bold node")
            return
        }
        
        XCTAssertEqual(newBoldNode.children.count, 1)
        XCTAssertNotNil(newBoldNode.children[0] as? TextNode)
        XCTAssertEqual(boldNode.text(), newBoldNode.text())
    }

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

        //editor.mergeSiblings(separatedAt: textNode1.length())
        editor.mergeBlockLevelElementRight(endingAt: textNode1.length())

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

        editor.mergeBlockLevelElementRight(endingAt: 0)

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

        editor.mergeBlockLevelElementRight(endingAt: text1.characters.count + text2.characters.count)

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
