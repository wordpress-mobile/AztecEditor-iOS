import XCTest
@testable import Aztec

class TextNodeTests: XCTestCase {
    
    typealias ElementNode = Libxml2.ElementNode
    typealias StandardElementType = Libxml2.StandardElementType
    typealias TextNode = Libxml2.TextNode
    
    // MARK: - Undo support
    /*
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
        let textNode = TextNode(text: "")
        
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
        
        let textNode = TextNode(text: text1)
        
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
        
        let textNode = TextNode(text: fullText)
        
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
        
        let textNode = TextNode(text: fullText)
        
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
        
        let textNode = TextNode(text: "")
        
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
        
        let textNode = TextNode(text: text1)
        
        textNode.prepend(text2)
        XCTAssertEqual(textNode.text(), fullText)
        
        undoManager.undo()
        XCTAssertEqual(textNode.text(), text1)
    }
    
    /// Tests that `replaceCharacters(inRange:withString:)` is undoable.
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
        
        let textNode = TextNode(text: fullText)
        
        textNode.replaceCharacters(inRange: range, withString: newText)
        XCTAssertEqual(textNode.text(), newFullText)
        
        undoManager.undo()
        XCTAssertEqual(textNode.text(), fullText)
    }
    
    /// Tests that `replaceCharacters(inRange:withString:)` is undoable.
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
        
        let textNode = TextNode(text: fullText)
        
        textNode.replaceCharacters(inRange: range, withString: newText)
        XCTAssertEqual(textNode.text(), newFullText)
        
        undoManager.undo()
        XCTAssertEqual(textNode.text(), fullText)
    }
    
    /// Tests that `replaceCharacters(inRange:withString:)` is undoable.
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
        
        let textNode = TextNode(text: fullText)
        
        textNode.replaceCharacters(inRange: range, withString: newText)
        XCTAssertEqual(textNode.text(), newFullText)
        
        undoManager.undo()
        XCTAssertEqual(textNode.text(), fullText)
    }
    
    /// Tests that `replaceCharacters(inRange:withString:)` is undoable.
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
        
        let textNode = TextNode(text: fullText)
        
        textNode.replaceCharacters(inRange: range, withString: newText)
        XCTAssertEqual(textNode.text(), newText)
        
        undoManager.undo()
        XCTAssertEqual(textNode.text(), fullText)
    }
    
    /// Tests that `replaceCharacters(inRange:withString:)` is undoable.
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
        
        let textNode = TextNode(text: fullText)
        
        textNode.replaceCharacters(inRange: range, withString: newText)
        XCTAssertEqual(textNode.text(), newText)
        
        undoManager.undo()
        XCTAssertEqual(textNode.text(), fullText)
    }*/
}
