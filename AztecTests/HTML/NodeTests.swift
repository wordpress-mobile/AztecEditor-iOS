import XCTest
@testable import Aztec

class NodeTests: XCTestCase {

    typealias Attribute = Libxml2.Attribute
    typealias ElementNode = Libxml2.ElementNode
    typealias Node = Libxml2.Node
    typealias TextNode = Libxml2.TextNode
    typealias StandardElementType = Libxml2.StandardElementType
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // MARK: - Tests

    func testFirstElementNodeInCommonNotFound() {

        let text1 = TextNode(text: "text1 goes here")
        let text2 = TextNode(text: "text2 goes here.")

        let _ = ElementNode(name: "p", attributes: [], children: [text1])

        XCTAssertEqual(text1.firstElementNodeInCommon(withNode: text2), nil)
    }

    func testFirstElementNodeInCommonWithUpToBlockLevel() {

        let text1 = TextNode(text: "text1 goes here")
        let text2 = TextNode(text: "text2 goes here.")

        let element1 = ElementNode(name: "p", attributes: [], children: [text1])
        let element2 = ElementNode(name: "p", attributes: [], children: [text2])
        let _ = ElementNode(name: "p", attributes: [], children: [element1, element2])

        XCTAssertEqual(text1.firstElementNodeInCommon(withNode: text2, interruptAtBlockLevel: true), nil)
    }
    
    // MARK: - Undo support
    
    func testThatParentChangesAreUndoable() {
        
        let undoManager = UndoManager()
        
        undoManager.disableUndoRegistration()
        
        let textNode = TextNode(text: "Hello")
        let elementNode = ElementNode(name: StandardElementType.b.rawValue, attributes: [], children: [textNode])
        
        undoManager.enableUndoRegistration()
        
        XCTAssertEqual(textNode.parent, elementNode)
        
        textNode.removeFromParent()
        XCTAssertNil(textNode.parent)
        
        undoManager.undo()
        XCTAssertEqual(textNode.parent, elementNode)
    }
}
