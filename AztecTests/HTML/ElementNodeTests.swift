import XCTest
@testable import Aztec

class ElementNodeTests: XCTestCase {

    typealias Attribute = Libxml2.Attribute
    typealias ElementNode = Libxml2.ElementNode
    typealias ElementNodeDescriptor = Libxml2.ElementNodeDescriptor
    typealias RootNode = Libxml2.RootNode
    typealias StandardElementType = Libxml2.StandardElementType
    typealias StringAttribute = Libxml2.StringAttribute
    typealias TextNode = Libxml2.TextNode

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    // MARK: - Misc / Unorganized

    /// Tries to obtain the lowest block-level elements intersecting the specified range.
    ///
    /// HTML string: <p>Hello <b>world</b>!</p>
    /// Range: (6...5)
    ///
    /// The result should be: 
    ///     - element: the main paragraph
    ///     - range: (6...5)
    ///
    func testEnumerateBlockLowestElementsIntersectingRange() {

        let textNode1 = TextNode(text: "Hello ")
        let textNode2 = TextNode(text: "world")
        let textNode3 = TextNode(text: "!")
        let boldNode = ElementNode(name: "b", attributes: [], children: [textNode2])
        let paragraph = ElementNode(name: "p", attributes: [], children: [textNode1, boldNode, textNode3])

        let range = NSRange(location: textNode1.length(), length: textNode2.length())
        let atLeastOneElementFound = expectation(description: "At least one elements should be returned in the enumeration.")

        paragraph.enumerateLowestBlockLevelElements(intersectingRange: range) { (element, intersection) in
            XCTAssertEqual(element, paragraph)
            XCTAssertEqual(intersection.location, range.location)
            XCTAssertEqual(intersection.length, range.length)
            atLeastOneElementFound.fulfill()
        }
        waitForExpectations(timeout: 0) { (error) in
            if let error = error {
                XCTFail(error.localizedDescription)
            }
        }
    }
    
    func testLeafNodesWrappingRange1() {
        let text1 = TextNode(text: "text1 goes here")
        let text2 = TextNode(text: "text2 goes here")
        let text3 = TextNode(text: "text3 goes here")

        let mainNode = ElementNode(name: "p", attributes: [], children: [text1, text2, text3])
        let range = NSRange(location: 0, length: mainNode.length())

        let nodesAndRanges = mainNode.leafNodesWrapping(range)

        XCTAssertEqual(nodesAndRanges.count, 3)
        XCTAssertEqual(nodesAndRanges[0].node as? TextNode, text1)
        XCTAssertEqual(nodesAndRanges[1].node as? TextNode, text2)
        XCTAssertEqual(nodesAndRanges[2].node as? TextNode, text3)

        XCTAssert(NSEqualRanges(nodesAndRanges[0].range, NSRange(location: 0, length: text1.length())))
        XCTAssert(NSEqualRanges(nodesAndRanges[1].range, NSRange(location: 0, length: text2.length())))
        XCTAssert(NSEqualRanges(nodesAndRanges[2].range, NSRange(location: 0, length: text3.length())))
    }

    func testLeafNodesWrappingRange2() {
        let text1 = TextNode(text: "text1 goes here")
        let text2 = TextNode(text: "text2 goes here.")
        let text3 = TextNode(text: "text3 goes here..")

        let mainNode = ElementNode(name: "p", attributes: [], children: [text1, text2, text3])
        let range = NSRange(location: 0, length: mainNode.length() - 1)

        let nodesAndRanges = mainNode.leafNodesWrapping(range)

        XCTAssertEqual(nodesAndRanges.count, 3)
        XCTAssertEqual(nodesAndRanges[0].node as? TextNode, text1)
        XCTAssertEqual(nodesAndRanges[1].node as? TextNode, text2)
        XCTAssertEqual(nodesAndRanges[2].node as? TextNode, text3)

        XCTAssert(NSEqualRanges(nodesAndRanges[0].range, NSRange(location: 0, length: text1.length())))
        XCTAssert(NSEqualRanges(nodesAndRanges[1].range, NSRange(location: 0, length: text2.length())))
        XCTAssert(NSEqualRanges(nodesAndRanges[2].range, NSRange(location: 0, length: text3.length() - 1)))
    }

