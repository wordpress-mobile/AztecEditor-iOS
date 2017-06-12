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
            NSFontAttributeName: UIFont.systemFont(ofSize: UIFont.systemFontSize),
            NSParagraphStyleAttributeName: NSParagraphStyle()
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
        let testingString = NSAttributedString(string: "Strike!", attributes: attributes)

        // Convert + Verify
        let node = rootNode(from: testingString)
        XCTAssert(node.children.count == 1)

        let strike = node.children.first as? ElementNode
        XCTAssertEqual(strike?.name, "strike")
        XCTAssert(strike?.children.count == 1)

        let text = strike?.children.first as? TextNode
        XCTAssertEqual(text?.contents, testingString.string)
    }


    ///
    ///
    func testLinkStyleEffectivelyMapsIntoItsTreeRepresentation() {
        let formatter = LinkFormatter()
        formatter.attributeValue = URL(string: "www.yosemite.com") as Any

        let attributes = formatter.apply(to: Constants.sampleAttributes)
        let testingString = NSAttributedString(string: "Yo! Yose! Yosemite!", attributes: attributes)

        // Convert + Verify
        let node = rootNode(from: testingString)
        XCTAssert(node.children.count == 1)

        let link = node.children.first as? ElementNode
        XCTAssertEqual(link?.name, "a")
        XCTAssert(link?.children.count == 1)

        let text = link?.children.first as? TextNode
        XCTAssertEqual(text?.contents, testingString.string)
    }


    ///
    ///
    func testListItemsRemainInTheSameContainingUnorderedList() {
        let firstText = "First Line"
        let secondText = "Second Line"

        let attributes = TextListFormatter(style: .ordered).apply(to: Constants.sampleAttributes)

        let text = firstText + String(.newline) + secondText
        let testingString = NSMutableAttributedString(string: text, attributes: attributes)

        // Convert + Verify
        let node = rootNode(from: testingString)
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


    ///
    ///
    func testCommentsArePreservedAndSerializedBack() {
        let attachment = CommentAttachment()
        attachment.text = "I'm a comment. YEAH!"
        let stringWithAttachment = NSAttributedString(attachment: attachment)

        let text = "Payload here"
        let testingString = NSMutableAttributedString(string: text)
        testingString.insert(stringWithAttachment, at: 0)
        testingString.append(stringWithAttachment)

        // Convert + Verify
        let node = rootNode(from: testingString)
        XCTAssert(node.children.count == 3)

        guard let headNode = node.children[0] as? CommentNode,
            let textNode = node.children[1] as? TextNode,
            let tailNode = node.children[2] as? CommentNode
        else {
            XCTFail()
            return
        }

        XCTAssertEqual(headNode.comment, attachment.text)
        XCTAssertEqual(tailNode.comment, attachment.text)
        XCTAssertEqual(textNode.contents, text)
    }


    ///
    ///
    func testLineElementGetsProperlySerialiedBackIntoItsHtmlRepresentation() {
        let attachment = LineAttachment()

        let stringWithAttachment = NSAttributedString(attachment: attachment)
        let stringWithText = NSAttributedString(string: "I'm a text line")

        let testingString = NSMutableAttributedString()

        testingString.append(stringWithAttachment)
        testingString.append(stringWithText)
        testingString.append(stringWithAttachment)
        testingString.append(stringWithText)
        testingString.append(stringWithAttachment)

        // Convert + Verify
        let node = rootNode(from: testingString)
        XCTAssert(node.children.count == 5)

        guard let firstLine = node.children[0] as? ElementNode,
            let firstText = node.children[1] as? TextNode,
            let secondLine = node.children[2] as? ElementNode,
            let secondText = node.children[3] as? TextNode,
            let thirdLine = node.children[4] as? ElementNode
        else {
            XCTFail()
            return
        }

        XCTAssertEqual(firstLine.name, "hr")
        XCTAssertEqual(secondLine.name, "hr")
        XCTAssertEqual(thirdLine.name, "hr")
        XCTAssertEqual(firstText.contents, stringWithText.string)
        XCTAssertEqual(secondText.contents, stringWithText.string)
    }


    ///
    ///
    func testHeaderElementGetsProperlySerialiedBackIntoItsHtmlRepresentation() {

        let levels: [HeaderFormatter.HeaderType] = [.h1, .h2, .h3, .h4, .h5, .h6]

        for level in levels {
            let formatter = HeaderFormatter(headerLevel: level, placeholderAttributes: [:])

            let headingStyle = formatter.apply(to: Constants.sampleAttributes)
            let headingText = NSAttributedString(string: "Aztec Rocks\n", attributes: headingStyle)
            let regularText = NSAttributedString(string: "Newline?", attributes: Constants.sampleAttributes)

            let testingString = NSMutableAttributedString()
            testingString.append(headingText)
            testingString.append(regularText)

            // Convert + Verify
            let node = rootNode(from: testingString)
            XCTAssert(node.children.count == 2)

            guard let headerNode = node.children[0] as? ElementNode,
                let headerTextNode = headerNode.children[0] as? TextNode,
                let regularTextNode = node.children[1] as? TextNode
            else {
                XCTFail()
                return
            }

            XCTAssertEqual(headerNode.name, "h\(level.rawValue)")
            XCTAssertEqual(headerTextNode.contents, "Aztec Rocks")
            XCTAssertEqual(regularTextNode.contents, "Newline?")
        }
    }


    ///
    ///
    func testUnknownHtmlDoesNotGetNuked() {
        let htmlAttachment = HTMLAttachment()
        htmlAttachment.rawHTML = "<table><tr><td>ROW ROW</td></tr></table>"

        let commentAttachment = CommentAttachment()
        commentAttachment.text = "Tail Comment"

        let htmlString = NSAttributedString(attachment: htmlAttachment)
        let textString = NSAttributedString(string: "Some Text here?")
        let commentString = NSAttributedString(attachment: commentAttachment)

        let testingString = NSMutableAttributedString()
        testingString.append(htmlString)
        testingString.append(textString)
        testingString.append(commentString)

        // Convert + Verify
        let node = rootNode(from: testingString)
        XCTAssert(node.children.count == 3)

        guard let htmlNode = node.children[0] as? ElementNode,
            let textNode = node.children[1] as? TextNode,
            let commentNode = node.children[2] as? CommentNode
        else {
            XCTFail()
            return
        }

        let reconvertedHTML = Libxml2.Out.HTMLConverter().convert(htmlNode)

        XCTAssertEqual(reconvertedHTML, htmlAttachment.rawHTML)
        XCTAssertEqual(textNode.contents, textString.string)
        XCTAssertEqual(commentNode.comment, commentAttachment.text)
    }


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
//    ///
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
