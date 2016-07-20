import XCTest
@testable import Aztec

class HTMLToAttributedStringTests: XCTestCase {

    typealias ElementNode = Libxml2.HTML.ElementNode
    typealias TextNode = Libxml2.HTML.TextNode

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    /// Test the conversion of a single tag at the root level to `NSAttributedString`.
    ///
    /// Example: <bold>Hello</bold>
    ///
    func testSimpleTagToStringConversion() {

        let tagNames = ["bold", "italic", "customTag", "div", "p", "a"]

        for (index, tagName) in tagNames.enumerate() {
            let parser = HTMLToAttributedString()

            let nodeText = "Hello"
            let html = "<\(tagName)>\(nodeText)</\(tagName)>"

            do {
                let string = try parser.convert(html)

                let rootNode = string.rootNode()

                guard rootNode.children.count == 1,
                    let mainNode = rootNode.children[0] as? ElementNode else {

                    XCTFail("Expected to find the first node.")
                    return
                }

                XCTAssert(mainNode.parent == rootNode)
                XCTAssert(mainNode.name == tagNames[index].lowercaseString)

                guard mainNode.children.count == 1,
                    let textNode = mainNode.children[0] as? TextNode else {

                    XCTFail("Expected to find the text node.")
                    return
                }

                XCTAssertEqual(textNode.text, nodeText)

            } catch {
                XCTFail("Unexpected conversion failure.")
            }
        }
    }