    func testLeafNodesWrappingRange3() {
        let text1 = TextNode(text: "text1 goes here")
        let text2 = TextNode(text: "text2 goes here.")
        let text3 = TextNode(text: "text3 goes here..")

        let mainNode = ElementNode(name: "p", attributes: [], children: [text1, text2, text3])
        let range = NSRange(location: 1, length: mainNode.length() - 1)

        let nodesAndRanges = mainNode.leafNodesWrapping(range)

        XCTAssertEqual(nodesAndRanges.count, 3)
        XCTAssertEqual(nodesAndRanges[0].node as? TextNode, text1)
        XCTAssertEqual(nodesAndRanges[1].node as? TextNode, text2)
        XCTAssertEqual(nodesAndRanges[2].node as? TextNode, text3)

        XCTAssert(NSEqualRanges(nodesAndRanges[0].range, NSRange(location: 1, length: text1.length() - 1)))
        XCTAssert(NSEqualRanges(nodesAndRanges[1].range, NSRange(location: 0, length: text2.length())))
        XCTAssert(NSEqualRanges(nodesAndRanges[2].range, NSRange(location: 0, length: text3.length())))
    }

    func testLeafNodesWrappingRange4() {
        let text1 = TextNode(text: "text1 goes here")
        let text2 = TextNode(text: "text2 goes here.")
        let text3 = TextNode(text: "text3 goes here..")

        let mainNode = ElementNode(name: "p", attributes: [], children: [text1, text2, text3])
        let range = NSRange(location: text1.length(), length: mainNode.length() - text1.length())

        let nodesAndRanges = mainNode.leafNodesWrapping(range)

        XCTAssertEqual(nodesAndRanges.count, 2)
        XCTAssertEqual(nodesAndRanges[0].node as? TextNode, text2)
        XCTAssertEqual(nodesAndRanges[1].node as? TextNode, text3)

        XCTAssert(NSEqualRanges(nodesAndRanges[0].range, NSRange(location: 0, length: text2.length())))
        XCTAssert(NSEqualRanges(nodesAndRanges[1].range, NSRange(location: 0, length: text3.length())))
    }

    func testLeafNodesWrappingRange5() {
        let text1 = TextNode(text: "text1 goes here")
        let text2 = TextNode(text: "text2 goes here.")
        let text3 = TextNode(text: "text3 goes here..")

        let mainNode = ElementNode(name: "p", attributes: [], children: [text1, text2, text3])
        let range = NSRange(location: 0, length: mainNode.length() - text3.length())

        let nodesAndRanges = mainNode.leafNodesWrapping(range)

        XCTAssertEqual(nodesAndRanges.count, 2)
        XCTAssertEqual(nodesAndRanges[0].node as? TextNode, text1)
        XCTAssertEqual(nodesAndRanges[1].node as? TextNode, text2)

        XCTAssert(NSEqualRanges(nodesAndRanges[0].range, NSRange(location: 0, length: text1.length())))
        XCTAssert(NSEqualRanges(nodesAndRanges[1].range, NSRange(location: 0, length: text2.length())))
    }

    func testLeafNodesWrappingRange6() {
        let text1 = TextNode(text: "text1 goes here")
        let text2 = TextNode(text: "text2 goes here.")
        let text3 = TextNode(text: "text3 goes here..")

        let mainNode = ElementNode(name: "p", attributes: [], children: [text1, text2, text3])
        let range = NSRange(location: text1.length(), length: 0)

        let nodesAndRanges = mainNode.leafNodesWrapping(range)

        XCTAssertEqual(nodesAndRanges.count, 1)
        XCTAssertEqual(nodesAndRanges[0].node as? TextNode, text2)

        XCTAssert(NSEqualRanges(nodesAndRanges[0].range, NSRange(location: 0, length: 0)))
    }

