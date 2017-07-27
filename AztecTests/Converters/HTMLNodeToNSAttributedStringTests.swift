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
        let spanAttribute2 = Attribute(name: "class", value: .string("aztec"))
        let spanNode2 = ElementNode(type: .span, attributes: [spanAttribute2], children: [textNode])

        // <span class="first"><span class="aztec">
        let spanAttribute1 = Attribute(name: "class", value: .string("first"))
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
        XCTAssertEqual(restoredSpanAttribute2?.value.toString(), "aztec")

        let restoredSpanElement1 = unsupportedHTML.elements.first
        XCTAssertEqual(restoredSpanElement1?.name, "span")

        let restoredSpanAttribute1 = restoredSpanElement1?.attributes.first
        XCTAssertEqual(restoredSpanAttribute1?.name, "class")
        XCTAssertEqual(restoredSpanAttribute1?.value.toString(), "first")
    }

    ///
    ///
    func testLineBreakTagWithinUnsupportedHTMLDoesNotCauseDataLoss() {
        let html = "<div><br>Aztec, don't forget me!</div>"

        let inNode = InHTMLConverter().convert(html)
        let attrString = attributedString(from: inNode)

        let outNode = NSAttributedStringToNodes().convert(attrString)
        let outHtml = OutHTMLConverter().convert(outNode)

        NSLog("HTML: \(outHtml)")
    }
}


// MARK: - Helpers
//
extension HTMLNodeToNSAttributedStringTests {

    func attributedString(from node: Node) -> NSAttributedString {
        let descriptor = UIFont.systemFont(ofSize: 14).fontDescriptor
        let converter = HTMLNodeToNSAttributedString(usingDefaultFontDescriptor: descriptor)

        return converter.convert(node)
    }
}
