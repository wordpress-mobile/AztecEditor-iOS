import XCTest
@testable import Aztec

class DOMEditorTests: XCTestCase {

    typealias DOMEditor = Libxml2.DOMEditor
    typealias ElementNode = Libxml2.ElementNode
    typealias ElementNodeDescriptor = Libxml2.ElementNodeDescriptor
    typealias RootNode = Libxml2.RootNode
    typealias StandardElementType = Libxml2.StandardElementType
    typealias TextNode = Libxml2.TextNode

    // MARK: - Setup & Teardown

    override func setUp() {
        // By default we don't want tests continuing after a failure.
        //
        continueAfterFailure = false
    }

    // MARK: - replaceCharacters(inRange:with:)

    /// Test that inserting a new line after a DIV tag doesn't crash
    /// See https://github.com/wordpress-mobile/WordPress-Aztec-iOS/issues/90
    ///
    /// Input HTML: `<div>This is a paragraph in a div</div>\nThis is some unwrapped text`
    /// - location: the location after the div tag.
    ///
    /// Expected results:
    /// - Output: `<div>This is a paragraph in a div</div>\n\nThis is some unwrapped text`
    ///
    func testInsertNewlineAfterDivShouldNotCrash() {
        let text1 = "🇮🇳 This is a paragraph in a div"
        let text2 = "\(String(.newline))This is some unwrapped text"
        let divText = TextNode(text: text1)
        let div = ElementNode(name: "div", attributes: [], children: [divText])
        let unwrappedText = TextNode(text: text2)
        let rootNode = RootNode(children: [div, unwrappedText])
        let editor = DOMEditor(with: rootNode)

        // Temporary hack!
        Libxml2.SharedEditor.currentEditor = editor

        let range = NSRange(location: text1.characters.count, length: 0)

        editor.replace(range, with: String(.newline))

        XCTAssertEqual(rootNode.text(), "\(text1)\(String(.newline))\(text2)")

        // Temporary hack!
        Libxml2.SharedEditor.currentEditor = nil
    }

    /// ElementNode's `replaceCharacters(inRange:withString:)` has produced `TextNode` fragmentation
    /// more than once in the past.
    ///
    /// This test tries to make sure we don't have regressions causing `TextNode` fragmentation.
    ///
    func testInsertingTextDoesntFragmentTextNodes() {
        let textNode = TextNode(text: "")
        let rootNode = RootNode(children: [textNode])
        let editor = DOMEditor(with: rootNode)

        // Temporary hack!
        Libxml2.SharedEditor.currentEditor = editor

        editor.replace(NSRange(location: 0, length: 0), with: "a")
        editor.replace(NSRange(location: 1, length: 0), with: "b")
        editor.replace(NSRange(location: 2, length: 0), with: "c")

        XCTAssertEqual(rootNode.children.count, 1)
        XCTAssert(rootNode.children[0] is TextNode)

        // Temporary hack!
        Libxml2.SharedEditor.currentEditor = nil
    }


    /// Tests `replaceCharacters(inRange:withString:)`.
    ///
    /// Input HTML: `<rootNode>Click on this <a href="http://www.wordpress.com">link</a></rootNode>`
    /// - Range: the range of the full contents of the `<a>` node.
    /// - New String: "link!"
    ///
    /// Expected results:
    /// - Output: `<rootNode>Click on this link!</rootNode>`
    ///
    func testReplaceCharactersInRangeWithString() {
        let linkText = TextNode(text: "link")
        let linkElement = ElementNode(name: "a", attributes: [], children: [linkText])
        let preLinkText = "Click on this "
        let preLinkTextNode = TextNode(text: preLinkText)
        let rootNode = RootNode(children: [preLinkTextNode, linkElement])
        let editor = DOMEditor(with: rootNode)

        // Temporary hack!
        Libxml2.SharedEditor.currentEditor = editor

        let range = NSRange(location: 14, length: 4)
        let newString = "link!"

        editor.replace(range, with: newString)

        XCTAssertEqual(rootNode.children.count, 1)

        guard let textNode = rootNode.children[0] as? TextNode else {
            XCTFail("Expected a child text node")
            return
        }

        XCTAssertEqual(textNode.text(), "\(preLinkText)\(newString)")

        // Temporary hack!
        Libxml2.SharedEditor.currentEditor = nil
    }

