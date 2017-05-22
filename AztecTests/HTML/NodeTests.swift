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

    // MARK: - Undo support
    
    func testThatParentChangesAreUndoable() {
        /*
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
 */
    }
}
