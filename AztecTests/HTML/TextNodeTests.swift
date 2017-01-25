import XCTest
@testable import Aztec

class TextNodeTests: XCTestCase {
    
    typealias EditContext = Libxml2.EditContext
    typealias ElementNode = Libxml2.ElementNode
    typealias StandardElementType = Libxml2.StandardElementType
    typealias TextNode = Libxml2.TextNode
    
    // MARK: - Editing text nodes
    
    /// Tests that appending text to a text node works fine.
    ///
    /// HTML string: <p>Hello World!</p>
    /// Text to append: "Hello There! "
    ///
    /// The results should be: "Hello World! Hello There!"
    ///
    func testAppend() {
        let textInNode = "Hello World!"
        let textToAppend = " Hello There!"
        let fullText = "\(textInNode)\(textToAppend)"
        
        let textNode = TextNode(text: textInNode)
        let paragraphNode = ElementNode(name: StandardElementType.p.rawValue, attributes: [], children: [textNode])
        
        textNode.append(textToAppend)
        
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
        
        XCTAssertEqual(paragraphNode.children.count, 1)

        textNode.append(textToAppendWithBR)
        
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
        
        XCTAssertEqual(paragraphNode.children.count, 1)
        
        textNode.append(fullTextToAppend)
        
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
        
        XCTAssertEqual(paragraphNode.children.count, 1)
        
        textNode.append(textToAppend)
        
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
        
        let splitLocation = text1.characters.count
        
        textNode.split(atLocation: splitLocation)
        
        XCTAssertEqual(paragraph.children.count, 2)
        
        guard let newTextNode1 = paragraph.children[0] as? TextNode, newTextNode1.text() == text1 else {
                XCTFail("Expected a text node here.")
                return
        }
        
        guard let newTextNode2 = paragraph.children[1] as? TextNode, newTextNode2.text() == text2 else {
                XCTFail("Expected a text node here.")
                return
        }
    }
    
    
    /// Tests that splitting a text node at a specified text location works fine.
    ///
    /// HTML string: <p>Hello World!</p>
    /// Split Location: 0
    ///
    /// The results should be:
    ///     - No splitting should occur, the selected text node should match the whole string.
    ///
    func testSplitAtLocation2() {
        let textNode = TextNode(text: "Hello World!")
        let paragraph = ElementNode(name: "p", attributes: [], children: [textNode])
        
        let splitLocation = 0
        
        textNode.split(atLocation: splitLocation)
        
        XCTAssertEqual(paragraph.children.count, 1)
        XCTAssertEqual(paragraph.children[0], textNode)
    }
    
    /// Tests that splitting a text node at a specified text location works fine.
    ///
    /// HTML string: <p>Hello World!</p>
    /// Split Location: full string length
    ///
    /// The results should be:
    ///     - No splitting should occur, the selected text node should match the whole string.
    ///
    func testSplitAtLocation3() {
        let textNode = TextNode(text: "Hello World!")
        let paragraph = ElementNode(name: "p", attributes: [], children: [textNode])
        
        let splitLocation = textNode.length()
        
        textNode.split(atLocation: splitLocation)
        
        XCTAssertEqual(paragraph.children.count, 1)
        XCTAssertEqual(paragraph.children[0], textNode)
    }
    
    // MARK: - Undo support
    
    /// Tests that appending text to a node, can be undone.
    ///
    /// Inputs:
    ///     - Text node contents: ""
    ///     - Text to append: "Hello there!"
    ///
    /// Verifications:
    ///     - Check that the undo event is properly registered.
    ///     - Check that after editing the text node, its content is: "Hello there!."
    ///     - Check that after undoing the text node edit, its content is: ""
    /// 
    func testThatAppendIsUndoable1() {
        
        let textToAppend = "Hello there!"
        
        let undoManager = UndoManager()
        let editContext = EditContext(undoManager: undoManager)
        let textNode = TextNode(text: "", editContext: editContext)
        
        textNode.append(textToAppend)
        XCTAssertEqual(textNode.text(), textToAppend)
        
        undoManager.undo()
        XCTAssertEqual(textNode.text(), "")
    }
    
    /// Tests that appending text to a node, can be undone.
    ///
    /// Inputs:
    ///     - Text node contents: "Hello"
    ///     - Text to append: " there!."
    ///
    /// Verifications:
    ///     - Check that the undo event is properly registered.
    ///     - Check that after editing the text node, its content is: "Hello there!."
    ///     - Check that after undoing the text node edit, its content is: ""
    ///
    func testThatAppendIsUndoable2() {
        let text1 = "Hello"
        let text2 = " there!"
        let fullText = "\(text1)\(text2)"
        
        let undoManager = UndoManager()
        let editContext = EditContext(undoManager: undoManager)
        
        let textNode = TextNode(text: text1, editContext: editContext)
        
        textNode.append(text2)
        XCTAssertEqual(textNode.text(), fullText)
        
        undoManager.undo()
        XCTAssertEqual(textNode.text(), text1)
    }
    
