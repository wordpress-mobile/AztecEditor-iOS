//import XCTest
//@testable import Aztec
//
//class OutHTMLConverterTests: XCTestCase {
//
//    typealias ElementNode = Libxml2.HTML.ElementNode
//    typealias TextNode = Libxml2.HTML.TextNode
//
//    typealias Attribute = Libxml2.HTML.Attribute
//    typealias StringAttribute = Libxml2.HTML.StringAttribute
//
//    override func setUp() {
//        super.setUp()
//        // Put setup code here. This method is called before the invocation of each test method in the class.
//    }
//
//    override func tearDown() {
//        // Put teardown code here. This method is called after the invocation of each test method in the class.
//        super.tearDown()
//    }
//
//    func testSimpleHTMLConversion() {
//        let parser = Libxml2.In.HTMLConverter()
//
//        let html = "<bold>Hello!</bold>"
//        let htmlData = html.dataUsingEncoding(NSUTF8StringEncoding)!
//
//        do {
//            let node = try parser.convert(htmlData)
//
//            guard let htmlNode = node as? ElementNode else {
//                XCTFail("Expected an element node.")
//                return
//            }
//
//            XCTAssertEqual(htmlNode.name, "bold")
//            XCTAssertEqual(htmlNode.attributes.count, 0)
//
//            guard let textNode = htmlNode.children[0] as? TextNode else {
//                XCTFail("Expected a text node.")
//                return
//            }
//
//            XCTAssertEqual(textNode.text, "Hello!")
//        } catch {
//            XCTFail("Unexpected conversion failure.")
//        }
//    }
//
//}
