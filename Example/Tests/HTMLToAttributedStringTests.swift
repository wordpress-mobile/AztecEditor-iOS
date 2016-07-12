import XCTest
@testable import Aztec

class HTMLToAttributedStringTests: XCTestCase {

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
    /// Example: <bold><italic>Hello</italic></bold>
    ///
    func testSimpleTagToStringConversion() {

        let tagNames = ["bold", "italic", "customTag", "div", "p", "a"]

        for (index, tagName) in tagNames.enumerate() {
            let parser = HTMLToAttributedString()

            let html = "<\(tagName)>Hello</\(tagName)>"
            let htmlData = html.dataUsingEncoding(NSUTF8StringEncoding)!

            do {
                let string = try parser.convert(htmlData)

                guard let firstTag = string.firstTag(matchingRange: NSRange(location: 0, length: string.length)) else {
                    XCTFail("Expected to find the first tag.")
                    return
                }

                XCTAssert(firstTag.parent == nil)
                XCTAssert(firstTag.name == tagNames[index].lowercaseString)
                XCTAssert(firstTag.child == nil)
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
}
