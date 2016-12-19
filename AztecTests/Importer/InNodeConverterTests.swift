import XCTest
@testable import Aztec
import libxml2

class InNodeConverterTests: XCTestCase {

    typealias ElementNode = Libxml2.ElementNode
    typealias Node = Libxml2.Node
    typealias TextNode = Libxml2.TextNode

    let textNodeName = "text"

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    /// Tests a simple xmlNode to HTML.TextNode conversion
    ///
    func testSimpleNodeConversion() {

        let nodeName = "DaNode!"
        
        guard let node = xmlNewNode(nil, nodeName) else {
            XCTFail("Failed to create the node.")
            return
        }
        
        let outNode = Libxml2.In.NodeConverter(registerUndo: { _ in }).convert(node.pointee)
        xmlFreeNode(node)

        guard let elementNode = outNode as? ElementNode else {
            XCTFail("Expected an element node")
            return
        }

        XCTAssertEqual(elementNode.name, nodeName)
        XCTAssertEqual(elementNode.parent, nil)
        XCTAssertEqual(elementNode.attributes.count, 0)
        XCTAssertEqual(elementNode.children.count, 0)
    }

    /// Tests a simple xmlNode to HTML.TextNode conversion
    ///
    func testSimpleTextNodeConversion() {

        let text = "DaText!"
        
        guard let node = xmlNewText(text) else {
            XCTFail("Failed to create the node.")
            return
        }
        
        let converter = Libxml2.In.NodeConverter(registerUndo: { _ in })
        let outNode = converter.convert(node.pointee)
        xmlFreeNode(node)

        guard let textNode = outNode as? TextNode else {
            XCTFail("Expected a text node")
            return
        }

        XCTAssertEqual(textNode.name, textNodeName)
        XCTAssertEqual(textNode.text(), text)
        XCTAssertEqual(textNode.parent, nil)
    }

    func testTextNodeInParentNodeConversion() {

        let text = "DaText!"
        let childNode = xmlNewText(text)

        let parentNodeName = "DaNode!"
        
        guard let parentNode = xmlNewNode(nil, parentNodeName) else {
            XCTFail("Failed to create the node.")
            return
        }

        xmlAddChild(parentNode, childNode)

        let converter = Libxml2.In.NodeConverter(registerUndo: { _ in })
        let outParentNode = converter.convert(parentNode.pointee)

        xmlFreeNode(parentNode) // frees all children

        guard let outElementNode = outParentNode as? ElementNode else {
            XCTFail("Expected an element node")
            return
        }

        XCTAssertEqual(outElementNode.name, parentNodeName)
        XCTAssertEqual(outElementNode.parent, nil)
        XCTAssertEqual(outElementNode.attributes.count, 0)
        XCTAssertEqual(outElementNode.children.count, 1)

        guard let outTextNode = outElementNode.children[0] as? TextNode else {
            XCTFail("Expected a text node")
            return
        }

        XCTAssertEqual(outTextNode.name, textNodeName)
        XCTAssertEqual(outTextNode.text(), text)
        XCTAssertEqual(outTextNode.parent, outParentNode)
    }
}
