import XCTest
@testable import Aztec

class NodeTests: XCTestCase {

    typealias Attribute = Libxml2.Attribute
    typealias ElementNode = Libxml2.ElementNode
    typealias Node = Libxml2.Node
    typealias TextNode = Libxml2.TextNode
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // MARK: - Tests

    func testElementNodesToRoot() {
        
        let text = TextNode(text: "text1 goes here", registerUndo: { _ in })

        let node1 = ElementNode(name: "p", attributes: [], children: [text], registerUndo: { _ in })
        let node2 = ElementNode(name: "p", attributes: [], children: [node1], registerUndo: { _ in })
        let node3 = ElementNode(name: "p", attributes: [], children: [node2], registerUndo: { _ in })

        let parentNodes = text.elementNodesToRoot()

        XCTAssertEqual(parentNodes[0], node1)
        XCTAssertEqual(parentNodes[1], node2)
        XCTAssertEqual(parentNodes[2], node3)
    }

    func testFirstElementNodeInCommon1() {

        let text1 = TextNode(text: "text1 goes here", registerUndo: { _ in })
        let text2 = TextNode(text: "text2 goes here.", registerUndo: { _ in })
        let text3 = TextNode(text: "text3 goes here..", registerUndo: { _ in })

        let mainNode = ElementNode(name: "p", attributes: [], children: [text1, text2, text3], registerUndo: { _ in })

        XCTAssertEqual(mainNode, text1.firstElementNodeInCommon(withNode: text2))
        XCTAssertEqual(mainNode, text2.firstElementNodeInCommon(withNode: text3))
        XCTAssertEqual(mainNode, text3.firstElementNodeInCommon(withNode: text1))
    }

    func testFirstElementNodeInCommon2() {

        let text1 = TextNode(text: "text1 goes here", registerUndo: { _ in })
        let text2 = TextNode(text: "text2 goes here.", registerUndo: { _ in })

        let element1 = ElementNode(name: "p", attributes: [], children: [text1], registerUndo: { _ in })
        let element2 = ElementNode(name: "p", attributes: [], children: [text2], registerUndo: { _ in })
        let element3 = ElementNode(name: "p", attributes: [], children: [element1, element2], registerUndo: { _ in })

        XCTAssertEqual(text1.firstElementNodeInCommon(withNode: text2), element3)
    }

    func testFirstElementNodeInCommonNotFound() {

        let text1 = TextNode(text: "text1 goes here", registerUndo: { _ in })
        let text2 = TextNode(text: "text2 goes here.", registerUndo: { _ in })

        let _ = ElementNode(name: "p", attributes: [], children: [text1], registerUndo: { _ in })

        XCTAssertEqual(text1.firstElementNodeInCommon(withNode: text2), nil)
    }

    func testFirstElementNodeInCommonWithUpToBlockLevel() {

        let text1 = TextNode(text: "text1 goes here", registerUndo: { _ in })
        let text2 = TextNode(text: "text2 goes here.", registerUndo: { _ in })

        let element1 = ElementNode(name: "p", attributes: [], children: [text1], registerUndo: { _ in })
        let element2 = ElementNode(name: "p", attributes: [], children: [text2], registerUndo: { _ in })
        let _ = ElementNode(name: "p", attributes: [], children: [element1, element2], registerUndo: { _ in })

        XCTAssertEqual(text1.firstElementNodeInCommon(withNode: text2, interruptAtBlockLevel: true), nil)
    }
    
}
