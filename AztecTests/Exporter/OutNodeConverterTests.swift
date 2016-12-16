import XCTest
@testable import Aztec
import libxml2

class OutNodeConverterTests: XCTestCase {

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

    /// Tests a simple HTML.TextNode to xmlNode conversion
    ///
    func testSimpleTextNodeConversion() {

        let nodeName = "text"
        let nodeText = "This is the text."
        let textNode = TextNode(text: nodeText, registerUndo: { _ in })
        let xmlNodePtr = Libxml2.Out.NodeConverter().convert(textNode)
        let xmlNode = xmlNodePtr.pointee

        let xmlNodeName = String(cString: xmlNode.name)
        let xmlNodeText = String(cString: xmlNode.content)
        
        XCTAssertEqual(xmlNodeName, nodeName)
        XCTAssertEqual(xmlNodeText, nodeText)

        // For some reason UnsafePointer<> types don't really like XCTAssertEqual().  We'll just
        // manually compare against nil.
        //
        XCTAssert(xmlNode.properties == nil)
        XCTAssert(xmlNode.children == nil)
        
        xmlFreeNode(xmlNodePtr)
    }

    func testElementAndChildElementNodeConversion() {
        
        let innerNodeName = "innerNode"
        let innerNode = ElementNode(name: innerNodeName, attributes: [], children: [], registerUndo: { _ in })
        
        let outerNodeName = "element"
        let testNode = ElementNode(name: outerNodeName, attributes: [], children: [innerNode], registerUndo: { _ in })
        
        let xmlOuterNodePtr = Libxml2.Out.NodeConverter().convert(testNode)
        let xmlOuterNode = xmlOuterNodePtr.pointee
        let xmlOuterNodeName = String(cString: xmlOuterNode.name)

        XCTAssertEqual(xmlOuterNodeName, outerNodeName)

        // For some reason UnsafePointer<> types don't really like XCTAssertEqual().  We'll just
        // manually compare against nil.
        //
        XCTAssert(xmlOuterNode.properties == nil)
        XCTAssert(xmlOuterNode.children != nil)

        let xmlInnerNode = xmlOuterNode.children.pointee
        let xmlInnerNodeName = String(cString: xmlInnerNode.name)

        XCTAssertEqual(xmlInnerNodeName, innerNodeName)

        // For some reason UnsafePointer<> types don't really like XCTAssertEqual().  We'll just
        // manually compare against nil.
        //
        XCTAssert(xmlInnerNode.properties == nil)
        XCTAssert(xmlInnerNode.children == nil)

        xmlFreeNode(xmlOuterNodePtr)
    }

    func testElementAndChildTextNodeConversion() {

        let innerNodeText = "some text"
        let innerNode = TextNode(text: innerNodeText, registerUndo: { _ in })

        let outerNodeName = "element"
        let testNode = ElementNode(name: outerNodeName, attributes: [], children: [innerNode], registerUndo: { _ in })

        let xmlOuterNodePtr = Libxml2.Out.NodeConverter().convert(testNode)
        let xmlOuterNode = xmlOuterNodePtr.pointee
        let xmlOuterNodeName = String(cString: xmlOuterNode.name)

        XCTAssertEqual(xmlOuterNodeName, outerNodeName)

        // For some reason UnsafePointer<> types don't really like XCTAssertEqual().  We'll just
        // manually compare against nil.
        //
        XCTAssert(xmlOuterNode.properties == nil)
        XCTAssert(xmlOuterNode.children != nil)

        let xmlInnerNode = xmlOuterNode.children.pointee
        let xmlInnerNodeName = String(cString: xmlInnerNode.name)
        let xmlInnerNodeText = String(cString: xmlInnerNode.content)

        XCTAssertEqual(xmlInnerNodeName, "text")
        XCTAssertEqual(xmlInnerNodeText, innerNodeText)

        // For some reason UnsafePointer<> types don't really like XCTAssertEqual().  We'll just
        // manually compare against nil.
        //
        XCTAssert(xmlInnerNode.properties == nil)
        XCTAssert(xmlInnerNode.children == nil)

        xmlFreeNode(xmlOuterNodePtr)
    }
}
