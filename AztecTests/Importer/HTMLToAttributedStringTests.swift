import XCTest
@testable import Aztec

class HTMLToAttributedStringTests: XCTestCase {

    typealias ElementNode = Libxml2.ElementNode
    typealias RootNode = Libxml2.RootNode
    typealias TextNode = Libxml2.TextNode

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

        for (index, tagName) in tagNames.enumerated() {
            let parser = HTMLToAttributedString(usingDefaultFontDescriptor: UIFont.systemFont(ofSize: 12).fontDescriptor, registerUndo: { _ in })

            let nodeText = "Hello"
            let html = "<\(tagName)>\(nodeText)</\(tagName)>"

            do {
                let output = try parser.convert(html)

                let rootNode = output.rootNode

                guard rootNode.children.count == 1,
                    let mainNode = rootNode.children[0] as? ElementNode else {

                    XCTFail("Expected to find the first node.")
                    return
                }

                XCTAssert(mainNode.parent == rootNode)
                XCTAssert(mainNode.name == tagNames[index].lowercased())

                guard mainNode.children.count == 1,
                    let textNode = mainNode.children[0] as? TextNode else {

                    XCTFail("Expected to find the text node.")
                    return
                }

                XCTAssertEqual(textNode.text(), nodeText)

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

        for (index, tagName) in tagNames.enumerated() {
            let parser = HTMLToAttributedString(usingDefaultFontDescriptor: UIFont.systemFont(ofSize: 12).fontDescriptor, registerUndo: { _ in })

            let firstText = "Hello "
            let secondText = "world"
            let thirdText = "!"
            let html = "\(firstText)<\(tagName)>\(secondText)</\(tagName)>\(thirdText)"

            do {
                let output = try parser.convert(html)

                let rootNode = output.rootNode

                guard rootNode.children.count == 3,
                    let firstTextNode = rootNode.children[0] as? TextNode,
                    let elementNode = rootNode.children[1] as? ElementNode,
                    let thirdTextNode = rootNode.children[2] as? TextNode else {

                        XCTFail("Expected to find the main paragraph child nodes.")
                        return
                }
                
                XCTAssertEqual(firstTextNode.text(), firstText)
                XCTAssertEqual(elementNode.name, tagNames[index].lowercased())
                XCTAssertEqual(thirdTextNode.text(), thirdText)

                guard elementNode.children.count == 1,
                    let secondTextNode = elementNode.children[0] as? TextNode else {

                    XCTFail("Expected to find the secondary text node.")
                    return
                }

                XCTAssertEqual(secondTextNode.text(), secondText)
            } catch {
                XCTFail("Unexpected conversion failure.")
            }
        }
    }

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

        for (index, tagName) in tagNames.enumerated() {
            let parser = HTMLToAttributedString(usingDefaultFontDescriptor: UIFont.systemFont(ofSize: 12).fontDescriptor, registerUndo: { _ in })

            let text = "Hello"
            let html = "<\(tagName.0)><\(tagName.1)>\(text)</\(tagName.1)></\(tagName.0)>"

            do {
                let output = try parser.convert(html)

                let rootNode = output.rootNode

                XCTAssertEqual(rootNode.name, RootNode.name)
                XCTAssertEqual(rootNode.children.count, 1)

                guard let firstNode = rootNode.children[0] as? ElementNode else {
                    XCTFail("Expected to find the first node.")
                    return
                }

                XCTAssertEqual(firstNode.parent, rootNode)
                XCTAssertEqual(firstNode.name, tagNames[index].0.lowercased())
                XCTAssertEqual(firstNode.children.count, 1)

                guard let secondNode = firstNode.children[0] as? ElementNode else {
                    XCTFail("Expected to find the second node.")
                    return
                }

                XCTAssertEqual(secondNode.parent, firstNode)
                XCTAssertEqual(secondNode.name, tagNames[index].1.lowercased())
                XCTAssertEqual(secondNode.children.count, 1)

                guard let textNode = secondNode.children[0] as? TextNode else {
                    XCTFail("Expected to find the text node.")
                    return
                }

                XCTAssertEqual(textNode.parent, secondNode)

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

        for (index, tagName) in tagNames.enumerated() {
            let parser = HTMLToAttributedString(usingDefaultFontDescriptor: UIFont.systemFont(ofSize: 12).fontDescriptor, registerUndo: { _ in })

            let firstText = "Hello "
            let secondText = "world"
            let thirdText = "!"
            let html = "<\(tagName.0)>\(firstText)<\(tagName.1)>\(secondText)</\(tagName.1)>\(thirdText)</\(tagName.0)>"

            do {
                let output = try parser.convert(html)

                let rootNode = output.rootNode

                XCTAssertEqual(rootNode.name, RootNode.name)
                XCTAssertEqual(rootNode.children.count, 1)

                guard let firstNode = rootNode.children[0] as? ElementNode else {
                    XCTFail("Expected to find the first node.")
                    return
                }

                XCTAssertEqual(firstNode.parent, rootNode)
                XCTAssertEqual(firstNode.name, tagNames[index].0.lowercased())
                XCTAssertEqual(firstNode.children.count, 3)

                guard let firstTextNode = firstNode.children[0] as? TextNode else {
                    XCTFail("Expected to find the first text node.")
                    return
                }

                XCTAssertEqual(firstTextNode.parent, firstNode)
                XCTAssertEqual(firstTextNode.text(), firstText)

                guard let secondNode = firstNode.children[1] as? ElementNode else {
                    XCTFail("Expected to find the second node.")
                    return
                }

                XCTAssertEqual(secondNode.parent, firstNode)
                XCTAssertEqual(secondNode.name, tagNames[index].1.lowercased())
                XCTAssertEqual(secondNode.children.count, 1)

                guard let secondTextNode = secondNode.children[0] as? TextNode else {
                    XCTFail("Expected to find the second text node.")
                    return
                }

                XCTAssertEqual(secondTextNode.parent, secondNode)
                XCTAssertEqual(secondTextNode.text(), secondText)

                guard let thirdTextNode = firstNode.children[2] as? TextNode else {
                    XCTFail("Expected to find the third text node.")
                    return
                }

                XCTAssertEqual(thirdTextNode.parent, firstNode)
                XCTAssertEqual(thirdTextNode.text(), thirdText)

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

        for (index, tagName) in tagNames.enumerated() {
            let parser = HTMLToAttributedString(usingDefaultFontDescriptor: UIFont.systemFont(ofSize: 12).fontDescriptor, registerUndo: { _ in })

            let firstText = "Hello "
            let secondText = "world"
            let thirdText = "!"
            let html = "<\(tagName.0)>\(firstText)<\(tagName.1)><\(tagName.2)>\(secondText)</\(tagName.2)></\(tagName.1)>\(thirdText)</\(tagName.0)>"

            do {
                let output = try parser.convert(html)

                let rootNode = output.rootNode

                XCTAssertEqual(rootNode.name, RootNode.name)
                XCTAssertEqual(rootNode.children.count, 1)

                guard let firstNode = rootNode.children[0] as? ElementNode else {
                    XCTFail("Expected to find the first node.")
                    return
                }

                XCTAssertEqual(firstNode.parent, rootNode)
                XCTAssertEqual(firstNode.name, tagNames[index].0.lowercased())
                XCTAssertEqual(firstNode.children.count, 3)

                guard let firstTextNode = firstNode.children[0] as? TextNode else {
                    XCTFail("Expected to find the first text node.")
                    return
                }

                XCTAssertEqual(firstTextNode.parent, firstNode)
                XCTAssertEqual(firstTextNode.text(), firstText)

                guard let secondNode = firstNode.children[1] as? ElementNode else {
                    XCTFail("Expected to find the second node.")
                    return
                }

                XCTAssertEqual(secondNode.parent, firstNode)
                XCTAssertEqual(secondNode.name, tagNames[index].1.lowercased())
                XCTAssertEqual(secondNode.children.count, 1)

                guard let thirdNode = secondNode.children[0] as? ElementNode else {
                    XCTFail("Expected to find the third node.")
                    return
                }

                XCTAssertEqual(thirdNode.parent, secondNode)
                XCTAssertEqual(thirdNode.name, tagNames[index].2.lowercased())
                XCTAssertEqual(thirdNode.children.count, 1)

                guard let secondTextNode = thirdNode.children[0] as? TextNode else {
                    XCTFail("Expected to find the second text node.")
                    return
                }

                XCTAssertEqual(secondTextNode.parent, thirdNode)
                XCTAssertEqual(secondTextNode.text(), secondText)

                guard let thirdTextNode = firstNode.children[2] as? TextNode else {
                    XCTFail("Expected to find the third text node.")
                    return
                }
                
                XCTAssertEqual(thirdTextNode.parent, firstNode)
                XCTAssertEqual(thirdTextNode.text(), thirdText)
            } catch {
                XCTFail("Unexpected conversion failure.")
            }
        }
    }
}
