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

        let inNode = InHTMLConverter().convert(inHtml)
        let attrString = attributedString(from: inNode)

        let outNode = NSAttributedStringToNodes().convert(attrString)
        let outHtml = OutHTMLConverter().convert(outNode)

        XCTAssertEqual(outHtml, inHtml)
    }


    /// Verifies that BR elements contained within span tags do not cause Data Loss.
    /// Ref. #658
    ///
    func testLineBreakTagWithinUnsupportedHTMLDoesNotCauseDataLoss() {
        let inHtml = "<span><br>Aztec, don't forget me!</span>"
        let expectedHtml = "<p><span><br></span><span>Aztec, don't forget me!</span></p>"

        let inNode = InHTMLConverter().convert(inHtml)
        let attrString = attributedString(from: inNode)

        let outNode = NSAttributedStringToNodes().convert(attrString)
        let outHtml = OutHTMLConverter().convert(outNode)

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
