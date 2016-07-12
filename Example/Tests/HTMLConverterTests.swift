import XCTest
@testable import Aztec

class HTMLConverterTests: XCTestCase {

    typealias ElementNode = Libxml2.HTML.ElementNode
    typealias TextNode = Libxml2.HTML.TextNode

    typealias Attribute = Libxml2.HTML.Attribute
    typealias StringAttribute = Libxml2.HTML.StringAttribute

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
/*
    func testExample() {
        let parser = Libxml2.HTMLConverter()

        let html = "<HTML style='a' nostye peace='123'>Hello World!</HTML>"
        let htmlData = html.dataUsingEncoding(NSUTF8StringEncoding)!
        let output = parser.convert(htmlData)

        if output.length > 0 {
            var range = NSRange(location: 0, length: output.length)
            let attributes = output.attributesAtIndex(0, effectiveRange: &range)
            print(output, attributes)
        }
    }
 */

    func testComplexHTMLConversion() {
        let parser = Libxml2.In.HTMLConverter()

        let html = "<HTML styLe='a' nostyle peace='123'>Hello <b>World</b>!</HTML>"
        let htmlData = html.dataUsingEncoding(NSUTF8StringEncoding)!

        do {
            let node = try parser.convert(htmlData)

            guard let htmlNode = node as? ElementNode else {
                XCTFail("Expected an element node.")
                return
            }

            XCTAssertEqual(htmlNode.name, "html")
            XCTAssertEqual(htmlNode.attributes.count, 3)

            guard let attribute1 = htmlNode.attributes[0] as? StringAttribute else {
                XCTFail("Expected a string attribute.")
                return
            }

            let attribute2 = htmlNode.attributes[1]

            guard let attribute3 = htmlNode.attributes[2] as? StringAttribute else {
                XCTFail("Expected a string attribute.")
                return
            }

            XCTAssertEqual(attribute1.name, "style")
            XCTAssertEqual(attribute1.value, "a")
            XCTAssertEqual(attribute2.name, "nostyle")
            XCTAssertEqual(attribute3.name, "peace")
            XCTAssertEqual(attribute3.value, "123")

            XCTAssert(htmlNode.children[0] is TextNode)
            XCTAssert(htmlNode.children[2] is TextNode)

            guard let boldNode = htmlNode.children[1] as? ElementNode else {
                XCTFail("Expected an element node.")
                return
            }

            XCTAssert(boldNode.name == "b")
            XCTAssert(boldNode.children[0] is TextNode)

        } catch {
            XCTFail("Unexpected conversion failure.")
        }
    }
}
