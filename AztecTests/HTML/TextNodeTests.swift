import XCTest
@testable import Aztec

class TextNodeTests: XCTestCase {
    
    typealias ElementNode = Libxml2.ElementNode
    typealias TextNode = Libxml2.TextNode
    typealias UndoClosure = Libxml2.Node.UndoClosure
    
    // MARK: - Editing text nodes
    
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

        let textNode = TextNode(text: "\(text1)\(text2)", registerUndo: { _ in })
        let paragraph = ElementNode(name: "p", attributes: [], children: [textNode], registerUndo: { _ in })
        
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
        let textNode = TextNode(text: "Hello World!", registerUndo: { _ in })
        let paragraph = ElementNode(name: "p", attributes: [], children: [textNode], registerUndo: { _ in })
        
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
        let textNode = TextNode(text: "Hello World!", registerUndo: { _ in })
        let paragraph = ElementNode(name: "p", attributes: [], children: [textNode], registerUndo: { _ in })
        
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
        var undoClosure: UndoClosure? = nil
        
        let textNode = TextNode(text: "") { anUndoClosure in
            undoClosure = anUndoClosure
        }
        
        textNode.append(textToAppend)
        XCTAssertEqual(textNode.text(), textToAppend)
        
        guard let theUndoClosure = undoClosure else {
            XCTAssertNotNil(undoClosure)
            return
        }
        
        theUndoClosure()
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
        
        var undoClosure: UndoClosure? = nil
        
        let textNode = TextNode(text: text1) { anUndoClosure in
            undoClosure = anUndoClosure
        }
        
        textNode.append(text2)
        XCTAssertEqual(textNode.text(), fullText)
        
        guard let theUndoClosure = undoClosure else {
            XCTAssertNotNil(undoClosure)
            return
        }
        
        theUndoClosure()
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
        
        var undoClosure: UndoClosure? = nil
        
        let textNode = TextNode(text: fullText) { anUndoClosure in
            undoClosure = anUndoClosure
        }
        
        textNode.deleteCharacters(inRange: range)
        XCTAssertEqual(textNode.text(), text2)
        
        guard let theUndoClosure = undoClosure else {
            XCTAssertNotNil(undoClosure)
            return
        }
        
        theUndoClosure()
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
        
        var undoClosure: UndoClosure? = nil
        
        let textNode = TextNode(text: fullText) { anUndoClosure in
            undoClosure = anUndoClosure
        }
        
        textNode.deleteCharacters(inRange: range)
        XCTAssertEqual(textNode.text(), text1)
        
        guard let theUndoClosure = undoClosure else {
            XCTAssertNotNil(undoClosure)
            return
        }
        
        theUndoClosure()
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
        var undoClosure: UndoClosure? = nil
        
        let textNode = TextNode(text: "") { anUndoClosure in
            undoClosure = anUndoClosure
        }
        
        textNode.prepend(textToPrepend)
        XCTAssertEqual(textNode.text(), textToPrepend)
        
        guard let theUndoClosure = undoClosure else {
            XCTAssertNotNil(undoClosure)
            return
        }
        
        theUndoClosure()
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
        
        var undoClosure: UndoClosure? = nil
        
        let textNode = TextNode(text: text1) { anUndoClosure in
            undoClosure = anUndoClosure
        }
        
        textNode.prepend(text2)
        XCTAssertEqual(textNode.text(), fullText)
        
        guard let theUndoClosure = undoClosure else {
            XCTAssertNotNil(undoClosure)
            return
        }
        
        theUndoClosure()
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
        
        var undoClosure: UndoClosure? = nil
        
        let textNode = TextNode(text: fullText) { anUndoClosure in
            undoClosure = anUndoClosure
        }
        
        textNode.replaceCharacters(inRange: range, withString: newText, inheritStyle: false)
        XCTAssertEqual(textNode.text(), newFullText)
        
        guard let theUndoClosure = undoClosure else {
            XCTAssertNotNil(undoClosure)
            return
        }
        
        theUndoClosure()
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
        
        var undoClosure: UndoClosure? = nil
        
        let textNode = TextNode(text: fullText) { anUndoClosure in
            undoClosure = anUndoClosure
        }
        
        textNode.replaceCharacters(inRange: range, withString: newText, inheritStyle: false)
        XCTAssertEqual(textNode.text(), newFullText)
        
        guard let theUndoClosure = undoClosure else {
            XCTAssertNotNil(undoClosure)
            return
        }
        
        theUndoClosure()
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
        
        var undoClosure: UndoClosure? = nil
        
        let textNode = TextNode(text: fullText) { anUndoClosure in
            undoClosure = anUndoClosure
        }
        
        textNode.replaceCharacters(inRange: range, withString: newText, inheritStyle: false)
        XCTAssertEqual(textNode.text(), newFullText)
        
        guard let theUndoClosure = undoClosure else {
            XCTAssertNotNil(undoClosure)
            return
        }
        
        theUndoClosure()
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
        
        var undoClosure: UndoClosure? = nil
        
        let textNode = TextNode(text: fullText) { anUndoClosure in
            undoClosure = anUndoClosure
        }
        
        textNode.replaceCharacters(inRange: range, withString: newText, inheritStyle: false)
        XCTAssertEqual(textNode.text(), newText)
        
        guard let theUndoClosure = undoClosure else {
            XCTAssertNotNil(undoClosure)
            return
        }
        
        theUndoClosure()
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
        
        var undoClosure: UndoClosure? = nil
        
        let textNode = TextNode(text: fullText) { anUndoClosure in
            undoClosure = anUndoClosure
        }
        
        textNode.replaceCharacters(inRange: range, withString: newText, inheritStyle: false)
        XCTAssertEqual(textNode.text(), newText)
        
        guard let theUndoClosure = undoClosure else {
            XCTAssertNotNil(undoClosure)
            return
        }
        
        theUndoClosure()
        XCTAssertEqual(textNode.text(), fullText)
    }
}
