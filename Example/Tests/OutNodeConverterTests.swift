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

        let nodeNameText = "text"
        let nodeText = "This is the text."
        let testNode = TextNode(name: nodeNameText, text: nodeText, attributes: [])
        let xmlNode = Libxml2.Out.NodeConverter().convert(testNode)
        
        let xmlNodeNameText = String(CString: UnsafePointer<Int8>(xmlNode.name), encoding: NSUTF8StringEncoding)
        let xmlNodeText = String(CString: UnsafePointer<Int8>(xmlNode.content), encoding: NSUTF8StringEncoding)
        
        XCTAssertEqual(nodeText, xmlNodeText)
        XCTAssertEqual(nodeNameText, xmlNodeNameText)        
    }
}