import XCTest
@testable import Aztec


// MARK: - NSAttributedStringToNodesTests
//
class NSAttributedStringToNodesTests: XCTestCase {

    /// Typealiases
    ///
    typealias Node = Libxml2.Node
    typealias CommentNode = Libxml2.CommentNode
    typealias ElementNode = Libxml2.ElementNode
    typealias RootNode = Libxml2.RootNode
    typealias TextNode = Libxml2.TextNode


    ///
    ///
    private struct Constants {
        static let sampleAttributes: [String : Any] = [
            NSFontAttributeName: UIFont.systemFont(ofSize: UIFont.systemFontSize)
        ]
    }


    ///
    ///
    func testBoldStyleEffectivelyMapsIntoItsTreeRepresentation() {
        let attributes = BoldFormatter().apply(to: Constants.sampleAttributes)
        let string = NSAttributedString(string: "Bold?", attributes: attributes)

        // Convert + Verify
        let node = rootNode(from: string)
        XCTAssert(node.children.count == 1)

        let bold = node.children.first as? ElementNode
        XCTAssertEqual(bold?.name, "b")
        XCTAssert(bold?.children.count == 1)

        let text = bold?.children.first as? TextNode
        XCTAssertEqual(text?.contents, string.string)
    }


    ///
    ///
    func testItalicStyleEffectivelyMapsIntoItsTreeRepresentation() {
        let attributes = ItalicFormatter().apply(to: Constants.sampleAttributes)
        let string = NSAttributedString(string: "Italics!", attributes: attributes)

        // Convert + Verify
        let node = rootNode(from: string)
        XCTAssert(node.children.count == 1)

        let italic = node.children.first as? ElementNode
        XCTAssertEqual(italic?.name, "i")
        XCTAssert(italic?.children.count == 1)

        let text = italic?.children.first as? TextNode
        XCTAssertEqual(text?.contents, string.string)
    }


    ///
    ///
    func testUnderlineStyleEffectivelyMapsIntoItsTreeRepresentation() {
        let attributes = UnderlineFormatter().apply(to: Constants.sampleAttributes)
        let string = NSAttributedString(string: "Underlined!", attributes: attributes)

        // Convert + Verify
        let node = rootNode(from: string)
        XCTAssert(node.children.count == 1)

        let underlined = node.children.first as? ElementNode
        XCTAssertEqual(underlined?.name, "u")
        XCTAssert(underlined?.children.count == 1)

        let text = underlined?.children.first as? TextNode
        XCTAssertEqual(text?.contents, string.string)
    }


    ///
    ///
    func testStrikeStyleEffectivelyMapsIntoItsTreeRepresentation() {
        let attributes = StrikethroughFormatter().apply(to: Constants.sampleAttributes)
        let string = NSAttributedString(string: "Strike!", attributes: attributes)

        // Convert + Verify
        let node = rootNode(from: string)
        XCTAssert(node.children.count == 1)

        let strike = node.children.first as? ElementNode
        XCTAssertEqual(strike?.name, "strike")
        XCTAssert(strike?.children.count == 1)

        let text = strike?.children.first as? TextNode
        XCTAssertEqual(text?.contents, string.string)
    }


    ///
    ///
    func testLinkStyleEffectivelyMapsIntoItsTreeRepresentation() {
        let formatter = LinkFormatter()
        formatter.attributeValue = URL(string: "www.yosemite.com") as Any

        let attributes = formatter.apply(to: Constants.sampleAttributes)
        let string = NSAttributedString(string: "Yo! Yose! Yosemite!", attributes: attributes)

        // Convert + Verify
        let node = rootNode(from: string)
        XCTAssert(node.children.count == 1)

        let link = node.children.first as? ElementNode
        XCTAssertEqual(link?.name, "a")
        XCTAssert(link?.children.count == 1)

        let text = link?.children.first as? TextNode
        XCTAssertEqual(text?.contents, string.string)
    }