    func testLeafNodesWrappingRange7() {
        let text1 = TextNode(text: "text1 goes here")
        let text2 = TextNode(text: "text2 goes here.")
        let text3 = TextNode(text: "text3 goes here..")

        let mainNode = ElementNode(name: "p", attributes: [], children: [text1, text2, text3])
        let range = NSRange(location: text1.length() - 1, length: 0)

        let nodesAndRanges = mainNode.leafNodesWrapping(range)

        XCTAssertEqual(nodesAndRanges.count, 1)
        XCTAssertEqual(nodesAndRanges[0].node as? TextNode, text1)

        XCTAssert(NSEqualRanges(nodesAndRanges[0].range, NSRange(location: text1.length() - 1, length: 0)))
    }

    /// Tests obtaining the block-level elements intercepting the full range of the following
    /// HTML string: <div>Hello <p>there</p></div>
    ///
    /// The results should be:
    ///     - (node: div, range: (0...6))
    ///     - (node: p, range: (0...5))
    ///
    func testLowestBlockLevelElements1() {

        let textPart1 = "Hello "
        let textPart2 = "there"

        let textNode1 = TextNode(text: textPart1)
        let textNode2 = TextNode(text: textPart2)

        let paragraph = ElementNode(name: "p", attributes: [], children: [textNode2])
        let div = ElementNode(name: "div", attributes: [], children: [textNode1, paragraph])

        let results = div.lowestBlockLevelElements(intersectingRange: div.range())

        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].element.name, "div")
        XCTAssertEqual(results[0].intersection.location, 0)
        XCTAssertEqual(results[0].intersection.length, 6)
        XCTAssertEqual(results[1].element.name, "p")
        XCTAssertEqual(results[1].intersection.location, 0)
        XCTAssertEqual(results[1].intersection.length, 5)
    }

    /// Tests obtaining the block-level elements intercepting the full range of the following
    /// HTML string: <div>Hello <p>there</p> man!</div>
    ///
    /// The results should be:
    ///     - (node: div, range: (0...6))
    ///     - (node: p, range: (0...5))
    ///     - (node: div, range: (11...5))
    ///
    func testLowestBlockLevelElements2() {

        let textPart1 = "Hello "
        let textPart2 = "there"
        let textPart3 = " man!"

        let textNode1 = TextNode(text: textPart1)
        let textNode2 = TextNode(text: textPart2)
        let textNode3 = TextNode(text: textPart3)

        let paragraph = ElementNode(name: "p", attributes: [], children: [textNode2])
        let div = ElementNode(name: "div", attributes: [], children: [textNode1, paragraph, textNode3])

        let results = div.lowestBlockLevelElements(intersectingRange: div.range())

        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(results[0].element.name, "div")
        XCTAssertEqual(results[0].intersection.location, 0)
        XCTAssertEqual(results[0].intersection.length, 6)
        XCTAssertEqual(results[1].element.name, "p")
        XCTAssertEqual(results[1].intersection.location, 0)
        XCTAssertEqual(results[1].intersection.length, 5)
        XCTAssertEqual(results[2].element.name, "div")
        XCTAssertEqual(results[2].intersection.location, 11)
        XCTAssertEqual(results[2].intersection.length, 5)
    }


    /// Tests obtaining the block-level elements intercepting the full range of the following
    ///
    /// HTML string: <div><p>Hello </p>there!</div>
    ///
    /// The results should be:
    ///     - (node: p, range: (0...6))
    ///     - (node: div, range: (6...6))
    ///
    func testLowestBlockLevelElements3() {

        let textPart1 = "Hello "
        let textPart2 = "there!"

        let textNode1 = TextNode(text: textPart1)
        let textNode2 = TextNode(text: textPart2)

        let paragraph = ElementNode(name: "p", attributes: [], children: [textNode1])
        let div = ElementNode(name: "div", attributes: [], children: [paragraph, textNode2])

        let results = div.lowestBlockLevelElements(intersectingRange: div.range())

        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].element.name, "p")
        XCTAssertEqual(results[0].intersection.location, 0)
        XCTAssertEqual(results[0].intersection.length, 6)
        XCTAssertEqual(results[1].element.name, "div")
        XCTAssertEqual(results[1].intersection.location, 6)
        XCTAssertEqual(results[1].intersection.length, 6)
    }

    /// Tests `childNodes(intersectingRange:)` with a zero-length range.
    ///
    /// Input HTML: <p>This is a test string.</p>
    /// Range: (5...0)
    ///
    /// Expected results:
    ///     - should find 1 matching child node (the text node)
    ///     - the range should be unchanged
    ///
    func testChildNodesIntersectingRange1() {
        let textNode = TextNode(text: "This is a test string.")
        let rangeLocation = 5
        XCTAssert(rangeLocation < textNode.length(),
                  "For this text we need to make sure the range location is inside the test node.")

        let range = NSRange(location: rangeLocation, length: 0)
        let paragraph = ElementNode(name: "p", attributes: [], children: [textNode])

        let childrenAndRanges = paragraph.childNodes(intersectingRange: range)

        guard childrenAndRanges.count == 1 else {
            XCTFail("Expected 1 child.")
            return
        }

        XCTAssertEqual(childrenAndRanges[0].child, textNode)
        XCTAssert(NSEqualRanges(childrenAndRanges[0].intersection, range))
    }


    /// Tests `childNodes(intersectingRange:)` with a zero-length range.
    ///
    /// Input HTML: <p>This is a test string.</p>
    /// Range: (0...0)
    ///
    /// Expected results:
    ///     - should find 1 matching child node (the text node)
    ///     - the range should be unchanged
    ///
    func testChildNodesIntersectingRange2() {
        let textNode = TextNode(text: "This is a test string.")
        let rangeLocation = 0
        XCTAssert(rangeLocation < textNode.length(),
                  "For this text we need to make sure the range location is inside the test node.")

        let range = NSRange(location: rangeLocation, length: 0)
        let paragraph = ElementNode(name: "p", attributes: [], children: [textNode])

        let childrenAndRanges = paragraph.childNodes(intersectingRange: range)

        guard childrenAndRanges.count == 1 else {
            XCTFail("Expected 1 child.")
            return
        }

        XCTAssertEqual(childrenAndRanges[0].child, textNode)
        XCTAssert(NSEqualRanges(childrenAndRanges[0].intersection, range))
    }

    /// Tests `childNodes(intersectingRange:)` with a zero-length range.
    ///
    /// Input HTML: <p><b>Hello</b><b>Hello again!</b></p>
    /// Prefer left node: true
    /// Range: (5...0)
    ///
    /// Expected results:
    ///     - should find 2 matching child nodes
    ///     - the ranges should be at the end of the first node, and the beginning of the second
    ///
    func testChildNodesIntersectingRange3() {

        let textNode1 = TextNode(text: "Hello")
        let textNode2 = TextNode(text: "Hello again!")

        let rangeLocation = 5
        XCTAssert(rangeLocation == textNode1.length(),
                  "For this text we need to make sure the range location is inside the test node.")

        let range = NSRange(location: rangeLocation, length: 0)

        let bold1 = ElementNode(name: "b", attributes: [], children: [textNode1])
        let bold2 = ElementNode(name: "b", attributes: [], children: [textNode2])
        let paragraph = ElementNode(name: "p", attributes: [], children: [bold1, bold2])

        let childrenAndRanges = paragraph.childNodes(intersectingRange: range)

        guard childrenAndRanges.count == 2 else {
            XCTFail("Expected 2 children.")
            return
        }

        XCTAssertEqual(childrenAndRanges[0].child, bold1)
        XCTAssertEqual(childrenAndRanges[1].child, bold2)
        XCTAssert(NSEqualRanges(childrenAndRanges[0].intersection, range))
        XCTAssert(NSEqualRanges(childrenAndRanges[1].intersection, NSRange(location: 0, length: 0)))
    }
}