    /// Tests that `deleteCharacters(inRange:)` is undoable.
    ///
    /// Inputs:
    ///     - Original node contents: "Hello there!"
    ///     - Range: (loc: 0, len: 5)
    ///
    /// Verifications:
    ///     - Check that the undo event is properly registered.
    ///     - Check that after editing the text node, its content is: " there!"
    ///     - Check that after undoing the text node edit, its content is: "Hello there!"
    ///
    func testThatDeleteCharactersIsUndoable1() {
        let text1 = "Hello"
        let text2 = " there!"
        let fullText = "\(text1)\(text2)"
        let range = NSRange(location: 0, length: text1.characters.count)
        
        let undoManager = UndoManager()
        let editContext = EditContext(undoManager: undoManager)
        
        let textNode = TextNode(text: fullText, editContext: editContext)
        
        textNode.deleteCharacters(inRange: range)
        XCTAssertEqual(textNode.text(), text2)
        
        undoManager.undo()
        XCTAssertEqual(textNode.text(), fullText)
    }
    
    /// Tests that `deleteCharacters(inRange:)` is undoable.
    ///
    /// Inputs:
    ///     - Original node contents: "Hello there!"
    ///     - Range: (loc: 5, len: 7)
    ///
    /// Verifications:
    ///     - Check that the undo event is properly registered.
    ///     - Check that after editing the text node, its content is: "Hello"
    ///     - Check that after undoing the text node edit, its content is: "Hello there!"
    ///
    func testThatDeleteCharactersIsUndoable2() {
        let text1 = "Hello"
        let text2 = " there!"
        let fullText = "\(text1)\(text2)"
        let range = NSRange(location: text1.characters.count, length: text2.characters.count)
        
        let undoManager = UndoManager()
        let editContext = EditContext(undoManager: undoManager)
        
        let textNode = TextNode(text: fullText, editContext: editContext)
        
        textNode.deleteCharacters(inRange: range)
        XCTAssertEqual(textNode.text(), text1)
        
        undoManager.undo()
        XCTAssertEqual(textNode.text(), fullText)
    }
    
    /// Tests that `prepend()` in undoable.
    ///
    /// Inputs:
    ///     - Text node contents: ""
    ///     - Text to prepend: "Hello there!"
    ///
    /// Verifications:
    ///     - Check that the undo event is properly registered.
    ///     - Check that after editing the text node, its content is: "Hello there!."
    ///     - Check that after undoing the text node edit, its content is: ""
    ///
    func testThatPrependIsUndoable1() {
        
        let textToPrepend = "Hello there!"
        
        let undoManager = UndoManager()
        let editContext = EditContext(undoManager: undoManager)
        
        let textNode = TextNode(text: "", editContext: editContext)
        
        textNode.prepend(textToPrepend)
        XCTAssertEqual(textNode.text(), textToPrepend)
        
        undoManager.undo()
        XCTAssertEqual(textNode.text(), "")
    }
    
    
    /// Tests that `prepend()` in undoable.
    ///
    /// Inputs:
    ///     - Text node contents: " there!."
    ///     - Text to prepend: "Hello"
    ///
    /// Verifications:
    ///     - Check that the undo event is properly registered.
    ///     - Check that after editing the text node, its content is: "Hello there!."
    ///     - Check that after undoing the text node edit, its content is: ""
    ///
    func testThatPrependIsUndoable2() {
        let text1 = " there!"
        let text2 = "Hello"
        let fullText = "\(text2)\(text1)"
        
        let undoManager = UndoManager()
        let editContext = EditContext(undoManager: undoManager)
        
        let textNode = TextNode(text: text1, editContext: editContext)
        
        textNode.prepend(text2)
        XCTAssertEqual(textNode.text(), fullText)
        
        undoManager.undo()
        XCTAssertEqual(textNode.text(), text1)
    }
    
    /// Tests that `replaceCharacters(inRange:withString:inheritStyle:)` is undoable.
    ///
    /// Inputs:
    ///     - Original node contents: "Hello there!"
    ///     - Range: (loc: 5, len: 1)
    ///     - New string: "-"
    ///
    /// Verifications:
    ///     - Check that the undo event is properly registered.
    ///     - Check that after editing the text node, its content is: "Hello-there!"
    ///     - Check that after undoing the text node edit, its content is: "Hello there!"
    ///
    func testThatReplaceCharactersIsUndoable1() {
        let text1 = "Hello"
        let text2 = " "
        let text3 = "there!"
        
        let fullText = "\(text1)\(text2)\(text3)"
        let range = NSRange(location: 5, length: 1)
        
        let newText = "-"
        let newFullText = "\(text1)\(newText)\(text3)"
        
        let undoManager = UndoManager()
        let editContext = EditContext(undoManager: undoManager)
        
        let textNode = TextNode(text: fullText, editContext: editContext)
        
        textNode.replaceCharacters(inRange: range, withString: newText, inheritStyle: false)
        XCTAssertEqual(textNode.text(), newFullText)
        
        undoManager.undo()
        XCTAssertEqual(textNode.text(), fullText)
    }
    
