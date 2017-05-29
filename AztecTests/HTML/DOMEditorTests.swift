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

    // MARK: - Appending
/*
    /// Tests that appending text to a text node works fine.
    ///
    /// HTML string: <p>Hello World!</p>
    /// Text to append: " Hello There!"
    ///
    /// The results should be: "Hello World! Hello There!"
    ///
    func testAppend() {
        let textInNode = "Hello World!"
        let textToAppend = " Hello There!"
        let fullText = "\(textInNode)\(textToAppend)"

        let textNode = TextNode(text: textInNode)
        let paragraphNode = ElementNode(name: StandardElementType.p.rawValue, attributes: [], children: [textNode])
        let rootNode = RootNode(children: [paragraphNode])
        let editor = DOMEditor(with: rootNode)

        editor.append(textToAppend, to: textNode)

        XCTAssertEqual(paragraphNode.text(), fullText)
    }


    /// Tests that appending text to a text node works fine, when the text to append contains line
    /// breaks.
    ///
    /// HTML string: <p>Hello World!</p>
    /// Text to append: "\nHello There!"
    ///
    /// The results should be: <p>Hello World!<br>Hello There!</p>
    ///
    func testAppendWithBr1() {
        let textInNode = "Hello World!"
        let textToAppend = "Hello There!"
        let textToAppendWithBR = "\(String(.newline))\(textToAppend)"

        let textNode = TextNode(text: textInNode)
        let paragraphNode = ElementNode(name: StandardElementType.p.rawValue, attributes: [], children: [textNode])
        let rootNode = RootNode(children: [paragraphNode])
        let editor = DOMEditor(with: rootNode)

        XCTAssertEqual(paragraphNode.children.count, 1)

        editor.append(textToAppendWithBR, to: textNode)

        XCTAssertEqual(paragraphNode.children.count, 3)

        guard let textNode1 = paragraphNode.children[0] as? TextNode else {
            XCTFail("Expected a text node.")
            return
        }

        guard let brNode = paragraphNode.children[1] as? ElementNode,
            brNode.name == StandardElementType.br.rawValue else {

                XCTFail("Expected a BR node.")
                return
        }

        guard let textNode2 = paragraphNode.children[2] as? TextNode else {
            XCTFail("Expected a text node.")
            return
        }

        XCTAssertEqual(textNode1.text(), textInNode)
        XCTAssertEqual(textNode2.text(), textToAppend)
    }

    /// Tests that appending text to a text node works fine, when the text to append contains line
    /// breaks.
    ///
    /// HTML string: <p>Hello World!</p>
    /// Text to append: "\nHello There!\nHow are you?"
    ///
    /// The results should be: <p>Hello World!<br>Hello There!<br>How are you?</p>
    ///
    func testAppendWithBr2() {
        let textInNode = "Hello World!"
        let textToAppend1 = "Hello There!"
        let textToAppend2 = "How are you?"

        let fullTextToAppend = "\(String(.newline))\(textToAppend1)\(String(.newline))\(textToAppend2)"

        let textNode = TextNode(text: textInNode)
        let paragraphNode = ElementNode(name: StandardElementType.p.rawValue, attributes: [], children: [textNode])
        let rootNode = RootNode(children: [paragraphNode])
        let editor = DOMEditor(with: rootNode)

        XCTAssertEqual(paragraphNode.children.count, 1)

        editor.append(fullTextToAppend, to: textNode)

        XCTAssertEqual(paragraphNode.children.count, 5)

        guard let textNode1 = paragraphNode.children[0] as? TextNode else {
            XCTFail("Expected a text node.")
            return
        }

        guard let brNode1 = paragraphNode.children[1] as? ElementNode,
            brNode1.name == StandardElementType.br.rawValue else {

                XCTFail("Expected a BR node.")
                return
        }

        guard let textNode2 = paragraphNode.children[2] as? TextNode else {
            XCTFail("Expected a text node.")
            return
        }

        guard let brNode2 = paragraphNode.children[3] as? ElementNode,
            brNode2.name == StandardElementType.br.rawValue else {

                XCTFail("Expected a BR node.")
                return
        }

        guard let textNode3 = paragraphNode.children[4] as? TextNode else {
            XCTFail("Expected a text node.")
            return
        }

        XCTAssertEqual(textNode1.text(), textInNode)
        XCTAssertEqual(textNode2.text(), textToAppend1)
        XCTAssertEqual(textNode3.text(), textToAppend2)
    }

    /// Tests that appending text to a text node works fine, when the text to append contains line
    /// breaks.
    ///
    /// HTML string: <p>Hello World!</p>
    /// Text to append: "\n\n"
    ///
    /// The results should be: <p>Hello World!<br>Hello There!<br>How are you?</p>
    ///
    func testAppendWithBr3() {
        let textInNode = "Hello World!"
        let textToAppend = "\(String(.newline))\(String(.newline))"

        let textNode = TextNode(text: textInNode)
        let paragraphNode = ElementNode(name: StandardElementType.p.rawValue, attributes: [], children: [textNode])
        let rootNode = RootNode(children: [paragraphNode])
        let editor = DOMEditor(with: rootNode)

        XCTAssertEqual(paragraphNode.children.count, 1)

        editor.append(textToAppend, to: textNode)

        XCTAssertEqual(paragraphNode.children.count, 3)

        guard let textNode1 = paragraphNode.children[0] as? TextNode else {
            XCTFail("Expected a text node.")
            return
        }

        guard let brNode1 = paragraphNode.children[1] as? ElementNode,
            brNode1.name == StandardElementType.br.rawValue else {

                XCTFail("Expected a BR node.")
                return
        }

        guard let brNode2 = paragraphNode.children[2] as? ElementNode,
            brNode2.name == StandardElementType.br.rawValue else {

                XCTFail("Expected a BR node.")
                return
        }

        XCTAssertEqual(textNode1.text(), textInNode)
    }
*/
    // MARK: - Prepend