    /// Tests `replaceCharacters(inRange:withString:)`.
    ///
    /// Input HTML: `<rootNode>Click on this <a href="http://www.wordpress.com">link</a></rootNode>`
    /// - Range: the range of the full contents of the `<a>` node.
    /// - New String: "link!"
    /// - Inherit Style: false
    ///
    /// Expected results:
    /// - Output: `<rootNode>Click on this link!</rootNode>`
    ///
    func testReplaceCharactersInRangeWithString2() {
        let text1 = "Click on this "
        let text2 = "link"
        let linkText = TextNode(text: text2)
        let linkElement = ElementNode(name: "a", attributes: [], children: [linkText])
        let preLinkText = TextNode(text: text1)
        let rootNode = RootNode(children: [preLinkText, linkElement])
        let editor = DOMEditor(with: rootNode)

        // Temporary hack!
        Libxml2.SharedEditor.currentEditor = editor

        let range = NSRange(location: 14, length: 4)
        let newString = "link!"
        let finalText = "\(text1)\(text2)!"

        editor.replace(range, with: newString)

        XCTAssertEqual(rootNode.children.count, 1)

        guard let textNode = rootNode.children[0] as? TextNode, textNode.text() == finalText else {

            XCTFail("Expected a text node, with the full text.")
            return
        }

        // Temporary hack!
        Libxml2.SharedEditor.currentEditor = nil
    }

    /// Tests `replaceCharacters(inRange:withString:)`.
    ///
    /// Input HTML: `<rootNode><p>Click on this <a href="http://www.wordpress.com">link</a></p></rootNode>`
    /// - Range: the range of the full contents of the `<a>` node.
    /// - New String: "link!"
    ///
    /// Expected results:
    /// - Output: `<div><p>Click on this </p>link!</div>`
    ///
    func testReplaceCharactersInRangeWithString3() {
        let text1 = "Click on this "
        let text2 = "link"
        let linkText = TextNode(text: text2)
        let linkElement = ElementNode(name: "a", attributes: [], children: [linkText])
        let preLinkText = TextNode(text: text1)
        let paragraph = ElementNode(name: "p", attributes: [], children: [preLinkText, linkElement])
        let rootNode = RootNode(children: [paragraph])
        let editor = DOMEditor(with: rootNode)

        // Temporary hack!
        Libxml2.SharedEditor.currentEditor = editor

        let range = NSRange(location: 14, length: 4)
        let newString = "link!"
        let finalText = "\(text1)\(text2)!"

        editor.replace(range, with: newString)

        XCTAssertEqual(rootNode.text(), finalText)
        XCTAssertEqual(rootNode.children.count, 1)

        guard let outParagraph = rootNode.children[0] as? ElementNode,
            outParagraph.name == StandardElementType.p.rawValue else {
                XCTFail("Expected a paragraph node.")
                return
        }

        XCTAssertEqual(outParagraph.text(), finalText)

        guard let outTextNode = outParagraph.children[0] as? TextNode,
            outTextNode.text() == finalText else {
                XCTFail("Expected a text node, with the full text.")
                return
        }

        // Temporary hack!
        Libxml2.SharedEditor.currentEditor = nil
    }