    /// Tests that `replaceCharacters(inRange:withString:inheritStyle:)` is undoable.
    ///
    /// Inputs:
    ///     - Original node contents: "Hello there!"
    ///     - Range: (loc: 0, len: 5)
    ///     - New string: "-"
    ///
    /// Verifications:
    ///     - Check that the undo event is properly registered.
    ///     - Check that after editing the text node, its content is: "- there!"
    ///     - Check that after undoing the text node edit, its content is: "Hello there!"
    ///
    func testThatReplaceCharactersIsUndoable2() {
        let text1 = "Hello"
        let text2 = " "
        let text3 = "there!"
        
        let fullText = "\(text1)\(text2)\(text3)"
        let range = NSRange(location: 0, length: 5)
        
        let newText = "-"
        let newFullText = "\(newText)\(text2)\(text3)"
        
        let undoManager = UndoManager()
        let editContext = EditContext(undoManager: undoManager)
        
        let textNode = TextNode(text: fullText, editContext: editContext)
        
        textNode.replaceCharacters(inRange: range, withString: newText, inheritStyle: false)
        XCTAssertEqual(textNode.text(), newFullText)
        
        undoManager.undo()
        XCTAssertEqual(textNode.text(), fullText)
    }
    
    /// Tests that `replaceCharacters(inRange:withString:inheritStyle:)` is undoable.
    ///
    /// Inputs:
    ///     - Original node contents: "Hello there!"
    ///     - Range: (loc: 6, len: 6)
    ///     - New string: "-"
    ///
    /// Verifications:
    ///     - Check that the undo event is properly registered.
    ///     - Check that after editing the text node, its content is: "Hello -"
    ///     - Check that after undoing the text node edit, its content is: "Hello there!"
    ///
    func testThatReplaceCharactersIsUndoable3() {
        let text1 = "Hello"
        let text2 = " "
        let text3 = "there!"
        
        let fullText = "\(text1)\(text2)\(text3)"
        let range = NSRange(location: 6, length: 6)
        
        let newText = "-"
        let newFullText = "\(text1)\(text2)\(newText)"
        
        let undoManager = UndoManager()
        let editContext = EditContext(undoManager: undoManager)
        
        let textNode = TextNode(text: fullText, editContext: editContext)
        
        textNode.replaceCharacters(inRange: range, withString: newText, inheritStyle: false)
        XCTAssertEqual(textNode.text(), newFullText)
        
        undoManager.undo()
        XCTAssertEqual(textNode.text(), fullText)
    }
    
    /// Tests that `replaceCharacters(inRange:withString:inheritStyle:)` is undoable.
    ///
    /// Inputs:
    ///     - Original node contents: "Hello there!"
    ///     - Range: (loc: 0, len: 12)
    ///     - New string: "-"
    ///
    /// Verifications:
    ///     - Check that the undo event is properly registered.
    ///     - Check that after editing the text node, its content is: "-"
    ///     - Check that after undoing the text node edit, its content is: "Hello there!"
    ///
    func testThatReplaceCharactersIsUndoable4() {
        let text1 = "Hello"
        let text2 = " "
        let text3 = "there!"
        
        let fullText = "\(text1)\(text2)\(text3)"
        let range = NSRange(location: 0, length: 12)
        
        let newText = "-"
        
        let undoManager = UndoManager()
        let editContext = EditContext(undoManager: undoManager)
        
        let textNode = TextNode(text: fullText, editContext: editContext)
        
        textNode.replaceCharacters(inRange: range, withString: newText, inheritStyle: false)
        XCTAssertEqual(textNode.text(), newText)
        
        undoManager.undo()
        XCTAssertEqual(textNode.text(), fullText)
    }
    
    /// Tests that `replaceCharacters(inRange:withString:inheritStyle:)` is undoable.
    ///
    /// Inputs:
    ///     - Original node contents: "Hello there!"
    ///     - Range: (loc: 0, len: 12)
    ///     - New string: ""
    ///
    /// Verifications:
    ///     - Check that the undo event is properly registered.
    ///     - Check that after editing the text node, its content is: ""
    ///     - Check that after undoing the text node edit, its content is: "Hello there!"
    ///
    func testThatReplaceCharactersIsUndoable5() {
        let text1 = "Hello"
        let text2 = " "
        let text3 = "there!"
        
        let fullText = "\(text1)\(text2)\(text3)"
        let range = NSRange(location: 0, length: 12)
        
        let newText = ""
        
        let undoManager = UndoManager()
        let editContext = EditContext(undoManager: undoManager)
        
        let textNode = TextNode(text: fullText, editContext: editContext)
        
        textNode.replaceCharacters(inRange: range, withString: newText, inheritStyle: false)
        XCTAssertEqual(textNode.text(), newText)
        
        undoManager.undo()
        XCTAssertEqual(textNode.text(), fullText)
    }
}
