import XCTest
@testable import Aztec

class ElementNodeTests: XCTestCase {

    typealias Attribute = Libxml2.HTML.Attribute
    typealias ElementNode = Libxml2.HTML.ElementNode
    typealias StringAttribute = Libxml2.HTML.StringAttribute
    typealias TextNode = Libxml2.HTML.TextNode

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    /// Whenever there's a single element node, make sure method `lowestElementNodeWrapping(range:)`
    /// returns the element node, as expected.
    ///
    func testThatLowestElementNodeWrappingRangeWorksWithASingleElementNode() {
        let text1 = TextNode(text: "text1 goes here")
        let text2 = TextNode(text: "text2 goes here")
        let text3 = TextNode(text: "text3 goes here")

        let mainNode = ElementNode(name: "p", attributes: [], children: [text1, text2, text3])
        let range = NSRange(location: text1.length(), length: text2.length())

        let node = mainNode.lowestElementNodeWrapping(range)

        XCTAssertEqual(node, mainNode)
    }

    /// Whenever the range is inside a child node, make sure that child node is returned.
    ///
    func testThatLowestElementNodeWrappingRangeWorksWithAChildNode1() {
        let text1 = TextNode(text: "text1 goes here")
        let text2 = TextNode(text: "text2 goes here")
        let text3 = TextNode(text: "text3 goes here")

        let childNode = ElementNode(name: "em", attributes: [], children: [text2])

        let mainNode = ElementNode(name: "p", attributes: [], children: [text1, childNode, text3])
        let range = NSRange(location: text1.length(), length: text2.length())

        let node = mainNode.lowestElementNodeWrapping(range)

        XCTAssertEqual(node, childNode)
    }

    /// Whenever the range is not strictly inside any child node, make sure the parent node is
    /// returned instead.
    ///
    func testThatLowestElementNodeWrappingRangeWorksWithAChildNode2() {
        let text1 = TextNode(text: "text1 goes here")
        let text2 = TextNode(text: "text2 goes here")
        let text3 = TextNode(text: "text3 goes here")

        let childNode = ElementNode(name: "em", attributes: [], children: [text2])

        let mainNode = ElementNode(name: "p", attributes: [], children: [text1, childNode, text3])
        let range = NSRange(location: text1.length() - 1, length: text2.length() + 2)

        let node = mainNode.lowestElementNodeWrapping(range)

        XCTAssertEqual(node, mainNode)
    }
    
}
