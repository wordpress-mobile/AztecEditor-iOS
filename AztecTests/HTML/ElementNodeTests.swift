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
    
    // MARK: - Prepend
    
    /// Tests that `prepend(_ child:)` works.
    ///
    /// Inputs:
    ///     - HTML: "<b> world!</b>"
    ///     - String to prepend: "Hello"
    ///
    /// Verifications:
    ///     - HTML: "<b>Hello world!</b>
    ///
    func testPrepend() {
        let text1 = "Hello"
        let text2 = " world!"
        let fullText = "\(text1)\(text2)"
        
        let textNode1 = TextNode(text: text1)
        let textNode2 = TextNode(text: text2)
        let boldNode = ElementNode(name: StandardElementType.b.rawValue, attributes: [], children: [textNode2])
        
        XCTAssertEqual(boldNode.children.count, 1)
        XCTAssertEqual(boldNode.children[0], textNode2)
        XCTAssertEqual(boldNode.text(), text2)
        
        boldNode.prepend(textNode1)
        
        XCTAssertEqual(boldNode.children.count, 1)
        XCTAssertEqual(boldNode.children[0].text(), fullText)
        XCTAssertEqual(boldNode.text(), fullText)
    }
    
    // MARK: - Misc / Unorganized

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

    /// Whenever there's a single element node, make sure method `lowestTextNodeWrapping(range:)`
    /// returns the text node, as expected.
    ///
    func testThatLowestTextNodeWrappingRangeWorksWithASingleElementNode() {
        let text1 = TextNode(text: "text1 goes here")
        let text2 = TextNode(text: "text2 goes here")
        let text3 = TextNode(text: "text3 goes here")

        let mainNode = ElementNode(name: "p", attributes: [], children: [text1, text2, text3])
        let range = NSRange(location: text1.length(), length: text2.length())

        let node = mainNode.lowestTextNodeWrapping(range)

        XCTAssertEqual(node, text2)
    }

    /// Whenever the range is inside a child node, make sure that child node is returned.
    ///
    func testThatLowestTextNodeWrappingRangeWorksWithAChildNode1() {
        let text1 = TextNode(text: "text1 goes here")
        let text2 = TextNode(text: "text2 goes here")
        let text3 = TextNode(text: "text3 goes here")

        let childNode = ElementNode(name: "em", attributes: [], children: [text2])

        let mainNode = ElementNode(name: "p", attributes: [], children: [text1, childNode, text3])
        let range = NSRange(location: text1.length(), length: text2.length())

        let node = mainNode.lowestTextNodeWrapping(range)

        XCTAssertEqual(node, text2)
    }

    /// Whenever the range is not strictly inside any child node, make sure the parent node is
    /// returned instead.
    ///
    func testThatLowestTextNodeWrappingRangeWorksWithAChildNode2() {
        let text1 = TextNode(text: "text1 goes here")
        let text2 = TextNode(text: "text2 goes here")
        let text3 = TextNode(text: "text3 goes here")

        let childNode = ElementNode(name: "em", attributes: [], children: [text2])

        let mainNode = ElementNode(name: "p", attributes: [], children: [text1, childNode, text3])
        let range = NSRange(location: text1.length() - 1, length: text2.length() + 2)

        let node = mainNode.lowestTextNodeWrapping(range)
        
        XCTAssertEqual(node, nil)
    }

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
    
    /// Tests `insert(string: String, at index: Int)`.
    ///
    /// Input HTML: <p><b>Hello1</b><b>Hello2</b></p>
    /// String: "---"
    /// Index: 0
    ///
    /// Expected results:
    ///     - Output should be: <p>---<b>Hello1</b><b>Hello2</b></p>
    ///
    func testInsertStringAt1() {
        let textNode1 = TextNode(text: "Hello1")
        let textNode2 = TextNode(text: "Hello2")
        let boldNode1 = ElementNode(name: "b", attributes: [], children: [textNode1])
        let boldNode2 = ElementNode(name: "b", attributes: [], children: [textNode2])
        let paragraph = ElementNode(name: "p", attributes: [], children: [boldNode1, boldNode2])
        
        let textToInsert = "---"
        
        paragraph.insert(textToInsert, atNodeIndex: 0)
        
        XCTAssertEqual(paragraph.children.count, 3)
        
        guard let newTextNode = paragraph.children[0] as? TextNode, newTextNode.text() == textToInsert else {
                XCTFail("Expected a text node here with the inserted text.")
                return
        }
        
        XCTAssertEqual(paragraph.children[1], boldNode1)
        XCTAssertEqual(paragraph.children[2], boldNode2)
    }
    
    /// Tests `insert(string: String, at index: Int)`.
    ///
    /// Input HTML: <p><b>Hello1</b><b>Hello2</b></p>
    /// String: "---"
    /// Index: 1
    ///
    /// Expected results:
    ///     - Output should be: <p><b>Hello1</b>---<b>Hello2</b></p>
    ///
    func testInsertStringAt2() {
        let textNode1 = TextNode(text: "Hello1")
        let textNode2 = TextNode(text: "Hello2")
        let boldNode1 = ElementNode(name: "b", attributes: [], children: [textNode1])
        let boldNode2 = ElementNode(name: "b", attributes: [], children: [textNode2])
        let paragraph = ElementNode(name: "p", attributes: [], children: [boldNode1, boldNode2])
        
        let textToInsert = "---"
        
        paragraph.insert(textToInsert, atNodeIndex: 1)
        
        XCTAssertEqual(paragraph.children.count, 3)
        
        guard let newTextNode = paragraph.children[1] as? TextNode, newTextNode.text() == textToInsert else {
                XCTFail("Expected a text node here with the inserted text.")
                return
        }
        
        XCTAssertEqual(paragraph.children[0], boldNode1)
        XCTAssertEqual(paragraph.children[2], boldNode2)
    }
    
    /// Tests `insert(string: String, at index: Int)`.
    ///
    /// Input HTML: <p><b>Hello1</b><b>Hello2</b></p>
    /// String: "---"
    /// Index: 2
    ///
    /// Expected results:
    ///     - Output should be: <p><b>Hello1</b><b>Hello2</b>---</p>
    ///
    func testInsertStringAt3() {
        let textNode1 = TextNode(text: "Hello1")
        let textNode2 = TextNode(text: "Hello2")
        let boldNode1 = ElementNode(name: "b", attributes: [], children: [textNode1])
        let boldNode2 = ElementNode(name: "b", attributes: [], children: [textNode2])
        let paragraph = ElementNode(name: "p", attributes: [], children: [boldNode1, boldNode2])
        
        let textToInsert = "---"
        
        paragraph.insert(textToInsert, atNodeIndex: 2)

        XCTAssertEqual(paragraph.children.count, 3)
        
        guard let newTextNode = paragraph.children[2] as? TextNode, newTextNode.text() == textToInsert else {
                XCTFail("Expected a text node here with the inserted text.")
                return
        }
        
        XCTAssertEqual(paragraph.children[0], boldNode1)
        XCTAssertEqual(paragraph.children[1], boldNode2)
    }
    
    /// Tests `insert(string: String, at index: Int)`.
    ///
    /// Input HTML: <p>Hello1<b>Hello2</b>Hello3</p>
    /// String: "---"
    /// Index: 0
    ///
    /// Expected results:
    ///     - Output should be: <p>---Hello1<b>Hello2</b>Hello3</p>
    ///     - The string should be attached to the adjacent TextNode.
    ///
    func testInsertStringAt4() {
        
        let adjacentText = "Hello1"
        
        let textNode1 = TextNode(text: adjacentText)
        let textNode2 = TextNode(text: "Hello2")
        let textNode3 = TextNode(text: "Hello3")
        let boldNode = ElementNode(name: "b", attributes: [], children: [textNode2])
        let paragraph = ElementNode(name: "p", attributes: [], children: [textNode1, boldNode, textNode3])
        
        let textToInsert = "---"
        
        paragraph.insert(textToInsert, atNodeIndex: 0)
        
        XCTAssertEqual(paragraph.children.count, 3)
        
        guard let textNode = paragraph.children[0] as? TextNode, textNode.text() == "\(textToInsert)\(adjacentText)" else {
                XCTFail("Expected a text node here with the inserted text.")
                return
        }
        
        XCTAssertEqual(paragraph.children[1], boldNode)
        XCTAssertEqual(paragraph.children[2], textNode3)
    }
    
    /// Tests `insert(string: String, at index: Int)`.
    ///
    /// Input HTML: <p>Hello1<b>Hello2</b>Hello3</p>
    /// String: "---"
    /// Index: 1
    ///
    /// Expected results:
    ///     - Output should be: <p>Hello1---<b>Hello2</b>Hello3</p>
    ///     - The string should be attached to the adjacent TextNode.
    ///
    func testInsertStringAt5() {
        
        let adjacentText = "Hello1"
        
        let textNode1 = TextNode(text: adjacentText)
        let textNode2 = TextNode(text: "Hello2")
        let textNode3 = TextNode(text: "Hello3")
        let boldNode = ElementNode(name: "b", attributes: [], children: [textNode2])
        let paragraph = ElementNode(name: "p", attributes: [], children: [textNode1, boldNode, textNode3])
        
        let textToInsert = "---"
        
        paragraph.insert(textToInsert, atNodeIndex: 1)
        
        XCTAssertEqual(paragraph.children.count, 3)
        
        guard let textNode = paragraph.children[0] as? TextNode, textNode.text() == "\(adjacentText)\(textToInsert)" else {
                XCTFail("Expected a text node here with the inserted text.")
                return
        }
        
        XCTAssertEqual(paragraph.children[1], boldNode)
        XCTAssertEqual(paragraph.children[2], textNode3)
    }
    
    /// Tests `insert(string: String, at index: Int)`.
    ///
    /// Input HTML: <p>Hello1<b>Hello2</b>Hello3</p>
    /// String: "---"
    /// Index: 2
    ///
    /// Expected results:
    ///     - Output should be: <p>Hello1<b>Hello2</b>---Hello3</p>
    ///     - The string should be attached to the adjacent TextNode.
    ///
    func testInsertStringAt6() {
        
        let adjacentText = "Hello3"
        
        let textNode1 = TextNode(text: "Hello1")
        let textNode2 = TextNode(text: "Hello2")
        let textNode3 = TextNode(text: adjacentText)
        let boldNode = ElementNode(name: "b", attributes: [], children: [textNode2])
        let paragraph = ElementNode(name: "p", attributes: [], children: [textNode1, boldNode, textNode3])
        
        let textToInsert = "---"
        
        paragraph.insert(textToInsert, atNodeIndex: 2)
        
        XCTAssertEqual(paragraph.children.count, 3)
        
        guard let textNode = paragraph.children[2] as? TextNode, textNode.text() == "\(textToInsert)\(adjacentText)" else {
                XCTFail("Expected a text node here with the inserted text.")
                return
        }
        
        XCTAssertEqual(paragraph.children[0], textNode1)
        XCTAssertEqual(paragraph.children[1], boldNode)
    }
    
    
    /// Tests `insert(string: String, at index: Int)`.
    ///
    /// Input HTML: <p>Hello1<b>Hello2</b>Hello3</p>
    /// String: "---"
    /// Index: 3
    ///
    /// Expected results:
    ///     - Output should be: <p>Hello1<b>Hello2</b>Hello3---</p>
    ///     - The string should be attached to the adjacent TextNode.
    ///
    func testInsertStringAt7() {
        
        let adjacentText = "Hello3"
        
        let textNode1 = TextNode(text: "Hello1")
        let textNode2 = TextNode(text: "Hello2")
        let textNode3 = TextNode(text: adjacentText)
        let boldNode = ElementNode(name: "b", attributes: [], children: [textNode2])
        let paragraph = ElementNode(name: "p", attributes: [], children: [textNode1, boldNode, textNode3])
        
        let textToInsert = "---"
        
        paragraph.insert(textToInsert, atNodeIndex: 3)
        
        XCTAssertEqual(paragraph.children.count, 3)
        
        guard let textNode = paragraph.children[2] as? TextNode, textNode.text() == "\(adjacentText)\(textToInsert)" else {
                XCTFail("Expected a text node here with the inserted text.")
                return
        }
        
        XCTAssertEqual(paragraph.children[0], textNode1)
        XCTAssertEqual(paragraph.children[1], boldNode)
    }

    // MARK: - replaceCharactersInRange

    /// Tests `replaceCharacters(inRange:withNode)`.
    ///
    /// Input HTML: `<p>Look at this photo:image.It's amazing</p>`
    /// - Range: the range of the image string.
    /// - New Node: <img>
    /// - Attributes:
    ///
    /// Expected results:
    /// - Output: `<p>Look at this photo:<img src="https://httpbin.org/image/jpeg.It's amazing" /></p>`
    ///
    func testReplaceCharactersInRangeWithNode() {
        let startText = "Look at this photo:"
        let middleText = "image"
        let endText = ".It's amazing"
        let paragraphText = TextNode(text: startText + middleText + endText)
        let paragraph = ElementNode(name: "p", attributes: [], children: [paragraphText])

        let range = NSRange(location: startText.characters.count, length: middleText.characters.count)
        let imgSrc = "https://httpbin.org/image/jpeg"

        let attributes = [Libxml2.StringAttribute(name: "src", value: imgSrc)]
        let descriptor = ElementNodeDescriptor(elementType: .img, attributes: attributes)
        let node = ElementNode(descriptor: descriptor)

        paragraph.replaceCharacters(in: range, with: node)

        XCTAssertEqual(paragraph.children.count, 3)

        guard let startNode = paragraph.children[0] as? TextNode, startNode.text() == startText else {

            XCTFail("Expected a text node")
            return
        }

        guard let imgNode = paragraph.children[1] as? ElementNode, imgNode.name == node.name else {

            XCTFail("Expected a img node")
            return
        }

        guard let endNode = paragraph.children[2] as? TextNode, endNode.text() == endText else {

            XCTFail("Expected a text node")
            return
        }
    }

    // MARK: - pushUp(rightSideDescendantEvaluatedBy:)
    
    
    /// Tests that `pushUp(leftSideDescendantEvaluatedBy:)` works.
    ///
    /// Push the node named "b" up to the level of the "strike" node.
    ///
    /// Input HTML: `<p><strike><b>Hello </b>there!<strike></p>`
    /// - Evaluation criteria: node.name == "b"
    ///
    /// Expected results:
    /// - Output: `<p><b><strike>Hello </strike></b><strike>there!</strike></p>`
    ///
    func testPushUpLeftSideDescendant() {
        
        let text1 = TextNode(text: "Hello ")
        let text2 = TextNode(text: "there!")
        let bold = ElementNode(name: "b", attributes: [], children: [text1])
        let strike = ElementNode(name: "strike", attributes: [], children: [bold, text2])
        let paragraph = ElementNode(name: "p", attributes: [], children: [strike])
        
        let result = strike.pushUp(leftSideDescendantEvaluatedBy: { node -> Bool in
            return node.name == "b"
        })
        
        XCTAssertEqual(paragraph.children.count, 2)
        
        guard let outBold = paragraph.children[0] as? ElementNode, outBold.name == "b" else {
                XCTFail("Expected a bold node here.")
                return
        }
        
        XCTAssertEqual(result, outBold)
        XCTAssertEqual(outBold.text(), text1.text())
        XCTAssertEqual(outBold.children.count, 1)
        
        guard let outStrike2 = outBold.children[0] as? ElementNode, outStrike2.name == "strike" else {
                XCTFail("Expected a strike node.")
                return
        }
        
        guard let outStrike1 = paragraph.children[1] as? ElementNode, outStrike1.name == "strike" else {
                XCTFail("Expected a strike node.")
                return
        }
        
        XCTAssertEqual(outStrike1.children.count, 1)
        XCTAssertEqual(outStrike1.children[0], text2)
    }
    
    /// Tests that `pushUp(leftSideDescendantEvaluatedBy:)` works.
    ///
    /// Should find no node to push up.
    ///
    /// Input HTML: `<p><strike><b>Hello </b>there!<strike></p>`
    /// - Evaluation criteria: node.name == "b"
    ///
    /// Expected results:
    /// - No node should be returned.
    ///
    func testPushUpLeftSideDescendantWithNilResult() {
        
        let text = TextNode(text: "Hello there!")
        let strike = ElementNode(name: "strike", attributes: [], children: [text])
        _ = ElementNode(name: "p", attributes: [], children: [strike])
        
        let result = strike.pushUp(leftSideDescendantEvaluatedBy: { node -> Bool in
            return node.name == "b"
        })
        
        XCTAssertNil(result)
    }
    
    /// Tests that `pushUp(rightSideDescendantEvaluatedBy:)` works.
    ///
    /// Push the node named "b" up to the level of the "strike" node.
    ///
    /// Input HTML: `<p><strike>Hello <b>there!</b></strike></p>`
    /// - Evaluation criteria: node.name == "b"
    ///
    /// Expected results:
    /// - Output: `<p><strike>Hello </strike><b><strike>there!</strike></b></p>`
    ///
    func testPushUpRightSideDescendant() {
        
        let text1 = TextNode(text: "Hello ")
        let text2 = TextNode(text: "there!")
        let bold = ElementNode(name: "b", attributes: [], children: [text2])
        let strike = ElementNode(name: "strike", attributes: [], children: [text1, bold])
        let paragraph = ElementNode(name: "p", attributes: [], children: [strike])
        
        let _ = strike.pushUp(rightSideDescendantEvaluatedBy: { node -> Bool in
            return node.name == "b"
        })
        
        XCTAssertEqual(paragraph.children.count, 2)
        
        guard let outStrike1 = paragraph.children[0] as? ElementNode, outStrike1.name == "strike" else {
                XCTFail("Expected a strike node.")
                return
        }
        
        XCTAssertEqual(outStrike1.children.count, 1)
        XCTAssertEqual(outStrike1.children[0], text1)
        
        guard let outBold = paragraph.children[1] as? ElementNode, outBold.name == "b" else {
                XCTFail("Expected a bold node here.")
                return
        }
        
        XCTAssertEqual(outBold.text(), text2.text())
        XCTAssertEqual(outBold.children.count, 1)
        
        guard let outStrike2 = outBold.children[0] as? ElementNode, outStrike2.name == "strike" else {
                XCTFail("Expected a strike node.")
                return
        }
    }
    
    /// Tests that `pushUp(rightSideDescendantEvaluatedBy:)` works.
    ///
    /// Should find no node to push up.
    ///
    /// Input HTML: `<p><strike>Hello there!<strike></p>`
    /// - Evaluation criteria: node.name == "b"
    ///
    /// Expected results:
    /// - No node should be returned.
    ///
    func testPushUpRightSideDescendantWithNilResult() {
        
        let text = TextNode(text: "Hello there!")
        let strike = ElementNode(name: "strike", attributes: [], children: [text])
        let _ = ElementNode(name: "p", attributes: [], children: [strike])
        
        let result = strike.pushUp(rightSideDescendantEvaluatedBy: { node -> Bool in
            return node.name == "b"
        })
        
        XCTAssertNil(result)
    }
    
    // MARK: - Undo Support
    
    /// Test that removing a child can be undone perfectly.
    ///
    /// Input:
    /// - HTML: `<p>Hello <b>world!</b></p>`
    /// - Child to remove: the bold tag
    ///
    /// Expected results:
    /// - After undoing the operation, the whole DOM shoud be back to normal.
    ///
    func testUndoRemoveChild() {
        
        let undoManager = UndoManager()
        
        undoManager.disableUndoRegistration()
        
        let textNode1 = TextNode(text: "Hello ")
        let textNode2 = TextNode(text: "world!")
        let boldNode = ElementNode(name: StandardElementType.b.rawValue, attributes: [], children: [textNode2])
        let paragraph = ElementNode(name: StandardElementType.p.rawValue, attributes: [], children: [textNode1, boldNode])
        
        undoManager.enableUndoRegistration()
        
        XCTAssertEqual(paragraph.children.count, 2)
        XCTAssertEqual(paragraph.children[0], textNode1)
        XCTAssertEqual(paragraph.children[1], boldNode)
        XCTAssertEqual(textNode1.parent, paragraph)
        XCTAssertEqual(boldNode.parent, paragraph)
        
        paragraph.remove(boldNode)
        
        XCTAssertEqual(paragraph.children.count, 1)
        XCTAssertEqual(paragraph.children[0], textNode1)
        XCTAssertEqual(textNode1.parent, paragraph)
        XCTAssertNil(boldNode.parent)
        
        undoManager.undo()
        
        XCTAssertEqual(paragraph.children.count, 2)
        XCTAssertEqual(paragraph.children[0], textNode1)
        XCTAssertEqual(paragraph.children[1], boldNode)
        XCTAssertEqual(textNode1.parent, paragraph)
        XCTAssertEqual(boldNode.parent, paragraph)
    }
    
    
    /// Test that removing a children can be undone perfectly.
    ///
    /// Input:
    /// - HTML: `<p>Hello <b>world!</b><em>How are you?</em></p>`
    /// - Children to remove: the bold and em tags
    ///
    /// Expected results:
    /// - After undoing the operation, the whole DOM shoud be back to normal.
    ///
    func testUndoRemoveChildren() {
        
        let undoManager = UndoManager()
        
        undoManager.disableUndoRegistration()
        
        let textNode1 = TextNode(text: "Hello ")
        let textNode2 = TextNode(text: "world!")
        let textNode3 = TextNode(text: "How are you?")
        let boldNode = ElementNode(name: StandardElementType.b.rawValue, attributes: [], children: [textNode2])
        let emNode = ElementNode(name: StandardElementType.em.rawValue, attributes: [], children: [textNode3])
        let paragraph = ElementNode(name: StandardElementType.p.rawValue, attributes: [], children: [textNode1, boldNode, emNode])
        
        undoManager.enableUndoRegistration()
        
        XCTAssertEqual(paragraph.children.count, 3)
        XCTAssertEqual(paragraph.children[0], textNode1)
        XCTAssertEqual(paragraph.children[1], boldNode)
        XCTAssertEqual(paragraph.children[2], emNode)
        XCTAssertEqual(textNode1.parent, paragraph)
        XCTAssertEqual(boldNode.parent, paragraph)
        XCTAssertEqual(emNode.parent, paragraph)
        
        paragraph.remove([boldNode, emNode])
        
        XCTAssertEqual(paragraph.children.count, 1)
        XCTAssertEqual(paragraph.children[0], textNode1)
        XCTAssertEqual(textNode1.parent, paragraph)
        XCTAssertNil(boldNode.parent)
        XCTAssertNil(emNode.parent)
        
        undoManager.undo()
        
        XCTAssertEqual(paragraph.children.count, 3)
        XCTAssertEqual(paragraph.children[0], textNode1)
        XCTAssertEqual(paragraph.children[1], boldNode)
        XCTAssertEqual(paragraph.children[2], emNode)
        XCTAssertEqual(textNode1.parent, paragraph)
        XCTAssertEqual(boldNode.parent, paragraph)
        XCTAssertEqual(emNode.parent, paragraph)
    }
}
