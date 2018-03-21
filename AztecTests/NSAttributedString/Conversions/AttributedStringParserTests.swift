import XCTest
@testable import Aztec

class AttributedStringParserTests: XCTestCase {

    /// Verifies that Bold Style gets effectively mapped.
    ///
    /// - Input: [Bold Style]Bold?[/Bold Style]
    ///
    /// - Output: <b>Bold?</b>
    ///
    func testBoldStyleEffectivelyMapsIntoItsTreeRepresentation() {
        let attributes = BoldFormatter().apply(to: Constants.sampleAttributes)
        let string = NSAttributedString(string: "Bold?", attributes: attributes)

        let rootNode = AttributedStringParser().parse(string)
        XCTAssertEqual(rootNode.children.count, 1)

        guard let paragraph = rootNode.children.first as? ElementNode else {
            XCTFail()
            return
        }
        XCTAssertEqual(paragraph.children.count, 1)

        guard let bold = paragraph.children.first as? ElementNode else {
            XCTFail()
            return
        }
        XCTAssertEqual(bold.name, "strong")
        XCTAssertEqual(bold.children.count, 1)

        guard let text = bold.children.first as? TextNode else {
            XCTFail()
            return
        }
        XCTAssertEqual(text.contents, string.string)
    }


    /// Verifies that Italics Style gets effectively mapped.
    ///
    /// - Input: [Italic Style]Italics![/Italic Style]
    ///
    /// - Output: <i>Italics</i>
    ///
    func testItalicStyleEffectivelyMapsIntoItsTreeRepresentation() {
        let attributes = ItalicFormatter().apply(to: Constants.sampleAttributes)
        let string = NSAttributedString(string: "Italics!", attributes: attributes)

        let node = AttributedStringParser().parse(string)
        XCTAssertEqual(node.children.count, 1)

        guard let paragraph = node.children.first as? ElementNode else {
            XCTFail()
            return
        }
        XCTAssertEqual(paragraph.children.count, 1)

        guard let italic = paragraph.children.first as? ElementNode else {
            XCTFail()
            return
        }
        XCTAssertEqual(italic.name, "em")
        XCTAssertEqual(italic.children.count, 1)

        guard let text = italic.children.first as? TextNode else {
            XCTFail()
            return
        }
        XCTAssertEqual(text.contents, string.string)
    }


    /// Verifies that Underline Style gets effectively mapped.
    ///
    /// - Input: [Underline Style]Underlined![/Underline Style]
    ///
    /// - Output: <u>Underlined!</u>
    ///
    func testUnderlineStyleEffectivelyMapsIntoItsTreeRepresentation() {
        let attributes = UnderlineFormatter().apply(to: Constants.sampleAttributes)
        let string = NSAttributedString(string: "Underlined!", attributes: attributes)

        let node = AttributedStringParser().parse(string)
        XCTAssertEqual(node.children.count, 1)

        guard let paragraph = node.children.first as? ElementNode else {
            XCTFail()
            return
        }
        XCTAssertEqual(paragraph.name, StandardElementType.p.rawValue)
        XCTAssertEqual(paragraph.children.count, 1)

        guard let underlined = paragraph.children.first as? ElementNode else {
            XCTFail()
            return
        }
        XCTAssertEqual(underlined.name, StandardElementType.u.rawValue)
        XCTAssertEqual(underlined.children.count, 1)

        guard let text = underlined.children.first as? TextNode else {
            XCTFail()
            return
        }
        XCTAssertEqual(text.contents, string.string)
    }


    /// Verifies that Strike Style gets effectively mapped.
    ///
    /// - Input: [Strike Style]Strike![/Strike Style]
    ///
    /// - Output: <strike>Strike!</strike>
    ///
    func testStrikeStyleEffectivelyMapsIntoItsTreeRepresentation() {
        let attributes = StrikethroughFormatter().apply(to: Constants.sampleAttributes)
        let testingString = NSAttributedString(string: "Strike!", attributes: attributes)

        // Convert + Verify
        let node = AttributedStringParser().parse(testingString)
        XCTAssertEqual(node.children.count, 1)

        guard let paragraph = node.children.first as? ElementNode else {
            XCTFail()
            return
        }

        guard let strike = paragraph.children.first as? ElementNode else {
            XCTFail()
            return
        }
        XCTAssertEqual(strike.name, StandardElementType.strike.rawValue)
        XCTAssertEqual(strike.children.count, 1)

        guard let text = strike.children.first as? TextNode else {
            XCTFail()
            return
        }
        XCTAssertEqual(text.contents, testingString.string)
    }


