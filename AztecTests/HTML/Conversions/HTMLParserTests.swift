import XCTest
@testable import Aztec

class HTMLParserTests: XCTestCase {

    func testSimpleHTMLConversion() {
        let parser = HTMLParser()

        let html = "<bold>Hello!</bold>"

        let rootNode = parser.parse(html)

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

        XCTAssertEqual(textNode.text(), "Hello!")
    }

    func testComplexHTMLConversion() {
        let parser = HTMLParser()

        let html = "<div styLe='a' nostyle peace='123'>Hello <b>World</b>!</div>"

        let rootNode = parser.parse(html)

        XCTAssertEqual(rootNode.children.count, 1)

        guard let divNode = rootNode.children[0] as? ElementNode else {
            XCTFail("Expected the div element node.")
            return
        }

        XCTAssertEqual(divNode.name, "div")
        XCTAssertEqual(divNode.attributes.count, 3)

        let attribute1 = divNode.attributes[0]
        let attribute2 = divNode.attributes[1]
        let attribute3 = divNode.attributes[2]

        XCTAssertEqual(attribute1.name, "style")
        XCTAssertEqual(attribute1.value.toString(), "a")
        XCTAssertEqual(attribute2.name, "nostyle")
        XCTAssertEqual(attribute3.name, "peace")
        XCTAssertEqual(attribute3.value.toString(), "123")

        XCTAssert(divNode.children[0] is TextNode)
        XCTAssert(divNode.children[2] is TextNode)

        guard let boldNode = divNode.children[1] as? ElementNode else {
            XCTFail("Expected an element node.")
            return
        }

        XCTAssert(boldNode.name == "b")
        XCTAssert(boldNode.children[0] is TextNode)
    }

    func testNonASCIIConversion() {
        let parser = HTMLParser()

        let html = "Otro año más"

        let rootNode = parser.parse(html)

        XCTAssertEqual(rootNode.children.count, 1)

        guard let textNode = rootNode.children.first as? TextNode else {
            XCTFail("Expected some text")
            return
        }

        XCTAssertEqual(textNode.text(), html)
    }
}