    /// Tests `replaceCharacters(inRange:withString:)`.
    ///
    /// Input HTML: `<rootNode><b>Hello</b> there!</rootNode>`
    /// - Range: the range of "there"
    /// - New String: "everyone"
    /// - Prefer left node: true
    ///
    /// Expected results:
    /// - Output: `<rootNode><b>Hello</b> everyone!</rootNode>`
    ///
    func testReplaceCharactersInRangeWithString4() {

        let text1 = "Hello"
        let space = " "
        let textToReplace = "there"
        let text2 = "\(space)\(textToReplace)!"

        let textToInsert = "everyone"
        let textToVerify = "\(space)\(textToInsert)!"

        let textNode1 = TextNode(text: text1)
        let boldNode = ElementNode(name: StandardElementType.b.rawValue, attributes: [], children: [textNode1])
        let textNode2 = TextNode(text: text2)
        let rootNode = RootNode(children: [boldNode, textNode2])
        let editor = DOMEditor(with: rootNode)

        // Temporary hack!
        Libxml2.SharedEditor.currentEditor = editor

        let replaceRange = NSRange(location: text1.characters.count + space.characters.count, length: textToReplace.characters.count)
        editor.replace(replaceRange, with: "everyone")

        XCTAssertEqual(rootNode.children.count, 2)
        XCTAssertEqual(rootNode.children[0], boldNode)

        guard let textNode = rootNode.children[1] as? TextNode, textNode.text() == textToVerify else {
            XCTFail("Expected a text node, with the full text.")
            return
        }

        // Temporary hack!
        Libxml2.SharedEditor.currentEditor = nil
    }


    /// Tests `replaceCharacters(inRange:withNodeName:withAttributes)`.
    ///
    /// Input HTML: `<p>Look at this photo:image.It's amazing</p>`
    /// - Range: the range of the image string.
    /// - New Node: <img>
    /// - Attributes:
    ///
    /// Expected results:
    /// - Output: `<p>Look at this photo:<img src="https://httpbin.org/image/jpeg.It's amazing" /></p>`
    ///
    func testReplaceCharactersInRangeWithNodeDescriptor() {
        let startText = "Look at this photo:"
        let middleText = "image"
        let endText = ".It's amazing"
        let paragraphText = TextNode(text: startText + middleText + endText)
        let paragraph = ElementNode(name: "p", attributes: [], children: [paragraphText])
        let rootNode = RootNode(children: [paragraph])
        let editor = DOMEditor(with: rootNode)

        // Temporary hack!
        Libxml2.SharedEditor.currentEditor = editor

        let range = NSRange(location: startText.characters.count, length: middleText.characters.count)
        let imgSrc = "https://httpbin.org/image/jpeg"

        let elementType = StandardElementType.img
        let imgNodeName = elementType.rawValue
        let attributes = [Libxml2.StringAttribute(name:"src", value: imgSrc)]
        let descriptor = ElementNodeDescriptor(elementType: elementType, attributes: attributes)

        paragraph.replaceCharacters(in: range, with: descriptor)

        XCTAssertEqual(paragraph.children.count, 3)

        guard let startNode = paragraph.children[0] as? TextNode, startNode.text() == startText else {

            XCTFail("Expected a text node")
            return
        }

        guard let imgNode = paragraph.children[1] as? ElementNode, imgNode.name == imgNodeName else {

            XCTFail("Expected a img node")
            return
        }

        guard let endNode = paragraph.children[2] as? TextNode, endNode.text() == endText else {
            
            XCTFail("Expected a text node")
            return
        }

        // Temporary hack!
        Libxml2.SharedEditor.currentEditor = nil
    }


    // MARK: - Wrapping Nodes

