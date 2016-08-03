import XCTest
@testable import Aztec
import libxml2

class OutNodeConverterTests: XCTestCase {

    typealias HTML = Libxml2.HTML
    typealias ElementNode = HTML.ElementNode
    typealias Node = HTML.Node
    typealias TextNode = HTML.TextNode

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
        let textNode = TextNode(text: nodeText, attributes: [])
        let xmlNodePtr = Libxml2.Out.NodeConverter().convert(textNode)
        let xmlNode = xmlNodePtr.memory

        let xmlNodeName = String(CString: UnsafePointer<Int8>(xmlNode.name), encoding: NSUTF8StringEncoding)
        let xmlNodeText = String(CString: UnsafePointer<Int8>(xmlNode.content), encoding: NSUTF8StringEncoding)
        
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
        let innerNode = ElementNode(name: innerNodeName, attributes: [], children: [])
        
        let outerNodeName = "element"
        let testNode = ElementNode(name: outerNodeName, attributes: [], children: [innerNode])
        
        let xmlOuterNodePtr = Libxml2.Out.NodeConverter().convert(testNode)
        let xmlOuterNode = xmlOuterNodePtr.memory
        let xmlOuterNodeName = String(CString: UnsafePointer<Int8>(xmlOuterNode.name), encoding: NSUTF8StringEncoding)

        XCTAssertEqual(xmlOuterNodeName, outerNodeName)

        // For some reason UnsafePointer<> types don't really like XCTAssertEqual().  We'll just
        // manually compare against nil.
        //
        XCTAssert(xmlOuterNode.properties == nil)
        XCTAssert(xmlOuterNode.children != nil)

        let xmlInnerNode = xmlOuterNode.children.memory
        let xmlInnerNodeName = String(CString: UnsafePointer<Int8>(xmlInnerNode.name), encoding: NSUTF8StringEncoding)

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
        let innerNode = TextNode(text: innerNodeText, attributes: [])

        let outerNodeName = "element"
        let testNode = ElementNode(name: outerNodeName, attributes: [], children: [innerNode])

        let xmlOuterNodePtr = Libxml2.Out.NodeConverter().convert(testNode)
        let xmlOuterNode = xmlOuterNodePtr.memory
        let xmlOuterNodeName = String(CString: UnsafePointer<Int8>(xmlOuterNode.name), encoding: NSUTF8StringEncoding)

        XCTAssertEqual(xmlOuterNodeName, outerNodeName)

        // For some reason UnsafePointer<> types don't really like XCTAssertEqual().  We'll just
        // manually compare against nil.
        //
        XCTAssert(xmlOuterNode.properties == nil)
        XCTAssert(xmlOuterNode.children != nil)

        let xmlInnerNode = xmlOuterNode.children.memory
        let xmlInnerNodeName = String(CString: UnsafePointer<Int8>(xmlInnerNode.name), encoding: NSUTF8StringEncoding)
        let xmlInnerNodeText = String(CString: UnsafePointer<Int8>(xmlInnerNode.content), encoding: NSUTF8StringEncoding)

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