    /// Verifies that Link Style gets effectively mapped.
    ///
    /// - Input: [Link Style]Yo! Yose! Yosemite![/Link Style]
    ///
    /// - Output: <a href="...">Yo! Yose! Yosemite!</a>
    ///
    func testLinkStyleEffectivelyMapsIntoItsTreeRepresentation() {
        let formatter = LinkFormatter()
        formatter.attributeValue = URL(string: "www.yosemite.com") as Any

        let attributes = formatter.apply(to: Constants.sampleAttributes)
        let testingString = NSAttributedString(string: "Yo! Yose! Yosemite!", attributes: attributes)

        // Convert + Verify
        let node = AttributedStringParser().parse(testingString)
        XCTAssertEqual(node.children.count, 1)

        guard let paragraph = node.children.first as? ElementNode else {
            XCTFail()
            return
        }
        XCTAssertEqual(paragraph.name, StandardElementType.p.rawValue)
        XCTAssertEqual(paragraph.children.count, 1)

        guard let link = paragraph.children.first as? ElementNode else {
            XCTFail()
            return
        }
        XCTAssertEqual(link.name, StandardElementType.a.rawValue)
        XCTAssertEqual(link.children.count, 1)

        guard let text = link.children.first as? TextNode else {
            XCTFail()
            return
        }
        XCTAssertEqual(text.contents, testingString.string)
    }