    /// Tests wrapping child nodes intersecting a certain range in a new `b` node.
    ///
    /// HTML String: <div><em>Hello </em>there!</div>
    /// Wrap range: (0...6)
    ///
    /// The result should be: <div><b><em>Hello </em></b>there!</div>
    ///
    func testWrapChildrenInNewBNode1() {

        let boldElementType = StandardElementType.b
        let range = NSRange(location: 0, length: 6)

        let textPart1 = "Hello "
        let textPart2 = "there!"

        let textNode1 = TextNode(text: textPart1)
        let textNode2 = TextNode(text: textPart2)

        let em = ElementNode(name: "em", attributes: [], children: [textNode1])
        let div = ElementNode(name: "div", attributes: [], children: [em, textNode2])
        let rootNode = RootNode(children: [div])

        let editor = DOMEditor(with: rootNode)

        // Temporary hack!
        Libxml2.SharedEditor.currentEditor = editor

        editor.wrap(range, in: ElementNodeDescriptor(elementType: boldElementType))

        XCTAssertEqual(div.children.count, 2)
        XCTAssertEqual(div.children[1], textNode2)

        guard let newBoldNode = div.children[0] as? ElementNode, newBoldNode.name == boldElementType.rawValue else {
            XCTFail("Expected a bold node here.")
            return
        }

        XCTAssertEqual(newBoldNode.children.count, 1)

        guard let newEmNode = newBoldNode.children[0] as? ElementNode, newEmNode.name == em.name else {
            XCTFail("Expected an em node here.")
            return
        }

        XCTAssertEqual(newEmNode.children.count, 1)
        XCTAssertEqual(newEmNode.children[0], textNode1)

        // Temporary hack!
        Libxml2.SharedEditor.currentEditor = nil
    }


    /// Tests wrapping child nodes intersecting a certain range in a new `b` node.
    ///
    /// HTML String: <div><em>Hello </em><u>there!</u></div>
    /// Wrap range: full text range / full div node range
    ///
    /// The result should be: <div><b><em>Hello </em><u>there!</u></b></div>
    ///
    func testWrapChildrenInNewBNode2() {

        let boldNodeName = "b"

        let textPart1 = "Hello "
        let textPart2 = "there!"

        let textNode1 = TextNode(text: textPart1)
        let textNode2 = TextNode(text: textPart2)

        let em = ElementNode(name: "em", attributes: [], children: [textNode1])
        let underline = ElementNode(name: "u", attributes: [], children: [textNode2])
        let div = ElementNode(name: "div", attributes: [], children: [em, underline])
        let rootNode = RootNode(children: [div])

        let editor = DOMEditor(with: rootNode)

        // Temporary hack!
        Libxml2.SharedEditor.currentEditor = editor

        editor.wrap(div.range(), in: ElementNodeDescriptor(name: boldNodeName))

        XCTAssertEqual(div.children.count, 1)

        guard let boldNode = div.children[0] as? ElementNode else {
            XCTFail("Expected a bold node here.")
            return
        }

        XCTAssertEqual(boldNode.name, boldNodeName)
        XCTAssertEqual(boldNode.children.count, 2)
        XCTAssertEqual(boldNode.children[0], em)
        XCTAssertEqual(boldNode.children[1], underline)

        XCTAssertEqual(em.children.count, 1)
        XCTAssertEqual(em.children[0], textNode1)

        XCTAssertEqual(underline.children.count, 1)
        XCTAssertEqual(underline.children[0], textNode2)

        // Temporary hack!
        Libxml2.SharedEditor.currentEditor = nil
    }


