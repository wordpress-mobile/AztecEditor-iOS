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


    /// Verifies that `<b>Bold?</b>` gets effectively translated into it's tree representation.
    ///
    func testBoldStyleGetsProperlySerializedBackIntoItsHtmlRepresentation() {
        let input = "<b>Bold?</b>"
        let expected = input

        let generated = generatedHTML(input: input)
        XCTAssertEqual(generated, expected)
    }


    /// Verifies that `<i>Italics!</i>` gets effectively translated into it's tree representation.
    ///
    func testItalicsStyleGetsProperlySerializedBackIntoItsHtmlRepresentation() {
        let input = "<i>Italics!</i>"
        let expected = input

        let generated = generatedHTML(input: input)
        XCTAssertEqual(generated, expected)
    }


    ///
    ///
    func testUnderlinedStyleGetsProperlySerializedBackIntoItsHtmlRepresentation() {
        let input = "<u>Underlined</u>"
        let expected = input

        let generated = generatedHTML(input: input)
        XCTAssertEqual(generated, expected)
    }


    ///
    ///
    func testStrikeStyleGetsProperlySerializedBackIntoItsHtmlRepresentation() {
        let input = "<strike>Srike!</strike>"
        let expected = input

        let generated = generatedHTML(input: input)
        XCTAssertEqual(generated, expected)
    }


    ///
    ///
    func testLinksStyleGetsProperlySerializedBackIntoItsHtmlRepresentation() {
        let input = "<a href=\"yosemite.com\">Yo! Yose! Yosemite!</a>"
        let expected = input

        let generated = generatedHTML(input: input)
        XCTAssertEqual(generated, expected)
    }


    ///
    ///
    func testListItemsRemainInTheSameContainingUnorderedList() {
        let input = "<ul><li>First Line</li><li>Second Line</li></ul>"
        let expected = input

        let generated = generatedHTML(input: input)
        XCTAssertEqual(generated, expected)
    }


    ///
    ///
    func testCommentsArePreservedAndSerializedBack() {
        let input = "<!-- I'm a comment. YEAH --><ul><li>Item</li></ul><!-- Tail Comment -->"
        let expected = input

        let generated = generatedHTML(input: input)
        XCTAssertEqual(generated, expected)
    }


    ///
    ///
    func testUnknownHtmlDoesNotGetNuked() {
        let input = "<table><tr><td>ROW ROW</td></tr></table><ul><li>Item</li></ul><!-- Tail Comment -->"
        let expected = input

        let generated = generatedHTML(input: input)
        XCTAssertEqual(generated, expected)
    }


    ///
    ///
    func testHeaderElementGetsProperlySerialiedBackIntoItsHtmlRepresentation() {
        for level in 1...6 {
            let input = "<h\(level)>Aztec Rocks</h\(level)>Newline!"
            let expected = input

            let generated = generatedHTML(input: input)
            XCTAssertEqual(generated, expected)
        }
    }


    ///
    ///
    func testLineElementGetsProperlySerialiedBackIntoItsHtmlRepresentation() {
        let input = "<hr>I'm a text line<hr>I'm another text line<hr>And i'm a third one"
        let expected = "<hr>I&apos;m a text line<hr>I&apos;m another text line<hr>And i&apos;m a third one"

        let generated = generatedHTML(input: input)
        XCTAssertEqual(generated, expected)
    }


    ///
    ///
    func testContiguousUnorderedListsGetHeirItemsmerged() {
        let input = "<ul><li>First Line</li></ul><ul><li>Second Line</li></ul>"
        let expected = "<ul><li>First Line</li><li>Second Line</li></ul>"

        let generated = generatedHTML(input: input)
        XCTAssertEqual(generated, expected)
    }


    ///
    //
    func testSomething2() {
        let input = "<blockquote><ul><li>First Line</li></ul></blockquote><blockquote><ul><li>Second Line</li></ul></blockquote>"
        let expected = "<blockquote><ul><li>First Line</li><li>Second Line</li></ul></blockquote>"

        let generated = generatedHTML(input: input)
        XCTAssertEqual(generated, expected)
    }


    ///
    ///
    func testSomething() {
        let input = "<ul><li><blockquote>text 1</blockquote></li></ul>" +
                    "<ul><li><blockquote>text 2</blockquote></li></ul>"
        let expected = "<ul><li><blockquote>text 1</blockquote><blockquote>text 2</blockquote></li></ul>"

        let generated = generatedHTML(input: input)
        XCTAssertEqual(generated, expected)
    }
}


// MARK: - Helpers
//
private extension NSAttributedStringToNodesTests {

    /// Returns the HTML resulting of converting:
    ///
    /// 1.  Input >> Attributed String
    /// 2.  Attributed String >> Node
    /// 3.  Node >> HTML
    ///
    func generatedHTML(input html: String) -> String {
        let attrString = attributedString(from: html)
        let node = rootNode(from: attrString)

        return self.html(from: node)
    }

    /// Converts a raw HTML String into it's NSAttributedString Representation
    ///
    func attributedString(from html: String) -> NSAttributedString {
        let defaultFont = UIFont.systemFont(ofSize: 12)
        let converter = HTMLToAttributedString(usingDefaultFontDescriptor: defaultFont.fontDescriptor)
        let (_, attrString) = try! converter.convert(html)

        return attrString
    }

    /// Converts an AttributedString into it's RootNode Representation
    ///
    func rootNode(from attrString: NSAttributedString) -> RootNode {
        let converter = NSAttributedStringToNodes()
        return converter.convert(attrString)
    }

    /// Converts a RootNode into it's HTML Representation
    ///
    func html(from node: RootNode) -> String {
        let converter = Libxml2.Out.HTMLConverter()
        return converter.convert(node)
    }
}
