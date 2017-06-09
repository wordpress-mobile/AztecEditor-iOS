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
    func testBoldStyleGetsEffectivelyConvertedIntoBoldNode() {
        let input = "<b>Bold?</b>"
        let expected = input

        let attrString = attributedString(from: input)
        let node = rootNode(from: attrString)
        let generated = html(from: node)

        XCTAssertEqual(generated, expected)
    }

    ///
    ///
    func testListItemsGetEffectivelyMerged() {
        let input = "<blockquote><ul><li>First Line</li></ul></blockquote><blockquote><ul><li>Second Line</li></ul></blockquote>"
        let expected = "<blockquote><ul><li>First Line</li><li>Second Line</li></ul></blockquote>"

        let attrString = attributedString(from: input)
        let node = rootNode(from: attrString)
        let generated = html(from: node)

        XCTAssertEqual(generated, expected)
    }

    ///
    ///
    func testSomething() {
        let input = "<ul><li><blockquote>text 1</blockquote></li></ul>" +
                    "<ul><li><blockquote>text 2</blockquote></li></ul>"
        let expected = "<ul><li><blockquote>text 1</blockquote><blockquote>text 2</blockquote></li></ul>"

        let attrString = attributedString(from: input)
        let node = rootNode(from: attrString)
        let generated = html(from: node)

        XCTAssertEqual(generated, expected)
    }
}


// MARK: - Helpers
//
private extension NSAttributedStringToNodesTests {

    /// Converts a raw HTML String into it's NSAttributedString Representation
    ///
    func attributedString(from html: String) -> NSAttributedString {
        let defaultFont = UIFont.systemFont(ofSize: 12)
        let converter = HTMLToAttributedString(usingDefaultFontDescriptor: defaultFont.fontDescriptor)
        let (_, attrString) = try! converter.convert(html)

        return attrString
    }

    ///
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
