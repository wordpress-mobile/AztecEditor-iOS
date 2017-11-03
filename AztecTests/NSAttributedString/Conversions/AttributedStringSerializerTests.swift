import XCTest
@testable import Aztec

class AttributedStringSerializerTests: XCTestCase {

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


    /// Verifies that the DivFormatter effectively appends the DIV Element Representation, to the properties collection.
    ///
    func testHtmlDivFormatterEffectivelyAppendsNewDivProperty() {
        let textNode = TextNode(text: "Ehlo World!")

        let divAttr3 = Attribute(name: "class", value: .string("third"))
        let divNode3 = ElementNode(type: .div, attributes: [divAttr3], children: [textNode])

        let divAttr2 = Attribute(name: "class", value: .string("second"))
        let divNode2 = ElementNode(type: .div, attributes: [divAttr2], children: [divNode3])

        let divAttr1 = Attribute(name: "class", value: .string("first"))
        let divNode1 = ElementNode(type: .div, attributes: [divAttr1], children: [divNode2])

        // Convert
        let output = attributedString(from: divNode1)

        // Test!
        var range = NSRange()
        guard let paragraphStyle = output.attribute(NSParagraphStyleAttributeName, at: 0, effectiveRange: &range) as? ParagraphStyle else {
            XCTFail()
            return
        }

        XCTAssert(range.length == textNode.length())
        XCTAssert(paragraphStyle.htmlDiv.count == 3)

        guard case let .element(restoredDiv1) = paragraphStyle.htmlDiv[0].representation!.kind,
            case let .element(restoredDiv2) = paragraphStyle.htmlDiv[1].representation!.kind,
            case let .element(restoredDiv3) = paragraphStyle.htmlDiv[2].representation!.kind
        else {
            XCTFail()
            return
        }

        XCTAssert(restoredDiv1.name == divNode1.name)
        XCTAssert(restoredDiv1.attributes == [divAttr1])

        XCTAssert(restoredDiv2.name == divNode2.name)
        XCTAssert(restoredDiv2.attributes == [divAttr2])

        XCTAssert(restoredDiv3.name == divNode3.name)
        XCTAssert(restoredDiv3.attributes == [divAttr3])
    }


    /// Verifies that BR elements contained within div tags do not cause any side effect.
    /// Ref. #658
    ///
    func testLineBreakTagWithinHTMLDivGetsProperlyEncodedAndDecoded() {
        let inHtml = "<div><br>Aztec, don't forget me!</div>"

        let inNode = HTMLParser().parse(inHtml)
        let attrString = attributedString(from: inNode)

        let outNode = AttributedStringParser().parse(attrString)
        let outHtml = DefaultHTMLSerializer().serialize(outNode)

        XCTAssertEqual(outHtml, inHtml)
    }


    /// Verifies that BR elements contained within span tags do not cause Data Loss.
    /// Ref. #658
    ///
    func testLineBreakTagWithinUnsupportedHTMLDoesNotCauseDataLoss() {
        let inHtml = "<span><br>Aztec, don't forget me!</span>"
        let expectedHtml = "<p><span><br></span><span>Aztec, don't forget me!</span></p>"

        let inNode = HTMLParser().parse(inHtml)
        let attrString = attributedString(from: inNode)

        let outNode = AttributedStringParser().parse(attrString)
        let outHtml = DefaultHTMLSerializer().serialize(outNode)

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

        let inNode = HTMLParser().parse(inHtml)
        let attrString = attributedString(from: inNode)

        let outNode = AttributedStringParser().parse(attrString)
        let outHtml = DefaultHTMLSerializer().serialize(outNode)

        XCTAssertEqual(outHtml, inHtml)
    }
    
    /// Verifies that a linked image is properly converted from HTML to attributed string and back to HTML.
    ///
    func testLinkedImageGetsProperlyEncodedAndDecoded() {
        let inHtml = "<p><a href=\"https://wordpress.com\"><img src=\"https://s.w.org/about/images/wordpress-logo-notext-bg.png\"></a></p>"
        
        let inNode = HTMLParser().parse(inHtml)
        let attrString = attributedString(from: inNode)
        
        let outNode = AttributedStringParser().parse(attrString)
        let outHtml = DefaultHTMLSerializer().serialize(outNode)
        
        XCTAssertEqual(outHtml, inHtml)
    }
}


// MARK: - Helpers
//
extension AttributedStringSerializerTests {

    func attributedString(from node: Node) -> NSAttributedString {
        let defaultAttributes = [NSFontAttributeName: UIFont.systemFont(ofSize: 14),
                                 NSParagraphStyleAttributeName: ParagraphStyle.default]
        
        let serializer = AttributedStringSerializer(defaultAttributes: defaultAttributes)

        return serializer.serialize(node)
    }
}