    /// Test the conversion of a single tag at a non-root level to `NSAttributedString`.
    ///
    /// Example: Hello <italic>world</italic>!
    ///
    func testSimpleTagAtNonRootLevelToStringConversion() {

        let tagNames = ["bold", "italic", "customTag", "div", "p", "a"]

        for (index, tagName) in tagNames.enumerate() {
            let parser = HTMLToAttributedString()

            let firstText = "Hello "
            let secondText = "world"
            let thirdText = "!"
            let html = "\(firstText)<\(tagName)>\(secondText)</\(tagName)>\(thirdText)"

            do {
                let string = try parser.convert(html)

                let rootNode = string.rootNode()

                guard rootNode.children.count == 3,
                    let firstTextNode = rootNode.children[0] as? TextNode,
                    let elementNode = rootNode.children[1] as? ElementNode,
                    let thirdTextNode = rootNode.children[2] as? TextNode else {

                        XCTFail("Expected to find the main paragraph child nodes.")
                        return
                }
                
                XCTAssertEqual(firstTextNode.text, firstText)
                XCTAssertEqual(elementNode.name, tagNames[index].lowercaseString)
                XCTAssertEqual(thirdTextNode.text, thirdText)

                guard elementNode.children.count == 1,
                    let secondTextNode = elementNode.children[0] as? TextNode else {

                    XCTFail("Expected to find the secondary text node.")
                    return
                }

                XCTAssertEqual(secondTextNode.text, secondText)

                /*
                let string = try parser.convert(htmlData)

                guard let firstTag = string.firstTag(insideRange: NSRange(location: 0, length: string.length)) else {
                    XCTFail("Expected to find the first tag.")
                    return
                }

                XCTAssert(firstTag.parent == nil)
                XCTAssert(firstTag.name == tagNames[index].lowercaseString)
                XCTAssert(firstTag.child == nil)
                 */
            } catch {
                XCTFail("Unexpected conversion failure.")
            }
        }
    }
/*
    /// Test the conversion of double tags at the root level to `NSAttributedString`.
    ///
    /// Example: <bold><italic>Hello</italic></bold>
    ///
    func testDoubleTagToStringConversion() {

        let tagNames = [("bold", "italic"),
                        ("italic", "customTag"),
                        ("customTag", "div"),
                        ("div", "p"),
                        ("p", "a"),
                        ("a", "bold")]

        for (index, tagName) in tagNames.enumerate() {
            let parser = HTMLToAttributedString()

            let html = "<\(tagName.0)><\(tagName.1)>Hello</\(tagName.1)></\(tagName.0)>"
            let htmlData = html.dataUsingEncoding(NSUTF8StringEncoding)!

            do {
                let string = try parser.convert(htmlData)

                guard let firstTag = string.firstTag(matchingRange: NSRange(location: 0, length: string.length)) else {
                    XCTFail("Expected to find the first tag.")
                    return
                }

                guard let secondTag = firstTag.child else {
                    XCTFail("Expected to find the second tag.")
                    return
                }

                XCTAssert(firstTag.parent == nil)
                XCTAssert(firstTag.name == tagNames[index].0.lowercaseString)
                XCTAssert(secondTag.name == tagNames[index].1.lowercaseString)
                XCTAssert(secondTag.child == nil)
            } catch {
                XCTFail("Unexpected conversion failure.")
            }
        }
    }


    /// Test the conversion of double tags at different levels to `NSAttributedString`.
    ///
    /// Example: <bold>Hello <italic>world</italic>!</bold>
    ///
    func testDoubleTagAtDifferentLevelsToStringConversion() {

        let tagNames = [("bold", "italic"),
                        ("italic", "customTag"),
                        ("customTag", "div"),
                        ("div", "p"),
                        ("p", "a"),
                        ("a", "bold")]

        for (index, tagName) in tagNames.enumerate() {
            let parser = HTMLToAttributedString()

            let html = "<\(tagName.0)>Hello <\(tagName.1)>world</\(tagName.1)>!</\(tagName.0)>"
            let htmlData = html.dataUsingEncoding(NSUTF8StringEncoding)!

            do {
                let string = try parser.convert(htmlData)

                guard let firstTag = string.firstTag(matchingRange: NSRange(location: 0, length: string.length)) else {
                    XCTFail("Expected to find the first tag.")
                    return
                }

                XCTAssert(firstTag.parent == nil)
                XCTAssert(firstTag.name == tagNames[index].0.lowercaseString)
                XCTAssert(firstTag.child == nil)

                guard let secondTag = string.firstTag(insideRange: NSRange(location: 0, length: string.length)) else {
                    XCTFail("Expected to find the second tag.")
                    return
                }

                XCTAssert(secondTag.parent == nil)
                XCTAssert(secondTag.name == tagNames[index].1.lowercaseString)
                XCTAssert(secondTag.child == nil)
            } catch {
                XCTFail("Unexpected conversion failure.")
            }
        }
    }


    /// Test the conversion of a single tag at root level, and double tags at child level to
    /// `NSAttributedString`.
    ///
    /// Example: <bold>Hello <italic><strong>world</strong></italic>!</bold>
    ///
    func testSingleTagAtRootLevelAndDoubleChildTagsToStringConversion() {

        let tagNames = [("bold", "italic", "strong"),
                        ("italic", "strong", "customTag"),
                        ("strong", "customTag", "div"),
                        ("customTag", "div", "p"),
                        ("div", "p", "a"),
                        ("p", "a", "bold"),
                        ("a", "bold", "italic")]

        for (index, tagName) in tagNames.enumerate() {
            let parser = HTMLToAttributedString()

            let html = "<\(tagName.0)>Hello <\(tagName.1)><\(tagName.2)>world</\(tagName.2)></\(tagName.1)>!</\(tagName.0)>"
            let htmlData = html.dataUsingEncoding(NSUTF8StringEncoding)!

            do {
                let string = try parser.convert(htmlData)

                guard let firstTag = string.firstTag(matchingRange: NSRange(location: 0, length: string.length)) else {
                    XCTFail("Expected to find the first tag.")
                    return
                }

                XCTAssert(firstTag.parent == nil)
                XCTAssert(firstTag.name == tagNames[index].0.lowercaseString)
                XCTAssert(firstTag.child == nil)

                guard let secondTag = string.firstTag(insideRange: NSRange(location: 0, length: string.length)) else {
                    XCTFail("Expected to find the second tag.")
                    return
                }

                guard let thirdTag = secondTag.child else {
                    XCTFail("Expected to find the second tag.")
                    return
                }

                XCTAssert(secondTag.parent == nil)
                XCTAssert(secondTag.name == tagNames[index].1.lowercaseString)
                XCTAssert(thirdTag.name == tagNames[index].2.lowercaseString)
                XCTAssert(thirdTag.child == nil)
            } catch {
                XCTFail("Unexpected conversion failure.")
            }
        }
    }
 */
}