    /// Tests wrapping child nodes intersecting a certain range in a new `b` node.
    ///
    /// HTML String: <div><em>Hello </em><u>there!</u></div>
    /// Wrap range: (2...8)
    ///
    /// The result should be: <div><em>He</em><b><em>llo </em><u>ther</u></b><u>e!</u></div>
    ///
    func testWrapChildrenInNewBNode3() {

        let boldNodeName = StandardElementType.b.rawValue

        let textPart1 = "Hello "
        let textPart2 = "there!"

        let textNode1 = TextNode(text: textPart1)
        let textNode2 = TextNode(text: textPart2)

        let em = ElementNode(name: StandardElementType.em.rawValue, attributes: [], children: [textNode1])
        let underline = ElementNode(name: StandardElementType.u.rawValue, attributes: [], children: [textNode2])
        let div = ElementNode(name: StandardElementType.div.rawValue, attributes: [], children: [em, underline])
        let rootNode = RootNode(children: [div])

        let editor = DOMEditor(with: rootNode)

        let range = NSRange(location: 2, length: 8)

        // Temporary hack!
        Libxml2.SharedEditor.currentEditor = editor

        editor.wrap(range, in: ElementNodeDescriptor(name: boldNodeName))

        XCTAssertEqual(rootNode.children.count, 1)

        // 1st level nodes

        guard let outDiv = rootNode.children[0] as? ElementNode else {
            XCTFail("Expected an element node.")
            return
        }

        XCTAssertEqual(outDiv.name, StandardElementType.div.rawValue)
        XCTAssertEqual(outDiv.children.count, 3)

        // 2nd level nodes

        guard let outEm = outDiv.children[0] as? ElementNode else {
            XCTFail("Expected an element node.")
            return
        }

        XCTAssertEqual(outEm.name, StandardElementType.em.rawValue)
        XCTAssertEqual(outEm.children.count, 1)
        XCTAssert(outEm.children[0] is TextNode)
        XCTAssertEqual(outEm.text(), "He")

        guard let outB = outDiv.children[1] as? ElementNode else {
            XCTFail("Expected an element node.")
            return
        }

        XCTAssertEqual(outB.name, StandardElementType.b.rawValue)
        XCTAssertEqual(outB.children.count, 2)

        guard let outU = outDiv.children[2] as? ElementNode else {
            XCTFail("Expected an element node.")
            return
        }

        XCTAssertEqual(outU.name, StandardElementType.u.rawValue)
        XCTAssertEqual(outU.children.count, 1)
        XCTAssert(outU.children[0] is TextNode)
        XCTAssertEqual(outU.text(), "e!")

        // 3rd level nodes

        guard let outEm2 = outB.children[0] as? ElementNode else {
            XCTFail("Expected an element node.")
            return
        }

        XCTAssertEqual(outEm2.name, StandardElementType.em.rawValue)
        XCTAssertEqual(outEm2.children.count, 1)
        XCTAssert(outEm2.children[0] is TextNode)
        XCTAssertEqual(outEm2.text(), "llo ")

        guard let outU2 = outB.children[1] as? ElementNode else {
            XCTFail("Expected an element node.")
            return
        }

        XCTAssertEqual(outU2.name, StandardElementType.u.rawValue)
        XCTAssertEqual(outU2.children.count, 1)
        XCTAssert(outU2.children[0] is TextNode)
        XCTAssertEqual(outU2.text(), "ther")

        // Temporary hack!
        Libxml2.SharedEditor.currentEditor = nil
    }

    /// Tests that wrapping a range in a node already present in that range, doesn't duplicate the
    /// node.
    ///
    /// HTML String: <div><b>Hello there</b></div>
    /// Wrap range: (0...11)
    ///
    /// Expected results:
    ///     - The output should match the input.
    ///
    func testWrapChildrenIntersectingRangeWithEquivalentNodeNames1() {
        let textNode = TextNode(text: "Hello there")
        let boldNode = ElementNode(name: "b", attributes: [], children: [textNode])
        let divNode = ElementNode(name: "div", attributes: [], children: [boldNode])
        let rootNode = RootNode(children: [divNode])

        let editor = DOMEditor(with: rootNode)

        // Temporary hack!
        Libxml2.SharedEditor.currentEditor = editor

        let range = NSRange(location: 0, length: 11)

        let boldElementDescriptor = ElementNodeDescriptor(elementType: .b)
        editor.wrap(range, in: boldElementDescriptor)

        XCTAssertEqual(divNode.children.count, 1)

        guard let newBoldNode = divNode.children[0] as? ElementNode, newBoldNode.name == "b" else {

            XCTFail("Expected a bold node")
            return
        }
        
        XCTAssertEqual(newBoldNode.children.count, 1)
        XCTAssertNotNil(newBoldNode.children[0] as? TextNode)
        XCTAssertEqual(boldNode.text(), newBoldNode.text())

        // Temporary hack!
        Libxml2.SharedEditor.currentEditor = nil
    }