/*
    /// Tests that `prepend(_ child:)` works.
    ///
    /// Inputs:
    ///     - HTML: "<b> world!</b>"
    ///     - String to prepend: "Hello"
    ///
    /// Verifications:
    ///     - HTML: "<b>Hello world!</b>
    ///
    func testPrepend() {
        let text1 = "Hello"
        let text2 = " world!"
        let fullText = "\(text1)\(text2)"

        let textNode1 = TextNode(text: text1)
        let textNode2 = TextNode(text: text2)
        let boldNode = ElementNode(name: StandardElementType.b.rawValue, attributes: [], children: [textNode2])
        let rootNode = RootNode(children: [boldNode])
        let editor = DOMEditor(with: rootNode)

        XCTAssertEqual(boldNode.children.count, 1)
        XCTAssertEqual(boldNode.children[0], textNode2)
        XCTAssertEqual(boldNode.text(), text2)

        editor.prepend(textNode1, to: boldNode)

        XCTAssertEqual(boldNode.children.count, 1)
        XCTAssertEqual(boldNode.children[0].text(), fullText)
        XCTAssertEqual(boldNode.text(), fullText)
    }


    /// Tests that prepending text to a text node works fine.
    ///
    /// HTML string: <p>Hello World!</p>
    /// Text to prepend: "Hello There! "
    ///
    /// The results should be: "Hello There! Hello World!"
    ///
    func testPrepend() {
        let textInNode = "Hello World!"
        let textToPrepend = "Hello There! "
        let fullText = "\(textToPrepend)\(textInNode)"

        let textNode = TextNode(text: textInNode)
        let paragraphNode = ElementNode(name: StandardElementType.p.rawValue, attributes: [], children: [textNode])
        let rootNode = RootNode(children: [paragraphNode])
        let editor = DOMEditor(with: rootNode)

        editor.prepend(textToPrepend, to: textNode)

        XCTAssertEqual(paragraphNode.text(), fullText)
    }

    /// Tests that prepending text to a text node works fine, when the text to prepend contains line
    /// breaks.
    ///
    /// HTML string: <p>Hello World!</p>
    /// Text to prepend: "Hello There!\n"
    ///
    /// The results should be: <p>Hello There!<br>Hello World!</p>
    ///
    func testPrependWithBr1() {
        let textInNode = "Hello World!"
        let textToPrepend = "Hello There!"
        let textToPrependWithBR = "\(textToPrepend)\(String(.newline))"

        let textNode = TextNode(text: textInNode)
        let paragraphNode = ElementNode(name: StandardElementType.p.rawValue, attributes: [], children: [textNode])
        let rootNode = RootNode(children: [paragraphNode])
        let editor = DOMEditor(with: rootNode)

        XCTAssertEqual(paragraphNode.children.count, 1)

        editor.prepend(textToPrependWithBR, to: textNode)

        XCTAssertEqual(paragraphNode.children.count, 3)

        guard let textNode1 = paragraphNode.children[0] as? TextNode else {
            XCTFail("Expected a text node.")
            return
        }

        guard let brNode = paragraphNode.children[1] as? ElementNode,
            brNode.name == StandardElementType.br.rawValue else {

                XCTFail("Expected a BR node.")
                return
        }

        guard let textNode2 = paragraphNode.children[2] as? TextNode else {
            XCTFail("Expected a text node.")
            return
        }

        XCTAssertEqual(textNode1.text(), textToPrepend)
        XCTAssertEqual(textNode2.text(), textInNode)
    }

    /// Tests that prepending text to a text node works fine, when the text to prepend contains line
    /// breaks.
    ///
    /// HTML string: <p>Hello World!</p>
    /// Text to prepend: "Hello There!\nHow are you?\n"
    ///
    /// The results should be: <p>Hello There!<br>nHow are you?<br>Hello World!</p>
    ///
    func testPrependWithBr2() {
        let textInNode = "Hello World!"
        let textToPrepend1 = "Hello There!"
        let textToPrepend2 = "How are you?"

        let fullTextToPrepend = "\(textToPrepend1)\(String(.newline))\(textToPrepend2)\(String(.newline))"

        let textNode = TextNode(text: textInNode)
        let paragraphNode = ElementNode(name: StandardElementType.p.rawValue, attributes: [], children: [textNode])
        let rootNode = RootNode(children: [paragraphNode])
        let editor = DOMEditor(with: rootNode)

        XCTAssertEqual(paragraphNode.children.count, 1)

        editor.prepend(fullTextToPrepend, to: textNode)

        XCTAssertEqual(paragraphNode.children.count, 5)

        guard let textNode1 = paragraphNode.children[0] as? TextNode else {
            XCTFail("Expected a text node.")
            return
        }

        guard let brNode1 = paragraphNode.children[1] as? ElementNode,
            brNode1.name == StandardElementType.br.rawValue else {

                XCTFail("Expected a BR node.")
                return
        }

        guard let textNode2 = paragraphNode.children[2] as? TextNode else {
            XCTFail("Expected a text node.")
            return
        }

        guard let brNode2 = paragraphNode.children[3] as? ElementNode,
            brNode2.name == StandardElementType.br.rawValue else {

                XCTFail("Expected a BR node.")
                return
        }

        guard let textNode3 = paragraphNode.children[4] as? TextNode else {
            XCTFail("Expected a text node.")
            return
        }

        XCTAssertEqual(textNode1.text(), textToPrepend1)
        XCTAssertEqual(textNode2.text(), textToPrepend2)
        XCTAssertEqual(textNode3.text(), textInNode)
    }*/

    // MARK: - replaceCharacters(inRange:with:)

