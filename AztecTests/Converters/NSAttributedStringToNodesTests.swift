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
        let html = "<b>Bold?</b>"

        let converter = NSAttributedStringToNodes()
        let attrString = attributedString(from: html)

        let root = converter.convert(attrString)
        XCTAssert(root.children.count == 1)

        guard let bold = root.children.first as? ElementNode, let text = bold.children.first as? TextNode else {
            XCTFail()
            return
        }

        XCTAssert(bold.children.count == 1)
        XCTAssertEqual(text.contents, "Bold?")
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
}
