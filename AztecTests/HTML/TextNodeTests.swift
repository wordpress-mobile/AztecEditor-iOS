import XCTest
@testable import Aztec

class TextNodeTests: XCTestCase {
    
    typealias ElementNode = Libxml2.ElementNode
    typealias TextNode = Libxml2.TextNode
    
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
}