/*
    /// Tests that replacing text to a text node works fine.
    ///
    /// Initial DOM: <p>Hello World!</p>
    /// Range to replace: the range of "Hello"
    /// New text for the replaced range: "Good Bye"
    ///
    /// The results should be: <p>Good Bye World!</p>"
    ///
    func testReplaceCharacters1() {
        let helloText = "Hello"
        let worldText = " World!"
        let initialText = "\(helloText)\(worldText)"

        let byeText = "Good Bye"

        let finalText = "\(byeText)\(worldText)"

        let textNode = TextNode(text: initialText)
        let paragraphNode = ElementNode(name: StandardElementType.p.rawValue, attributes: [], children: [textNode])

        XCTAssertEqual(paragraphNode.children.count, 1)

        let replaceRange = NSRange(location: 0, length: helloText.characters.count)

        textNode.replaceCharacters(inRange: replaceRange, withString: byeText)

        XCTAssertEqual(paragraphNode.children.count, 1)
        XCTAssertEqual(paragraphNode.children[0], textNode)
        XCTAssertEqual(paragraphNode.text(), finalText)
    }

    /// Tests that replacing text to a text node works fine.
    ///
    /// Initial DOM: <p>Hello World!</p>
    /// Range to replace: the range of " World!"
    /// New text for the replaced range: " City!"
    ///
    /// The results should be: <p>Hello City!</p>"
    ///
    func testReplaceCharacters2() {
        let helloText = "Hello"
        let worldText = " World!"
        let initialText = "\(helloText)\(worldText)"

        let cityText = " City!"

        let finalText = "\(helloText)\(cityText)"

        let textNode = TextNode(text: initialText)
        let paragraphNode = ElementNode(name: StandardElementType.p.rawValue, attributes: [], children: [textNode])

        XCTAssertEqual(paragraphNode.children.count, 1)

        let replaceRange = NSRange(location: helloText.characters.count, length: worldText.characters.count)

        textNode.replaceCharacters(inRange: replaceRange, withString: cityText)

        XCTAssertEqual(paragraphNode.children.count, 1)
        XCTAssertEqual(paragraphNode.children[0], textNode)
        XCTAssertEqual(paragraphNode.text(), finalText)
    }

    /// Tests that replacing text to a text node works fine.
    ///
    /// Initial DOM: <p>Hello World!</p>
    /// Range to replace: the range of "Hello "
    /// New text for the replaced range: "Good Bye\n"
    ///
    /// The results should be: <p>Hello<br>World!</p>"
    ///
    func testReplaceCharactersWithBr1() {
        let helloText = "Hello "
        let worldText = "World!"
        let initialText = "\(helloText)\(worldText)"

        let helloAndBreakText = "\(helloText)\n"

        let textNode = TextNode(text: initialText)
        let paragraphNode = ElementNode(name: StandardElementType.p.rawValue, attributes: [], children: [textNode])

        XCTAssertEqual(paragraphNode.children.count, 1)

        let replaceRange = NSRange(location: 0, length: helloText.characters.count)

        textNode.replaceCharacters(inRange: replaceRange, withString: helloAndBreakText)

        XCTAssertEqual(paragraphNode.children.count, 3)

        guard let textNode1 = paragraphNode.children[0] as? TextNode else {
            XCTFail("Expected a text node.")
            return
        }

        guard let breakNode = paragraphNode.children[1] as? ElementNode,
            breakNode.name == StandardElementType.br.rawValue else {
                XCTFail("Expected a BR node.")
                return
        }

        guard let textNode2 = paragraphNode.children[2] as? TextNode else {
            XCTFail("Expected a text node.")
            return
        }

        XCTAssertEqual(textNode1.text(), helloText)
        XCTAssertEqual(textNode2.text(), worldText)
    }

    /// Tests that replacing text to a text node works fine.
    ///
    /// Initial DOM: <p>Hello World!</p>
    /// Range to replace: the range of " World!"
    /// New text for the replaced range: "\nWorld!"
    ///
    /// The results should be: <p>Hello<br>World!</p>"
    ///
    func testReplaceCharactersWithBr2() {
        let helloText = "Hello"
        let worldText = " World!"
        let initialText = "\(helloText)\(worldText)"

        let breakAndWorldText = "\n\(worldText)"

        let textNode = TextNode(text: initialText)
        let paragraphNode = ElementNode(name: StandardElementType.p.rawValue, attributes: [], children: [textNode])

        XCTAssertEqual(paragraphNode.children.count, 1)

        let replaceRange = NSRange(location: helloText.characters.count, length: worldText.characters.count)

        textNode.replaceCharacters(inRange: replaceRange, withString: breakAndWorldText)

        XCTAssertEqual(paragraphNode.children.count, 3)

        guard let textNode1 = paragraphNode.children[0] as? TextNode else {
            XCTFail("Expected a text node.")
            return
        }

        guard let breakNode = paragraphNode.children[1] as? ElementNode,
            breakNode.name == StandardElementType.br.rawValue else {
                XCTFail("Expected a BR node.")
                return
        }

        guard let textNode2 = paragraphNode.children[2] as? TextNode else {
            XCTFail("Expected a text node.")
            return
        }

        XCTAssertEqual(textNode1.text(), helloText)
        XCTAssertEqual(textNode2.text(), worldText)
    }


    /// Tests that replacing text to a text node works fine.
    ///
    /// Initial DOM: <p>Hello World!</p>
    /// Range to replace: the range of the space between words
    /// New text for the replaced range: "\n"
    ///
    /// The results should be: <p>Hello<br>World!</p>"
    ///
    func testReplaceCharactersWithBr3() {
        let helloText = "Hello"
        let space = " "
        let worldText = "World!"
        let initialText = "\(helloText)\(space)\(worldText)"

        let breakText = "\n"

        let textNode = TextNode(text: initialText)
        let paragraphNode = ElementNode(name: StandardElementType.p.rawValue, attributes: [], children: [textNode])

        XCTAssertEqual(paragraphNode.children.count, 1)

        let replaceRange = NSRange(location: helloText.characters.count, length: space.characters.count)

        textNode.replaceCharacters(inRange: replaceRange, withString: breakText)

        XCTAssertEqual(paragraphNode.children.count, 3)

        guard let textNode1 = paragraphNode.children[0] as? TextNode else {
            XCTFail("Expected a text node.")
            return
        }

        guard let breakNode = paragraphNode.children[1] as? ElementNode,
            breakNode.name == StandardElementType.br.rawValue else {
                XCTFail("Expected a BR node.")
                return
        }

        guard let textNode2 = paragraphNode.children[2] as? TextNode else {
            XCTFail("Expected a text node.")
            return
        }

        XCTAssertEqual(textNode1.text(), helloText)
        XCTAssertEqual(textNode2.text(), worldText)
    }

    /// Tests that replacing text to a text node works fine.
    ///
    /// Initial DOM: <p>Hello World!</p>
    /// Range to replace: the range of the space between words
    /// New text for the replaced range: "\nTo My\n"
    ///
    /// The results should be: <p>Hello<br>To My<br>World!</p>"
    ///
    func testReplaceCharactersWithBr4() {
        let helloText = "Hello"
        let space = " "
        let worldText = "World!"
        let initialText = "\(helloText)\(space)\(worldText)"

        let toMyText = "To My"
        let newText = "\n\(toMyText)\n"

        let textNode = TextNode(text: initialText)
        let paragraphNode = ElementNode(name: StandardElementType.p.rawValue, attributes: [], children: [textNode])
        let rootNode = RootNode(children: [paragraphNode])
        let editor = DOMEditor(with: rootNode)

        XCTAssertEqual(paragraphNode.children.count, 1)

        let replaceRange = NSRange(location: helloText.characters.count, length: space.characters.count)

        editor.replace(replaceRange, with: newText)
        textNode.replaceCharacters(inRange: replaceRange, withString: newText)

        XCTAssertEqual(paragraphNode.children.count, 5)

        guard let textNode1 = paragraphNode.children[0] as? TextNode else {
            XCTFail("Expected a text node.")
            return
        }

        guard let breakNode1 = paragraphNode.children[1] as? ElementNode,
            breakNode1.name == StandardElementType.br.rawValue else {
                XCTFail("Expected a BR node.")
                return
        }

        guard let textNode2 = paragraphNode.children[2] as? TextNode else {
            XCTFail("Expected a text node.")
            return
        }

        guard let breakNode2 = paragraphNode.children[3] as? ElementNode,
            breakNode2.name == StandardElementType.br.rawValue else {
                XCTFail("Expected a BR node.")
                return
        }

        guard let textNode3 = paragraphNode.children[4] as? TextNode else {
            XCTFail("Expected a text node.")
            return
        }

        XCTAssertEqual(textNode1.text(), helloText)
        XCTAssertEqual(textNode2.text(), toMyText)
        XCTAssertEqual(textNode3.text(), worldText)
    }
*/

    /// Test that inserting a new line after a DIV tag doesn't crash
    /// See https://github.com/wordpress-mobile/WordPress-Aztec-iOS/issues/90
    ///
    /// Input HTML: `<div>This is a paragraph in a div</div>This is some unwrapped text`
    /// - location: the location after the div tag.
    ///
    /// Expected results:
    /// - Output: `<div>This is a paragraph in a div</div>\nThis is some unwrapped text`
    ///
    func testInsertNewlineAfterDivShouldNotCrash() {
        let text1 = "🇮🇳 Wrapped"
        let text2 = "Unwrapped"
        let divText = TextNode(text: text1)
        let div = ElementNode(name: "div", attributes: [], children: [divText])
        let unwrappedText = TextNode(text: text2)
        let rootNode = RootNode(children: [div, unwrappedText])
        let editor = DOMEditor(with: rootNode)

        let location = editor.inspector.length(of: div)

        editor.insert(String(.newline), atLocation: location)

        XCTAssertEqual(editor.inspector.text(for: rootNode), "\(text1)\(String(.paragraphSeparator))\(String(.newline))\(text2)")
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

        editor.replace(NSRange(location: 0, length: 0), with: "a")
        editor.replace(NSRange(location: 1, length: 0), with: "b")
        editor.replace(NSRange(location: 2, length: 0), with: "c")

        XCTAssertEqual(rootNode.children.count, 1)
        XCTAssert(rootNode.children[0] is TextNode)
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

        let range = NSRange(location: 14, length: 4)
        let newString = "link!"

        editor.replace(range, with: newString)

        XCTAssertEqual(rootNode.children.count, 1)

        guard let textNode = rootNode.children[0] as? TextNode else {
            XCTFail("Expected a child text node")
            return
        }

        XCTAssertEqual(editor.inspector.text(for: textNode), "\(preLinkText)\(newString)")
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

        let range = NSRange(location: 14, length: 4)
        let newString = "link!"
        let finalText = "\(text1)\(text2)!"

        editor.replace(range, with: newString)

        XCTAssertEqual(rootNode.children.count, 1)

        guard let textNode = rootNode.children[0] as? TextNode, editor.inspector.text(for: textNode) == finalText else {

            XCTFail("Expected a text node, with the full text.")
            return
        }
    }

    /// Tests `replaceCharacters(inRange:withString:)`.
    ///
    /// Input HTML: `<rootNode><p>Click on this <a href="http://www.wordpress.com">link</a></p></rootNode>`
    /// - Range: the range of the full contents of the `<a>` node.
    /// - New String: "link!"
    ///
    /// Expected results:
    /// - Output: `<div><p>Click on this link!</p></div>`
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

        let range = NSRange(location: 14, length: 4)
        let newString = "link!"
        let finalText = "\(text1)\(text2)!"

        editor.replace(range, with: newString)

        XCTAssertEqual(editor.inspector.text(for: rootNode), finalText)
        XCTAssertEqual(rootNode.children.count, 1)

        guard let outParagraph = rootNode.children[0] as? ElementNode,
            outParagraph.name == StandardElementType.p.rawValue else {
                XCTFail("Expected a paragraph node.")
                return
        }

        XCTAssertEqual(editor.inspector.text(for: outParagraph), finalText)

        guard let outTextNode = outParagraph.children[0] as? TextNode,
            editor.inspector.text(for: outTextNode) == finalText else {
                XCTFail("Expected a text node, with the full text.")
                return
        }
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

        let replaceRange = NSRange(location: text1.characters.count + space.characters.count, length: textToReplace.characters.count)
        editor.replace(replaceRange, with: "everyone")

        XCTAssertEqual(rootNode.children.count, 2)
        XCTAssertEqual(rootNode.children[0], boldNode)

        guard let textNode = rootNode.children[1] as? TextNode, editor.inspector.text(for: textNode) == textToVerify else {
            XCTFail("Expected a text node, with the full text.")
            return
        }
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

        let range = NSRange(location: startText.characters.count, length: middleText.characters.count)
        let imgSrc = "https://httpbin.org/image/jpeg"

        let elementType = StandardElementType.img
        let imgNodeName = elementType.rawValue
        let attributes = [Libxml2.StringAttribute(name:"src", value: imgSrc)]
        let element = ElementNode(name: imgNodeName, attributes: attributes, children: [])

        editor.replace(range, with: element)

        XCTAssertEqual(paragraph.children.count, 3)

        guard let startNode = paragraph.children[0] as? TextNode, editor.inspector.text(for: startNode) == startText else {
            XCTFail("Expected a text node")
            return
        }

        guard let imgNode = paragraph.children[1] as? ElementNode, imgNode.name == imgNodeName else {
            XCTFail("Expected a img node")
            return
        }

        guard let endNode = paragraph.children[2] as? TextNode, editor.inspector.text(for: endNode) == endText else {
            XCTFail("Expected a text node")
            return
        }
    }


    /// Tests `replaceCharacters(inRange:withNode)`.
    ///
    /// Input HTML: `<p>Look at this photo:image.It's amazing</p>`
    /// - Range: the range of the image string.
    /// - New Node: <img>
    /// - Attributes:
    ///
    /// Expected results:
    /// - Output: `<p>Look at this photo:<img src="https://httpbin.org/image/jpeg.It's amazing" /></p>`
    ///
    func testReplaceCharactersInRangeWithNode() {
        let startText = "Look at this photo:"
        let middleText = "image"
        let endText = ".It's amazing"
        let paragraphText = TextNode(text: startText + middleText + endText)
        let paragraph = ElementNode(name: "p", attributes: [], children: [paragraphText])
        let rootNode = RootNode(children: [paragraph])
        let editor = DOMEditor(with: rootNode)

        let range = NSRange(location: startText.characters.count, length: middleText.characters.count)
        let imgSrc = "https://httpbin.org/image/jpeg"

        let attributes = [Libxml2.StringAttribute(name: "src", value: imgSrc)]
        let descriptor = ElementNodeDescriptor(elementType: .img, attributes: attributes)
        let node = ElementNode(descriptor: descriptor)

        editor.replace(range, with: node)

        XCTAssertEqual(paragraph.children.count, 3)

        guard let startNode = paragraph.children[0] as? TextNode, editor.inspector.text(for: startNode) == startText else {

            XCTFail("Expected a text node")
            return
        }

        guard let imgNode = paragraph.children[1] as? ElementNode, imgNode.name == node.name else {

            XCTFail("Expected a img node")
            return
        }

        guard let endNode = paragraph.children[2] as? TextNode, editor.inspector.text(for: endNode) == endText else {
            
            XCTFail("Expected a text node")
            return
        }
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

        editor.wrap(editor.inspector.range(of: div), in: ElementNodeDescriptor(name: boldNodeName))

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
        XCTAssertEqual(editor.inspector.text(for: outEm), "He")

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
        XCTAssertEqual(editor.inspector.text(for: outU), "e!")

        // 3rd level nodes

        guard let outEm2 = outB.children[0] as? ElementNode else {
            XCTFail("Expected an element node.")
            return
        }

        XCTAssertEqual(outEm2.name, StandardElementType.em.rawValue)
        XCTAssertEqual(outEm2.children.count, 1)
        XCTAssert(outEm2.children[0] is TextNode)
        XCTAssertEqual(editor.inspector.text(for: outEm2), "llo ")

        guard let outU2 = outB.children[1] as? ElementNode else {
            XCTFail("Expected an element node.")
            return
        }

        XCTAssertEqual(outU2.name, StandardElementType.u.rawValue)
        XCTAssertEqual(outU2.children.count, 1)
        XCTAssert(outU2.children[0] is TextNode)
        XCTAssertEqual(editor.inspector.text(for: outU2), "ther")
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
        XCTAssertEqual(editor.inspector.text(for: boldNode), editor.inspector.text(for: newBoldNode))
    }

    // MARK: - pushUp(rightSideDescendantEvaluatedBy:)

    /// Tests that `pushUp(leftSideDescendantEvaluatedBy:)` works.
    ///
    /// Push the node named "b" up to the level of the "strike" node.
    ///
    /// Input HTML: `<p><strike><b>Hello </b>there!<strike></p>`
    /// - Evaluation criteria: node.name == "b"
    ///
    /// Expected results:
    /// - Output: `<p><b><strike>Hello </strike></b><strike>there!</strike></p>`
    ///
    func testPushUpLeftSideDescendant() {

        let text1 = TextNode(text: "Hello ")
        let text2 = TextNode(text: "there!")
        let bold = ElementNode(name: "b", attributes: [], children: [text1])
        let strike = ElementNode(name: "strike", attributes: [], children: [bold, text2])
        let paragraph = ElementNode(name: "p", attributes: [], children: [strike])
        let rootNode = RootNode(children: [paragraph])
        let editor = DOMEditor(with: rootNode)

        let result = editor.pushUp(in: strike, leftSideDescendantEvaluatedBy: { node -> Bool in
            return node.name == "b"
        })

        XCTAssertEqual(paragraph.children.count, 2)

        guard let outBold = paragraph.children[0] as? ElementNode, outBold.name == "b" else {
            XCTFail("Expected a bold node here.")
            return
        }

        XCTAssertEqual(result, outBold)
        XCTAssertEqual(editor.inspector.text(for: outBold), editor.inspector.text(for: text1))
        XCTAssertEqual(outBold.children.count, 1)

        guard let outStrike2 = outBold.children[0] as? ElementNode, outStrike2.name == "strike" else {
            XCTFail("Expected a strike node.")
            return
        }

        guard let outStrike1 = paragraph.children[1] as? ElementNode, outStrike1.name == "strike" else {
            XCTFail("Expected a strike node.")
            return
        }

        XCTAssertEqual(outStrike1.children.count, 1)
        XCTAssertEqual(outStrike1.children[0], text2)
    }