    // MARK: - Merging Siblings

    /// Tests that `mergeBlockLevelElementRight(endingAt:)` works properly.
    ///
    /// - Input:
    ///     - HTML: "<root><p>Hello</p><blockquote>world!</blockquote></root>"
    ///     - Separation location: length of "Hello"
    ///
    /// - Expected results:
    ///     - HTML: "<root><p>Helloworld!</p></root>"
    ///
    func testMergeSiblings() {
        let text1 = "Hello"
        let text2 = "world!"

        let textNode1 = TextNode(text: text1)
        let textNode2 = TextNode(text: text2)

        let paragraph = ElementNode(name: StandardElementType.p.rawValue, attributes: [], children: [textNode1])
        let blockquote = ElementNode(name: StandardElementType.blockquote.rawValue, attributes: [], children: [textNode2])
        let rootNode = RootNode(children: [paragraph, blockquote])

        let editor = DOMEditor(with: rootNode)

        // Temporary hack!
        Libxml2.SharedEditor.currentEditor = editor

        editor.mergeBlockLevelElementRight(endingAt: textNode1.length())

        XCTAssertEqual(rootNode.children.count, 1)

        guard let newParagraph = rootNode.children[0] as? ElementNode,
            newParagraph.name == StandardElementType.p.rawValue else {
                XCTFail("Expected a paragraph node.")
                return
        }

        /// - TODO: this test should be modified to make sure the child of newParagraph is a single
        ///     TextNode element.  For the time being we're purposedly ignoring this, since there are
        ///     other priorities.  This is the recommented code for that:
        ///
        /// XCTAssertEqual(newParagraph.children.count, 1)
        ///
        /// guard let newTextNode = newParagraph.children[0] as? TextNode else {
        ///     XCTFail("Expected a TextNode.")
        ///     return
        /// }
        ///
        /// XCTAssertEqual(newTextNode.text(), "\(text1)\(text2)")

        XCTAssertEqual(newParagraph.children.count, 1)
        XCTAssert(newParagraph.children[0] is TextNode)
        XCTAssertEqual(newParagraph.children[0].text(), "\(text1)\(text2)")

        // Temporary hack!
        Libxml2.SharedEditor.currentEditor = nil
    }

    /// Tests that `findSiblings(separatedAt:)` works properly.
    ///
    /// - Input:
    ///     - HTML: "<root><p>Hello</p><blockquote>world!</blockquote></root>"
    ///     - Separation location: first DOM location
    ///
    /// - Expected results:
    ///     - The output should not change.
    ///
    func testMergeSiblings2() {
        let text1 = "Hello"
        let text2 = "world!"

        let textNode1 = TextNode(text: text1)
        let textNode2 = TextNode(text: text2)

        let paragraph = ElementNode(name: StandardElementType.p.rawValue, attributes: [], children: [textNode1])
        let blockquote = ElementNode(name: StandardElementType.blockquote.rawValue, attributes: [], children: [textNode2])
        let rootNode = RootNode(children: [paragraph, blockquote])

        let editor = DOMEditor(with: rootNode)

        // Temporary hack!
        Libxml2.SharedEditor.currentEditor = editor

        editor.mergeBlockLevelElementRight(endingAt: 0)

        XCTAssertEqual(rootNode.children.count, 2)

        guard let newParagraph = rootNode.children[0] as? ElementNode,
            newParagraph.name == StandardElementType.p.rawValue else {
                XCTFail("Expected a paragraph node.")
                return
        }

        XCTAssertEqual(newParagraph, paragraph)
        XCTAssertEqual(newParagraph.text(), text1)

        guard let newBlockquote = rootNode.children[1] as? ElementNode,
            newBlockquote.name == StandardElementType.blockquote.rawValue else {
                XCTFail("Expected a paragraph node.")
                return
        }

        XCTAssertEqual(newBlockquote, blockquote)
        XCTAssertEqual(newBlockquote.text(), text2)

        // Temporary hack!
        Libxml2.SharedEditor.currentEditor = nil
    }

