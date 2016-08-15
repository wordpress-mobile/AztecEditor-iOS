import XCTest
@testable import Aztec

class InHTMLConverterTests: XCTestCase {

    typealias ElementNode = Libxml2.ElementNode
    typealias TextNode = Libxml2.TextNode

    typealias Attribute = Libxml2.Attribute
    typealias StringAttribute = Libxml2.StringAttribute

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testSimpleHTMLConversion() {
        let parser = Libxml2.In.HTMLConverter()

        let html = "<bold>Hello!</bold>"

        do {
            let rootNode = try parser.convert(html)

            XCTAssertEqual(rootNode.children.count, 1)

            guard let htmlNode = rootNode.children[0] as? ElementNode else {
                XCTFail("Expected an element node.")
                return
            }

            XCTAssertEqual(htmlNode.name, "bold")
            XCTAssertEqual(htmlNode.attributes.count, 0)

            guard let textNode = htmlNode.children[0] as? TextNode else {
                XCTFail("Expected a text node.")
                return
            }

            XCTAssertEqual(textNode.text, "Hello!")
        } catch {
            XCTFail("Unexpected conversion failure.")
        }
    }

    func testComplexHTMLConversion() {
        let parser = Libxml2.In.HTMLConverter()

        let html = "<div styLe='a' nostyle peace='123'>Hello <b>World</b>!</div>"

        do {
            let rootNode = try parser.convert(html)

            XCTAssertEqual(rootNode.children.count, 1)

            guard let divNode = rootNode.children[0] as? ElementNode else {
                XCTFail("Expected the div element node.")
                return
            }

            XCTAssertEqual(divNode.name, "div")
            XCTAssertEqual(divNode.attributes.count, 3)

            guard let attribute1 = divNode.attributes[0] as? StringAttribute else {
                XCTFail("Expected a string attribute.")
                return
            }

            let attribute2 = divNode.attributes[1]

            guard let attribute3 = divNode.attributes[2] as? StringAttribute else {
                XCTFail("Expected a string attribute.")
                return
            }

            XCTAssertEqual(attribute1.name, "style")
            XCTAssertEqual(attribute1.value, "a")
            XCTAssertEqual(attribute2.name, "nostyle")
            XCTAssertEqual(attribute3.name, "peace")
            XCTAssertEqual(attribute3.value, "123")

            XCTAssert(divNode.children[0] is TextNode)
            XCTAssert(divNode.children[2] is TextNode)

            guard let boldNode = divNode.children[1] as? ElementNode else {
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
