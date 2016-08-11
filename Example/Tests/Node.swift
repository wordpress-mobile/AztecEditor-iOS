import XCTest
@testable import Aztec

class NodeTests: XCTestCase {

    typealias ElementNode = Libxml2.HTML.ElementNode
    typealias Node = Libxml2.HTML.Node
    typealias TextNode = Libxml2.HTML.TextNode

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testParentNodeInCommon1() {

        let text1 = TextNode(text: "text1 goes here")
        let text2 = TextNode(text: "text2 goes here.")
        let text3 = TextNode(text: "text3 goes here..")

        let mainNode = ElementNode(name: "p", attributes: [], children: [text1, text2, text3])

        XCTAssertEqual(mainNode, text1.parentNodeInCommon(withNode: text2))
        XCTAssertEqual(mainNode, text2.parentNodeInCommon(withNode: text3))
        XCTAssertEqual(mainNode, text3.parentNodeInCommon(withNode: text1))
    }

    func testParentNodeInCommon2() {

        let text1 = TextNode(text: "text1 goes here")
        let text2 = TextNode(text: "text2 goes here.")

        let element1 = ElementNode(name: "p", attributes: [], children: [text1])
        let element2 = ElementNode(name: "p", attributes: [], children: [text2])
        let element3 = ElementNode(name: "p", attributes: [], children: [element1, element2])

        XCTAssertEqual(text1.parentNodeInCommon(withNode: text2), element3)
    }

    func testParentNodeInCommonWithNoParentNodesInCommon() {

        let text1 = TextNode(text: "text1 goes here")
        let text2 = TextNode(text: "text2 goes here.")

        let _ = ElementNode(name: "p", attributes: [], children: [text1])

        XCTAssertEqual(text1.parentNodeInCommon(withNode: text2), nil)
    }

    func testParentNodeInCommonWithInterruption() {

        let text1 = TextNode(text: "text1 goes here")
        let text2 = TextNode(text: "text2 goes here.")

        let element1 = ElementNode(name: "p", attributes: [], children: [text1])
        let element2 = ElementNode(name: "p", attributes: [], children: [text2])
        let _ = ElementNode(name: "p", attributes: [], children: [element1, element2])

        XCTAssertEqual(text1.parentNodeInCommon(withNode: text2, interruptAtBlockLevel: true), nil)
    }
    
}
