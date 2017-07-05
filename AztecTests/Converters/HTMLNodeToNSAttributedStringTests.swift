import XCTest
@testable import Aztec


// MARK: - HTMLNodeToNSAttributedStringTests
//
class HTMLNodeToNSAttributedStringTests: XCTestCase {

    /// Verifies that <span> Nodes are preserved into the NSAttributedString instance, by means of the UnsupportedHTML
    /// attribute.
    ///
    func testMultipleSpanNodesAreProperlyPreservedWithinUnsupportedHtmlAttribute() {
        let textNode = TextNode(text: "Ehlo World!")

        // <span class="aztec">
        let spanAttribute2 = StringAttribute(name: "class", value: "aztec")
        let spanNode2 = ElementNode(type: .span, attributes: [spanAttribute2], children: [textNode])

        // <span class="first"><span class="aztec">
        let spanAttribute1 = StringAttribute(name: "class", value: "first")
        let spanNode1 = ElementNode(type: .span, attributes: [spanAttribute1], children: [spanNode2])

        // <h1><span class="first"><span class="aztec">
        let headerNode = ElementNode(type: .h1, attributes: [], children: [spanNode1])
        let rootNode = RootNode(children: [headerNode])

        // Convert + Test
        let output = attributedString(from: rootNode)

        var range = NSRange()
        guard let unsupportedHTML = output.attribute(UnsupportedHTMLAttributeName, at: 0, effectiveRange: &range) as? UnsupportedHTML else {
            XCTFail()
            return
        }

        XCTAssert(range.length == textNode.length())
        XCTAssert(unsupportedHTML.elements.count == 2)

        let restoredSpanElement2 = unsupportedHTML.elements.last
        XCTAssertEqual(restoredSpanElement2?.name, "span")

        let restoredSpanAttribute2 = restoredSpanElement2?.attributes.first
        XCTAssertEqual(restoredSpanAttribute2?.name, "class")
        XCTAssertEqual(restoredSpanAttribute2?.value, "aztec")

        let restoredSpanElement1 = unsupportedHTML.elements.first
        XCTAssertEqual(restoredSpanElement1?.name, "span")

        let restoredSpanAttribute1 = restoredSpanElement1?.attributes.first
        XCTAssertEqual(restoredSpanAttribute1?.name, "class")
        XCTAssertEqual(restoredSpanAttribute1?.value, "first")
    }
}


// MARK: - Helpers
//
extension HTMLNodeToNSAttributedStringTests {

    func attributedString(from node: Node) -> NSAttributedString {
        let descriptor = UIFont.boldSystemFont(ofSize: 14).fontDescriptor
        let converter = HTMLNodeToNSAttributedString(usingDefaultFontDescriptor: descriptor)

        return converter.convert(node)
    }
}
