import XCTest
@testable import Aztec

class ElementNodeTests: XCTestCase {

    typealias Attribute = Libxml2.Attribute
    typealias ElementNode = Libxml2.ElementNode
    typealias ElementNodeDescriptor = Libxml2.ElementNodeDescriptor
    typealias RootNode = Libxml2.RootNode
    typealias StandardElementType = Libxml2.StandardElementType
    typealias StringAttribute = Libxml2.StringAttribute
    typealias TextNode = Libxml2.TextNode

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // MARK: - Undo Support
    /*
    /// Test that removing a child can be undone perfectly.
    ///
    /// Input:
    /// - HTML: `<p>Hello <b>world!</b></p>`
    /// - Child to remove: the bold tag
    ///
    /// Expected results:
    /// - After undoing the operation, the whole DOM shoud be back to normal.
    ///
    func testUndoRemoveChild() {
        
        let undoManager = UndoManager()
        
        undoManager.disableUndoRegistration()
        
        let textNode1 = TextNode(text: "Hello ")
        let textNode2 = TextNode(text: "world!")
        let boldNode = ElementNode(name: StandardElementType.b.rawValue, attributes: [], children: [textNode2])
        let paragraph = ElementNode(name: StandardElementType.p.rawValue, attributes: [], children: [textNode1, boldNode])
        
        undoManager.enableUndoRegistration()
        
        XCTAssertEqual(paragraph.children.count, 2)
        XCTAssertEqual(paragraph.children[0], textNode1)
        XCTAssertEqual(paragraph.children[1], boldNode)
        XCTAssertEqual(textNode1.parent, paragraph)
        XCTAssertEqual(boldNode.parent, paragraph)
        
        paragraph.remove(boldNode)
        
        XCTAssertEqual(paragraph.children.count, 1)
        XCTAssertEqual(paragraph.children[0], textNode1)
        XCTAssertEqual(textNode1.parent, paragraph)
        XCTAssertNil(boldNode.parent)
        
        undoManager.undo()
        
        XCTAssertEqual(paragraph.children.count, 2)
        XCTAssertEqual(paragraph.children[0], textNode1)
        XCTAssertEqual(paragraph.children[1], boldNode)
        XCTAssertEqual(textNode1.parent, paragraph)
        XCTAssertEqual(boldNode.parent, paragraph)
    }
    
    
    /// Test that removing a children can be undone perfectly.
    ///
    /// Input:
    /// - HTML: `<p>Hello <b>world!</b><em>How are you?</em></p>`
    /// - Children to remove: the bold and em tags
    ///
    /// Expected results:
    /// - After undoing the operation, the whole DOM shoud be back to normal.
    ///
    func testUndoRemoveChildren() {
        
        let undoManager = UndoManager()
        
        undoManager.disableUndoRegistration()
        
        let textNode1 = TextNode(text: "Hello ")
        let textNode2 = TextNode(text: "world!")
        let textNode3 = TextNode(text: "How are you?")
        let boldNode = ElementNode(name: StandardElementType.b.rawValue, attributes: [], children: [textNode2])
        let emNode = ElementNode(name: StandardElementType.em.rawValue, attributes: [], children: [textNode3])
        let paragraph = ElementNode(name: StandardElementType.p.rawValue, attributes: [], children: [textNode1, boldNode, emNode])
        
        undoManager.enableUndoRegistration()
        
        XCTAssertEqual(paragraph.children.count, 3)
        XCTAssertEqual(paragraph.children[0], textNode1)
        XCTAssertEqual(paragraph.children[1], boldNode)
        XCTAssertEqual(paragraph.children[2], emNode)
        XCTAssertEqual(textNode1.parent, paragraph)
        XCTAssertEqual(boldNode.parent, paragraph)
        XCTAssertEqual(emNode.parent, paragraph)
        
        paragraph.remove([boldNode, emNode])
        
        XCTAssertEqual(paragraph.children.count, 1)
        XCTAssertEqual(paragraph.children[0], textNode1)
        XCTAssertEqual(textNode1.parent, paragraph)
        XCTAssertNil(boldNode.parent)
        XCTAssertNil(emNode.parent)
        
        undoManager.undo()
        
        XCTAssertEqual(paragraph.children.count, 3)
        XCTAssertEqual(paragraph.children[0], textNode1)
        XCTAssertEqual(paragraph.children[1], boldNode)
        XCTAssertEqual(paragraph.children[2], emNode)
        XCTAssertEqual(textNode1.parent, paragraph)
        XCTAssertEqual(boldNode.parent, paragraph)
        XCTAssertEqual(emNode.parent, paragraph)
    }
 */
}
