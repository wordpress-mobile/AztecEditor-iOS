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

        // Convert
        let output = attributedString(from: rootNode)

        // Test
        var range = NSRange()
        guard let unsupportedHTML = output.attribute(UnsupportedHTMLAttributeName, at: 0, effectiveRange: &range) as? UnsupportedHTML else {
            XCTFail()
            return
        }

        let representations = unsupportedHTML.representations
        XCTAssert(range.length == textNode.length())
        XCTAssert(representations.count == 2)

        let restoredSpanElement2 = representations.last
        XCTAssertEqual(restoredSpanElement2?.name, "span")

        let restoredSpanAttribute2 = restoredSpanElement2?.attributes.first
        XCTAssertEqual(restoredSpanAttribute2?.name, "class")
        XCTAssertEqual(restoredSpanAttribute2?.value.toString(), "aztec")

        let restoredSpanElement1 = representations.first
        XCTAssertEqual(restoredSpanElement1?.name, "span")

        let restoredSpanAttribute1 = restoredSpanElement1?.attributes.first
        XCTAssertEqual(restoredSpanAttribute1?.name, "class")
        XCTAssertEqual(restoredSpanAttribute1?.value.toString(), "first")
    }


    /// Verifies that BR elements contained within div tags do not cause Data Loss.
    /// Ref. #658
    ///
    func testLineBreakTagWithinUnsupportedHTMLDoesNotCauseDataLoss() {
        let inHtml = "<div><br>Aztec, don't forget me!</div>"
        let expectedHtml = "<div><br></div><div>Aztec, don't forget me!</div>"

        let inNode = InHTMLConverter().convert(inHtml)
        let attrString = attributedString(from: inNode)

        let outNode = NSAttributedStringToNodes().convert(attrString)
        let outHtml = OutHTMLConverter().convert(outNode)

        XCTAssertEqual(outHtml, expectedHtml)
    }


    /// Verifies that nested Unsupported HTML snippets get applied to *their own* UnsupportedHTML container.
    /// Ref. #658
    ///
    func testMultipleUnrelatedUnsupportedHTMLSnippetsDoNotGetAppliedToTheEntireStringRange() {
        let inHtml = "<div>" +
            "<p><span>One</span></p>" +
            "<p><span><br></span></p>" +
            "<p><span>Two</span></p>" +
            "<p><br></p>" +
            "<p><span>Three</span><span>Four</span><span>Five</span></p>" +
            "</div>"

        let expectedHtml = "<p><div><span>One</span></div></p>" +
            "<p><div><span><br></span></div></p>" +
            "<p><div><span>Two</span></div></p>" +
            "<p><div><br></div></p>" +
            "<p><div><span>Three</span></div><div><span>Four</span></div><div><span>Five</span></div></p>"

        let inNode = InHTMLConverter().convert(inHtml)
        let attrString = attributedString(from: inNode)

        let outNode = NSAttributedStringToNodes().convert(attrString)
        let outHtml = OutHTMLConverter().convert(outNode)

        // TODO: replace expectedHTML with inHTML once the DivFormatter is in place
        XCTAssertEqual(outHtml, expectedHtml)
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