    /// Verifies that Lists get effectively mapped.
    ///
    /// - Input: <ul><li>First Line\nSecond Line</li></ul>
    ///
    /// - Output: <ul><li>First Line</li><li>Second Line</li></ul>
    ///
    func testListItemsRemainInTheSameContainingUnorderedList() {
        let firstText = "First Line"
        let secondText = "Second Line"

        let attributes = TextListFormatter(style: .unordered).apply(to: Constants.sampleAttributes)

        let text = firstText + String(.lineFeed) + secondText
        let testingString = NSMutableAttributedString(string: text, attributes: attributes)

        // Convert + Verify
        let node = AttributedStringParser().parse(testingString)
        XCTAssert(node.children.count == 1)

        let list = node.children.first as? ElementNode
        XCTAssertEqual(list?.name, "ul")
        guard list?.children.count == 2 else {
            XCTFail()
            return
        }

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


    /// Verifies that Lists get effectively mapped.
    ///
    /// - Input: <ol><li>First Line\nSecond Line</li></ol>
    ///
    /// - Output: <ol><li>First Line</li><li>Second Line</li></ol>
    ///
    func testListItemsRemainInTheSameContainingOrderedList() {
        let firstText = "First Line"
        let secondText = "Second Line"

        let attributes = TextListFormatter(style: .ordered).apply(to: Constants.sampleAttributes)

        let text = firstText + String(.lineFeed) + secondText
        let testingString = NSMutableAttributedString(string: text, attributes: attributes)

        // Convert + Verify
        let node = AttributedStringParser().parse(testingString)
        XCTAssert(node.children.count == 1)

        let list = node.children.first as? ElementNode
        XCTAssertEqual(list?.name, "ol")
        guard list?.children.count == 2 else {
            XCTFail()
            return
        }

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


    /// Verifies that Comments get effectively mapped.
    ///
    /// - Input: [Comment Attachment]I'm a comment. YEAH![Comment Attachment]
    ///
    /// - Output: <!-- Comment -->I'm a comment. YEAH!<!-- Comment -->
    ///
    func testCommentsArePreservedAndSerializedBack() {
        let attachment = CommentAttachment()
        attachment.text = "I'm a comment. YEAH!"
        let stringWithAttachment = NSAttributedString(attachment: attachment)

        let text = "Payload here"
        let testingString = NSMutableAttributedString(string: text)
        testingString.insert(stringWithAttachment, at: 0)
        testingString.append(stringWithAttachment)

        let node = AttributedStringParser().parse(testingString)
        XCTAssertEqual(node.children.count, 1)

        guard let paragraph = node.children.first as? ElementNode,
            paragraph.name == StandardElementType.p.rawValue else {
                XCTFail()
                return
        }

        XCTAssertEqual(paragraph.children.count, 3)

        guard let headNode = paragraph.children[0] as? CommentNode,
            let textNode = paragraph.children[1] as? TextNode,
            let tailNode = paragraph.children[2] as? CommentNode
        else {
            XCTFail()
            return
        }

        XCTAssertEqual(headNode.comment, attachment.text)
        XCTAssertEqual(tailNode.comment, attachment.text)
        XCTAssertEqual(textNode.contents, text)
    }


    /// Verifies that Line Attachments get effectively mapped.
    ///
    /// - Input: I'm a text line[Line Attachment]I'm a text line[Line Attachment]I'm a text line[Line Attachment]
    ///
    /// - Output: I'm a text line<hr>I'm a text line<hr>I'm a text line<hr>
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
        let node = AttributedStringParser().parse(testingString)

        guard let paragraphElement = node.children.first as? ElementNode else {
            XCTFail()
            return
        }

        XCTAssert(paragraphElement.children.count == 5)

        guard let firstLine = paragraphElement.children[0] as? ElementNode,
            let firstText = paragraphElement.children[1] as? TextNode,
            let secondLine = paragraphElement.children[2] as? ElementNode,
            let secondText = paragraphElement.children[3] as? TextNode,
            let thirdLine = paragraphElement.children[4] as? ElementNode
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


    /// Verifies that Header Style gets properly mapped.
    ///
    /// - Input: <h1>Aztec Rocks</h1>\nNewline?
    ///
    /// - Output: <h1>Aztec Rocks</h1>Newline?
    ///
    func testHeaderElementGetsProperlySerialiedBackIntoItsHtmlRepresentation() {

        let levels: [Header.HeaderType] = [.h1, .h2, .h3, .h4, .h5, .h6]

        for level in levels {
            let formatter = HeaderFormatter(headerLevel: level, placeholderAttributes: [:])

            let headingStyle = formatter.apply(to: Constants.sampleAttributes)
            let headingText = NSAttributedString(string: "Aztec Rocks\n", attributes: headingStyle)
            let regularText = NSAttributedString(string: "Newline?", attributes: Constants.sampleAttributes)

            let testingString = NSMutableAttributedString()
            testingString.append(headingText)
            testingString.append(regularText)

            // Convert + Verify
            let node = AttributedStringParser().parse(testingString)
            XCTAssert(node.children.count == 2)

            guard let headerNode = node.children[0] as? ElementNode else {
                XCTFail()
                return
            }

            guard let paragraphElement = node.children[1] as? ElementNode else {
                XCTFail()
                return
            }

            XCTAssertEqual(headerNode.children.count, 1)
            XCTAssertEqual(paragraphElement.children.count, 1)

            guard let headerTextNode = headerNode.children.first as? TextNode,
                let regularTextNode = paragraphElement.children.first as? TextNode
            else {
                XCTFail()
                return
            }

            XCTAssertEqual(headerNode.name, "h\(level.rawValue)")
            XCTAssertEqual(headerTextNode.contents, "Aztec Rocks")
            XCTAssertEqual(regularTextNode.contents, "Newline?")
        }
    }


    /// Verifies that Unknown HTML Attachments get properly mapped, and don't get nuked along the way.
    ///
    /// - Input: [Unknown HTML][Tail Comment]
    ///
    /// - Output: [Unknown HTML]<!-- Tail Comment -->
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
        let node = AttributedStringParser().parse(testingString)
        XCTAssert(node.children.count == 1)

        guard let paragraphNode = node.children.first as? ElementNode else {
            XCTFail()
            return
        }

        XCTAssert(paragraphNode.children.count == 3)

        guard let htmlNode = paragraphNode.children[0] as? ElementNode,
            let textNode = paragraphNode.children[1] as? TextNode,
            let commentNode = paragraphNode.children[2] as? CommentNode
        else {
            XCTFail()
            return
        }

        let reconvertedHTML = DefaultHTMLSerializer().serialize(htmlNode)

        XCTAssertEqual(reconvertedHTML, htmlAttachment.rawHTML)
        XCTAssertEqual(textNode.contents, textString.string)
        XCTAssertEqual(commentNode.comment, commentAttachment.text)
    }


    /// Verifies that Line Breaks get properly converted into BR Element, whenever the Leftmost + Rightmost elements
    /// are just plain strings.
    ///
    /// - Input: Hello\nWorld
    ///
    /// - Output: Hello<br>World
    ///
    func testNewlineIsAddedBetweenTwoNonBlocklevelElements() {
        let testingString = NSAttributedString(string: "Hello\nWorld")

        // Convert + Verify
        let node = AttributedStringParser().parse(testingString)
        XCTAssertEqual(node.children.count, 2)

        guard let paragraphElement1 = node.children[0] as? ElementNode else {
            XCTFail()
            return
        }

        guard let paragraphElement2 = node.children[1] as? ElementNode else {
            XCTFail()
            return
        }

        XCTAssertEqual(paragraphElement1.children.count, 1)
        XCTAssertEqual(paragraphElement2.children.count, 1)

        guard let helloNode = paragraphElement1.children.first as? TextNode,
            let worldNode = paragraphElement2.children.first as? TextNode
        else {
            XCTFail()
            return
        }

        XCTAssertEqual(helloNode.contents, "Hello")
        XCTAssertEqual(worldNode.contents, "World")
    }

    /// Verifies that Line Breaks do NOT get added into the Tree, whenever the Leftmost + Rightmost elements
    /// are H1.
    ///
    /// - Input: <h1>Hello\nWorld</h1>
    ///
    /// - Output: <h1>Hello</h1><h1>World</h1>
    ///
    func testNewlineDoesNotGetAddedBetweenTwoBlocklevelElements() {
        let formatter = HeaderFormatter(headerLevel: .h1, placeholderAttributes: nil)
        let headingStyle = formatter.apply(to: Constants.sampleAttributes)

        let testingString = NSAttributedString(string: "Hello\nWorld", attributes: headingStyle)

        // Convert + Verify
        let node = AttributedStringParser().parse(testingString)
        guard node.children.count == 2 else {
            XCTFail()
            return
        }

        guard let headingElementNode = node.children[0] as? ElementNode,
            let worldElementNode = node.children[1] as? ElementNode,
            let helloTextNode = headingElementNode.children[0] as? TextNode,
            let worldTextNode = worldElementNode.children[0] as? TextNode
        else {
            XCTFail()
            return
        }

        XCTAssertEqual(headingElementNode.name, "h1")
        XCTAssertEqual(worldElementNode.name, "h1")
        XCTAssertEqual(helloTextNode.contents, "Hello")
        XCTAssertEqual(worldTextNode.contents, "World")
    }


    /// Verifies that a List placed within a blockquote gets properly merged, when a Paragraph Break is detected
    /// (and split in two different paragraphs!).
    ///
    /// - Input: <blockquote><ul><li>First Line\nSecond Line</li></ul></blockquote>
    ///
    /// - Output: <blockquote><ul><li>First Line</li><li>Second Line</li></ul></blockquote>
    ///
    func testNestedListWithinBlockquoteGetsProperlyMerged() {
        let firstText = "First Line"
        let secondText = "Second Line"

        let text = firstText + String(.lineFeed) + secondText
        let testingString = NSMutableAttributedString(string: text, attributes: Constants.sampleAttributes)
        let testingRange = testingString.rangeOfEntireString

        BlockquoteFormatter().applyAttributes(to: testingString, at: testingRange)
        TextListFormatter(style: .ordered).applyAttributes(to: testingString, at: testingRange)

        // Convert + Verify
        let node = AttributedStringParser().parse(testingString)
        XCTAssert(node.children.count == 1)

        guard let blockquoteElementNode = node.children.first as? ElementNode,
            blockquoteElementNode.name == "blockquote",
            blockquoteElementNode.children.count == 1
        else {
            XCTFail()
            return
        }

        guard let unorderedElementNode = blockquoteElementNode.children.first as? ElementNode,
            unorderedElementNode.name == "ol",
            unorderedElementNode.children.count == 2
        else {
            XCTFail()
            return
        }

        guard let firstListItem = unorderedElementNode.children[0] as? ElementNode,
            let secondListItem = unorderedElementNode.children[1] as? ElementNode,
            firstListItem.name == "li",
            secondListItem.name == "li",
            firstListItem.children.count == 1,
            secondListItem.children.count == 1
        else {
            XCTFail()
            return
        }

        let firstTextItem = firstListItem.children.first as? TextNode
        let secondTextItem = secondListItem.children.first as? TextNode

        XCTAssertEqual(firstTextItem?.contents, firstText)
        XCTAssertEqual(secondTextItem?.contents, secondText)
    }


    /// Verifies that two paragraphs consisting on <ul><li><blockquote> get properly merged (which is up to the UL 
    /// level!)
    ///
    /// - Input: <ul><li><blockquote>First Line\nSecond Line</blockquote></li></ul>
    ///
    /// - Output: <ul><li><blockquote>First Line</blockquote></li><li><blockquote>Second Line</blockquote></li></ul>
    ///
    func testLineBreakEffectivelyCutsBlockquoteNestedWithinListItem() {
        let firstText = "First Line"
        let secondText = "Second Line"

        let text = firstText + String(.lineFeed) + secondText
        let testingString = NSMutableAttributedString(string: text, attributes: Constants.sampleAttributes)
        let testingRange = testingString.rangeOfEntireString

        TextListFormatter(style: .unordered).applyAttributes(to: testingString, at: testingRange)
        BlockquoteFormatter().applyAttributes(to: testingString, at: testingRange)

        // Convert + Verify
        let node = AttributedStringParser().parse(testingString)
        XCTAssert(node.children.count == 1)

        guard let unorderedElementNode = node.children.first as? ElementNode,
            unorderedElementNode.name == "ul",
            unorderedElementNode.children.count == 2
        else {
            XCTFail()
            return
        }

        guard let firstListItem = unorderedElementNode.children[0] as? ElementNode,
            let secondListItem = unorderedElementNode.children[1] as? ElementNode,
            firstListItem.name == "li",
            secondListItem.name == "li",
            firstListItem.children.count == 1,
            secondListItem.children.count == 1
        else {
            XCTFail()
            return
        }

        guard let firstBlockquoteNode = firstListItem.children.first as? ElementNode,
            let secondBlockquoteNode = secondListItem.children.first as? ElementNode,
            firstBlockquoteNode.name == "blockquote",
            firstBlockquoteNode.children.count == 1,
            secondBlockquoteNode.name == "blockquote",
            secondBlockquoteNode.children.count == 1
        else {
            XCTFail()
            return
        }

        let firstTextNode = firstBlockquoteNode.children.first as? TextNode
        let secondTextNode = secondBlockquoteNode.children.first as? TextNode

        XCTAssertEqual(firstTextNode?.contents, firstText)
        XCTAssertEqual(secondTextNode?.contents, secondText)
    }


    /// Verifies that the last List Item within a list *never* gets merged with the next Paragraph's List Item of
    /// the exact same leve.
    ///
    /// - Input: <ul><li><h1>Hello\nWorld</h1></li></ul>
    ///
    /// - Output: <ul><li><h1>Hello</h1></li><li><h1>World</h1></li></ul>
    ///
    func testLastListItemIsNeverMergedWithTheNextListItem() {
        let firstText = "Hello"
        let secondText = "World"

        let text = firstText + String(.lineFeed) + secondText
        let testingString = NSMutableAttributedString(string: text, attributes: Constants.sampleAttributes)
        let testingRange = testingString.rangeOfEntireString

        TextListFormatter(style: .unordered).applyAttributes(to: testingString, at: testingRange)
        HeaderFormatter().applyAttributes(to: testingString, at: testingRange)

        // Convert + Verify
        let node = AttributedStringParser().parse(testingString)
        XCTAssert(node.children.count == 1)

        guard let unorderedElementNode = node.children.first as? ElementNode,
            unorderedElementNode.name == "ul",
            unorderedElementNode.children.count == 2
        else {
            XCTFail()
            return
        }

        guard let firstListItem = unorderedElementNode.children[0] as? ElementNode,
            let secondListItem = unorderedElementNode.children[1] as? ElementNode,
            firstListItem.name == "li",
            secondListItem.name == "li",
            firstListItem.children.count == 1,
            secondListItem.children.count == 1
        else {
            XCTFail()
            return
        }

        guard let firstHeaderNode = firstListItem.children.first as? ElementNode,
            let secondHeaderNode = secondListItem.children.first as? ElementNode,
            firstHeaderNode.name == "h1",
            firstHeaderNode.children.count == 1,
            secondHeaderNode.name == "h1",
            secondHeaderNode.children.count == 1
        else {
            XCTFail()
            return
        }

        let firstTextNode = firstHeaderNode.children.first as? TextNode
        let secondTextNode = secondHeaderNode.children.first as? TextNode

        XCTAssertEqual(firstTextNode?.contents, firstText)
        XCTAssertEqual(secondTextNode?.contents, secondText)
    }


    /// Verifies that Unsupported HTML is preserved, and converted into Nodes.
    ///
    /// - Input: <span>Ehlo World!</span>
    ///
    /// - Output: The same!!
    ///
    func testUnsupportedHtmlIsPreservedAndSerializedBack() {
        let text = "Hello World!"
        let testingString = NSMutableAttributedString(string: text)

        let spanElement = ElementNode(type: .span)
        let representation = HTMLElementRepresentation(spanElement)

        // Store
        let unsupportedHTML = UnsupportedHTML(representations: [representation])
        testingString.addAttribute(.unsupportedHtml, value: unsupportedHTML, range: testingString.rangeOfEntireString)

        // Convert + Verify
        let node = AttributedStringParser().parse(testingString)
        XCTAssert(node.children.count == 1)

        let paragraphElement = node.children.first as? ElementNode
        XCTAssertEqual(paragraphElement?.name, StandardElementType.p.rawValue)
        XCTAssertEqual(paragraphElement?.children.count, 1)

        let restoredSpanNode = paragraphElement?.children.first as? ElementNode
        XCTAssert(restoredSpanNode?.name == StandardElementType.span.rawValue)
        XCTAssert(restoredSpanNode?.children.count == 1)

        let restoredTextNode = restoredSpanNode?.children.first as? TextNode
        XCTAssert(restoredTextNode?.contents == text)
    }


    /// Verifies that Unsupported HTML is preserved, and converted into Nodes.
    ///
    /// - Input: <span>Ehlo World!</span>
    ///
    /// - Output: The same!!
    ///
    func testMultipleNewlinesAreProperlyMappedIntoBreakNodes() {
        let text = "\nHello\n\n\nEveryone\n\nYEAH\nSarasa"
        let testingString = NSMutableAttributedString(string: text)


        // Convert + Verify
        let node = AttributedStringParser().parse(testingString)

        let expectedNodes = [
            0: nil,
            1: "Hello",
            2: nil,
            3: nil,
            4: "Everyone",
            5: nil,
            6: "YEAH",
            7: "Sarasa"
        ]

        for (index, text) in expectedNodes {
            guard let paragraphElement = node.children[index] as? ElementNode else {
                XCTFail()
                return
            }

            if let text = text {

                let textNode = paragraphElement.children.first as? TextNode
                XCTAssert(textNode?.contents == text)
            } else {
                XCTAssert(paragraphElement.children.count == 0)
            }
        }
    }


    /// Verifies that the Pre Element is effectively converted into an ElementNode.
    ///
    /// - Input: <pre>Ehlo World!</pre>
    ///
    /// - Output: The same!!
    ///
    func testPreIsEffectivelySerializedIntoPreElement() {
        let text = "Ehlo World!"
        let testingString = NSMutableAttributedString(string: text)

        let range = testingString.rangeOfEntireString

        let formatter = PreFormatter()
        formatter.applyAttributes(to: testingString, at: range)

        // Convert + Verify
        let node = AttributedStringParser().parse(testingString)
        XCTAssert(node.children.count == 1)

        let restoredSpanNode = node.children.first as? ElementNode
        XCTAssert(restoredSpanNode?.name == "pre")
        XCTAssert(restoredSpanNode?.children.count == 1)

        let restoredTextNode = restoredSpanNode?.children.first as? TextNode
        XCTAssert(restoredTextNode?.contents == text)
    }


    /// Verifies that the Div Element is effectively converted into an ElementNode.
    ///
    /// - Input: <div><div>Ehlo World!</div></div>
    ///
    /// - Output: Same as above!
    ///
    func testDivIsEffectivelySerializedIntoDivElement() {
        let text = "Ehlo World!"
        let testingString = NSMutableAttributedString(string: text)

        let range = testingString.rangeOfEntireString

        let formatter = HTMLDivFormatter()
        formatter.applyAttributes(to: testingString, at: range)
        formatter.applyAttributes(to: testingString, at: range)

        // Convert + Verify
        let node = AttributedStringParser().parse(testingString)
        XCTAssert(node.children.count == 1)

        let restoredDiv1Node = node.children.first as? ElementNode
        XCTAssert(restoredDiv1Node?.name == "div")
        XCTAssert(restoredDiv1Node?.children.count == 1)

        let restoredDiv2Node = restoredDiv1Node?.children.first as? ElementNode
        XCTAssert(restoredDiv2Node?.name == "div")
        XCTAssert(restoredDiv2Node?.children.count == 1)

        let restoredTextNode = restoredDiv2Node?.children.first as? TextNode
        XCTAssert(restoredTextNode?.contents == text)
    }


    /// Verifies that Images with no caption strings do not get wrapped up by a figcaption element.
    ///
    /// - Input: Image Attachment, with no caption set.
    ///
    /// - Output: <img src="."
    ///
    func testImagesWithNoCaptionWillNotProduceFigureNorFigcaptionElements() {
        let attachment = ImageAttachment(identifier: UUID().uuidString)
        let string = NSAttributedString(attachment: attachment)

        let node = AttributedStringParser().parse(string)
        XCTAssert(node.children.count == 1)

        let paragraphNode = node.firstChild(ofType: .p)
        XCTAssert(paragraphNode?.children.count == 1)

        let imageNode = paragraphNode?.firstChild(ofType: .img)
        XCTAssertNotNil(imageNode)
    }


    /// Verifies that Images with their .size property set to [.thumbnail, .medium, .large] do get explicit `width` and `height` attributes.
    ///
    /// - Input: Image Attachment, with it's size set to [.thumbnail, .medium, .large].
    ///
    /// - Output: <img width=".." height=".">, matching the tested size
    ///
    func testImagesWithNonDefaultSizeGetsExplicitWidthAndHeightAttributes() {
        let attachment = ImageAttachment(identifier: UUID().uuidString)
        attachment.image = Assets.imageIcon

        let string = NSAttributedString(attachment: attachment)
        let parser = AttributedStringParser()

        for targetSize in [ImageAttachment.Size.thumbnail, .medium, .large] {

            attachment.size = targetSize

            let node = parser.parse(string)
            XCTAssert(node.children.count == 1)

            let imageNode = node.firstChild(ofType: .p)?.firstChild(ofType: .img)
            XCTAssertNotNil(imageNode)

            let widthAttribute = imageNode?.attributes.first { $0.name == "width" }
            XCTAssertNotNil(widthAttribute)
            XCTAssertEqual(widthAttribute?.value.toString(), String(describing: Int(targetSize.width)))

            let heightAttribute = imageNode?.attributes.first { $0.name == "height" }
            XCTAssertNotNil(heightAttribute)
        }
    }


    /// Verifies that Images with their .size property set to [.full, .none] do NOT get explicit `width` and `height` attributes.
    ///
    /// - Input: Image Attachment, with it's size set to [.full, .none].
    ///
    /// - Output: <img />, with no "height=" nor "width=" attributes.
    ///
    func testImagesWithDefaultSizesDoNotGetExplicitDimensionAttributes() {
        let attachment = ImageAttachment(identifier: UUID().uuidString)
        attachment.image = Assets.imageIcon

        let string = NSAttributedString(attachment: attachment)
        let parser = AttributedStringParser()

        for targetSize in [ImageAttachment.Size.full, .none] {

            attachment.size = targetSize

            let node = parser.parse(string)
            XCTAssert(node.children.count == 1)

            let imageNode = node.firstChild(ofType: .p)?.firstChild(ofType: .img)
            XCTAssertNotNil(imageNode)

            let widthAttribute = imageNode?.attributes.first { $0.name == "width" }
            XCTAssertNil(widthAttribute)

            let heightAttribute = imageNode?.attributes.first { $0.name == "height" }
            XCTAssertNil(heightAttribute)
        }
    }


    /// Verifies that Images with it's caption field get properly wrapped within a figure element.
    ///
    /// - Input: Image Attachment, with it's caption set.
    ///
    /// - Output: <figure><img src="."><figcaption>Hello!</figcaption></figure>
    ///
    func testImagesWithCaptionProduceFigureAndFigcaptionElements() {
        let attachment = ImageAttachment(identifier: UUID().uuidString)
        let caption = NSAttributedString(string: "Hello!")
        
        let string = NSAttributedString(attachment: attachment, caption: caption, attributes: [:])

        let node = AttributedStringParser().parse(string)
        XCTAssert(node.children.count == 1)

        let figureNode = node.firstChild(ofType: .figure)
        XCTAssertEqual(figureNode?.children.count, 2)

        let imageNode = figureNode?.firstChild(ofType: .img)
        XCTAssertNotNil(imageNode)

        let figcaptionNode = figureNode?.firstChild(ofType: .figcaption)
        XCTAssertNotNil(figcaptionNode)
    }


    /// Verifies that Images with *Styled* caption fields get properly converted into their corresponding HTML
    ///
    /// - Input: Image Attachment, with a caption in Bold + Italics.
    ///
    /// - Output: <figure><img src="."><figcaption><strong><em>Bold and Italics</em></strong></figcaption></figure>
    ///
    func testFigcaptionGetsItsStyleProperlyParsed() {
        let boldAttributes = BoldFormatter().apply(to: Constants.sampleAttributes)
        let boldAndItalicAttributes = ItalicFormatter().apply(to: boldAttributes)

        let attachment = ImageAttachment(identifier: UUID().uuidString)
        let captionText = "Bold And Italics"
        let caption = NSAttributedString(string: captionText, attributes: boldAndItalicAttributes)
        let string = NSAttributedString(attachment: attachment, caption: caption, attributes: [:])

        let node = AttributedStringParser().parse(string)
        print(node)
        
        guard let figureNode = node.firstChild(ofType: .figure) else {
            XCTFail()
            return
        }
        
        guard let figcaptionNode = figureNode.firstChild(ofType: .figcaption) else {
            XCTFail()
            return
        }

        guard let strongNode = figcaptionNode.firstChild(ofType: .strong) else {
            XCTFail()
            return
        }

        guard let italicsNode = strongNode.firstChild(ofType: .em) else {
            XCTFail()
            return
        }

        guard let textNode = italicsNode.children.first as? TextNode else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(textNode.text(), captionText)
    }
    
    /// Verifies that Images with *Styled* caption fields get properly converted into their corresponding HTML
    ///
    /// - Input: Image Attachment, with a caption in Bold + Italics.
    ///
    /// - Output: <figure><img src="."><figcaption><strong><em>Bold and Italics</em></strong></figcaption></figure>
    ///
    func testAppendProperty() {
        let string = NSMutableAttributedString(string: "Hello world!", attributes: Constants.sampleAttributes)
        
        string.append(paragraphProperty: Figure())
        
        guard let paragraphStyle = string.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? ParagraphStyle else {
            XCTFail() // Expected a ParagraphStyle object.
            return
        }
        
        XCTAssert(paragraphStyle.hasProperty(where: { $0 is Figure }))
    }
}

// MARK: - Helpers
//
private extension AttributedStringParserTests {

    /// Constants
    ///
    struct Constants {
        static let sampleAttributes: [NSAttributedStringKey : Any] = [
            .font: UIFont.systemFont(ofSize: UIFont.systemFontSize),
            .paragraphStyle: NSParagraphStyle()
        ]
    }
}