    /// Tests that `findSiblings(separatedAt:)` works properly.
    ///
    /// - Input:
    ///     - HTML: "<root><p>Hello</p><blockquote>world!</blockquote></root>"
    ///     - Separation location: final DOM location
    ///
    /// - Expected results:
    ///     - The output should not change.
    ///
    func testMergeSiblings3() {
        let text1 = "Hello"
        let text2 = "world!"

        let textNode1 = TextNode(text: text1)
        let textNode2 = TextNode(text: text2)

        let paragraph = ElementNode(name: StandardElementType.p.rawValue, attributes: [], children: [textNode1])
        let blockquote = ElementNode(name: StandardElementType.blockquote.rawValue, attributes: [], children: [textNode2])
        let rootNode = RootNode(children: [paragraph, blockquote])

        let editor = DOMEditor(with: rootNode)

        // Temporary hack!
        Libxml2.SharedEditor.currentEditor = editor

        editor.mergeBlockLevelElementRight(endingAt: text1.characters.count + text2.characters.count)

        XCTAssertEqual(rootNode.children.count, 2)

        guard let newParagraph = rootNode.children[0] as? ElementNode,
            newParagraph.name == StandardElementType.p.rawValue else {
                XCTFail("Expected a paragraph node.")
                return
        }

        XCTAssertEqual(newParagraph, paragraph)
        XCTAssertEqual(newParagraph.text(), text1)

        guard let newBlockquote = rootNode.children[1] as? ElementNode,
            newBlockquote.name == StandardElementType.blockquote.rawValue else {
                XCTFail("Expected a paragraph node.")
                return
        }

        XCTAssertEqual(newBlockquote, blockquote)
        XCTAssertEqual(newBlockquote.text(), text2)

        // Temporary hack!
        Libxml2.SharedEditor.currentEditor = nil
    }

    // MARK: - Splitting


    /// Tests that splitting an element node at a specified text location works fine.
    ///
    /// HTML string: <div><p>Hello 🇮🇳 World!</p></div>
    /// Split target: the paragraph tag
    /// Split Location: right after the flag
    ///
    /// The results should be:
    ///     - The output should be: <div><p>Hello 🇮🇳</p><p> World!</p></div>
    ///
    func testSplitAtLocation() {
        let text1 = "Hello 🇮🇳"
        let text2 = " World!"

        let textNode = TextNode(text: "\(text1)\(text2)")
        let paragraph = ElementNode(name: "p", attributes: [], children: [textNode])
        let div = ElementNode(name: "div", attributes: [], children: [paragraph])
        let rootNode = RootNode(children: [div])
        let editor = DOMEditor(with: rootNode)

        // Temporary hack!
        Libxml2.SharedEditor.currentEditor = editor

        let splitLocation = text1.characters.count
        editor.split(paragraph, at: splitLocation)

        XCTAssertEqual(div.children.count, 2)

        guard let newParagraph1 = div.children[0] as? ElementNode, newParagraph1.text() == text1 else {
            XCTFail("Expected the first new paragraph to exist and be the same as the original paragraph.")
            return
        }

        guard let newParagraph2 = div.children[1] as? ElementNode, newParagraph2.text() == text2 else {
            XCTFail("Expected the first new paragraph to exist.")
            return
        }

        // Temporary hack!
        Libxml2.SharedEditor.currentEditor = nil
    }
}