/*
    /// Tests that `pushUp(leftSideDescendantEvaluatedBy:)` works.
    ///
    /// Should find no node to push up.
    ///
    /// Input HTML: `<p><strike><b>Hello </b>there!<strike></p>`
    /// - Evaluation criteria: node.name == "b"
    ///
    /// Expected results:
    /// - No node should be returned.
    ///
    func testPushUpLeftSideDescendantWithNilResult() {

        let text = TextNode(text: "Hello there!")
        let strike = ElementNode(name: "strike", attributes: [], children: [text])
        _ = ElementNode(name: "p", attributes: [], children: [strike])

        let result = strike.pushUp(leftSideDescendantEvaluatedBy: { node -> Bool in
            return node.name == "b"
        })

        XCTAssertNil(result)
    }

    /// Tests that `pushUp(rightSideDescendantEvaluatedBy:)` works.
    ///
    /// Push the node named "b" up to the level of the "strike" node.
    ///
    /// Input HTML: `<p><strike>Hello <b>there!</b></strike></p>`
    /// - Evaluation criteria: node.name == "b"
    ///
    /// Expected results:
    /// - Output: `<p><strike>Hello </strike><b><strike>there!</strike></b></p>`
    ///
    func testPushUpRightSideDescendant() {

        let text1 = TextNode(text: "Hello ")
        let text2 = TextNode(text: "there!")
        let bold = ElementNode(name: "b", attributes: [], children: [text2])
        let strike = ElementNode(name: "strike", attributes: [], children: [text1, bold])
        let paragraph = ElementNode(name: "p", attributes: [], children: [strike])

        let _ = strike.pushUp(rightSideDescendantEvaluatedBy: { node -> Bool in
            return node.name == "b"
        })

        XCTAssertEqual(paragraph.children.count, 2)

        guard let outStrike1 = paragraph.children[0] as? ElementNode, outStrike1.name == "strike" else {
            XCTFail("Expected a strike node.")
            return
        }

        XCTAssertEqual(outStrike1.children.count, 1)
        XCTAssertEqual(outStrike1.children[0], text1)

        guard let outBold = paragraph.children[1] as? ElementNode, outBold.name == "b" else {
            XCTFail("Expected a bold node here.")
            return
        }

        XCTAssertEqual(outBold.text(), text2.text())
        XCTAssertEqual(outBold.children.count, 1)

        guard let outStrike2 = outBold.children[0] as? ElementNode, outStrike2.name == "strike" else {
            XCTFail("Expected a strike node.")
            return
        }
    }

    /// Tests that `pushUp(rightSideDescendantEvaluatedBy:)` works.
    ///
    /// Should find no node to push up.
    ///
    /// Input HTML: `<p><strike>Hello there!<strike></p>`
    /// - Evaluation criteria: node.name == "b"
    ///
    /// Expected results:
    /// - No node should be returned.
    ///
    func testPushUpRightSideDescendantWithNilResult() {

        let text = TextNode(text: "Hello there!")
        let strike = ElementNode(name: "strike", attributes: [], children: [text])
        let paragraph = ElementNode(name: "p", attributes: [], children: [strike])
        let rootNode = RootNode(children: [paragraph])
        let editor = DOMEditor(with: rootNode)

        let result = editor.pushUp(in: strike, rightSideDescendantEvaluatedBy: { node -> Bool in
            return node.name == "b"
        })

        XCTAssertNil(result)
    }
 */

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

        let splitLocation = text1.characters.count
        editor.split(paragraph, at: splitLocation)

        XCTAssertEqual(div.children.count, 2)

        guard let newParagraph1 = div.children[0] as? ElementNode, let newText1 = newParagraph1.children[0] as? TextNode else {
            XCTFail("Expected the first new paragraph to exist and be the same as the original paragraph.")
            return
        }

        guard let newParagraph2 = div.children[1] as? ElementNode, let newText2 = newParagraph2.children[0] as? TextNode else {
            XCTFail("Expected the first new paragraph to exist.")
            return
        }

        XCTAssert(editor.inspector.text(for: newText1) == text1)
        XCTAssert(editor.inspector.text(for: newText2) == text2)
    }


    /// Tests that splitting a text node at a specified text location works fine.
    ///
    /// HTML string: <p>Hello World!</p>
    /// Split Location: 5
    ///
    /// The results should be:
    ///     - After the split, the selected text node should contain: "Hello"
    ///     - A new text node should exist immediately after, containing: " World!"
    ///
    func testSplitAtLocation1() {
        let text1 = "Hello"
        let text2 = " World!"

        let textNode = TextNode(text: "\(text1)\(text2)")
        let paragraph = ElementNode(name: "p", attributes: [], children: [textNode])
        let rootNode = RootNode(children: [paragraph])
        let editor = DOMEditor(with: rootNode)

        let splitLocation = text1.characters.count

        let (left, right) = editor.split(textNode, at: splitLocation)

        XCTAssertEqual(editor.inspector.text(for: left), text1)
        XCTAssertEqual(editor.inspector.text(for: right), text2)
    }
}