    ///
    ///
    func testListItemsRemainInTheSameContainingUnorderedList() {
        let firstText = "First Line"
        let secondText = "Second Line"

        let attributes = TextListFormatter(style: .ordered).apply(to: Constants.sampleAttributes)

        let text = firstText + String(.newline) + secondText
        let string = NSMutableAttributedString(string: text, attributes: attributes)

        // Convert + Verify
        let node = rootNode(from: string)
        XCTAssert(node.children.count == 1)

        let list = node.children.first as? ElementNode
        XCTAssertEqual(list?.name, "ol")
        XCTAssert(list?.children.count == 2)

        let firstListItem = list?.children[0] as? ElementNode
        let secondListItem = list?.children[1] as? ElementNode
        XCTAssertEqual(firstListItem?.name, "li")
        XCTAssertEqual(secondListItem?.name, "li")
        XCTAssert(firstListItem?.children.count == 1)
        XCTAssert(secondListItem?.children.count == 1)

        let firstTextItem = firstListItem?.children.first as? TextNode
        let secondTextItem = secondListItem?.children.first as? TextNode

        XCTAssertEqual(firstTextItem?.contents, firstText)
        XCTAssertEqual(secondTextItem?.contents, secondText)
    }


//    ///
//    ///
//    func testCommentsArePreservedAndSerializedBack() {
//        let input = "<!-- I'm a comment. YEAH --><ul><li>Item</li></ul><!-- Tail Comment -->"
//        let expected = input
//
//        let generated = generatedHTML(input: input)
//        XCTAssertEqual(generated, expected)
//    }
//
//
//    ///
//    ///
//    func testUnknownHtmlDoesNotGetNuked() {
//        let input = "<table><tr><td>ROW ROW</td></tr></table><ul><li>Item</li></ul><!-- Tail Comment -->"
//        let expected = input
//
//        let generated = generatedHTML(input: input)
//        XCTAssertEqual(generated, expected)
//    }
//
//
//    ///
//    ///
//    func testHeaderElementGetsProperlySerialiedBackIntoItsHtmlRepresentation() {
//        for level in 1...6 {
//            let input = "<h\(level)>Aztec Rocks</h\(level)>Newline!"
//            let expected = input
//
//            let generated = generatedHTML(input: input)
//            XCTAssertEqual(generated, expected)
//        }
//    }
//
//
//    ///
//    ///
//    func testLineElementGetsProperlySerialiedBackIntoItsHtmlRepresentation() {
//        let input = "<hr>I'm a text line<hr>I'm another text line<hr>And i'm a third one"
//        let expected = "<hr>I&apos;m a text line<hr>I&apos;m another text line<hr>And i&apos;m a third one"
//
//        let generated = generatedHTML(input: input)
//        XCTAssertEqual(generated, expected)
//    }
//
//
//    ///
//    ///
//    func testContiguousUnorderedListsGetHeirItemsmerged() {
//        let input = "<ul><li>First Line</li></ul><ul><li>Second Line</li></ul>"
//        let expected = "<ul><li>First Line</li><li>Second Line</li></ul>"
//
//        let generated = generatedHTML(input: input)
//        XCTAssertEqual(generated, expected)
//    }
//
//
//    ///
//    //
//    func testSomething2() {
//        let input = "<blockquote><ul><li>First Line</li></ul></blockquote><blockquote><ul><li>Second Line</li></ul></blockquote>"
//        let expected = "<blockquote><ul><li>First Line</li><li>Second Line</li></ul></blockquote>"
//
//        let generated = generatedHTML(input: input)
//        XCTAssertEqual(generated, expected)
//    }
//
//
//    ///
//    ///
//    func testSomething() {
//        let input = "<ul><li><blockquote>text 1</blockquote></li></ul>" +
//                    "<ul><li><blockquote>text 2</blockquote></li></ul>"
//        let expected = "<ul><li><blockquote>text 1</blockquote><blockquote>text 2</blockquote></li></ul>"
//    }
}


// MARK: - Helpers
//
private extension NSAttributedStringToNodesTests {

    /// Converts an AttributedString into it's RootNode Representation
    ///
    func rootNode(from attrString: NSAttributedString) -> RootNode {
        let converter = NSAttributedStringToNodes()
        return converter.convert(attrString)
    }
}
