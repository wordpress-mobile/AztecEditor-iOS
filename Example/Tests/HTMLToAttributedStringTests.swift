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

    func testSimpleTagToStringConversion() {

        let tagNames = ["bold", "italic", "customTag", "div", "p", "a"]

        for (index, tagName) in tagNames.enumerate() {
            let parser = HTMLToAttributedString()

            let html = "<\(tagName)>Hello</\(tagName)>"
            let htmlData = html.dataUsingEncoding(NSUTF8StringEncoding)!

            do {
                let string = try parser.convert(htmlData)

                guard let firstTag = string.firstTag(forRange: NSRange(location: 0, length: string.length)) else {
                    XCTFail("Expected to find the first tag.")
                    return
                }

                XCTAssert(firstTag.previous == nil)
                XCTAssert(firstTag.name == tagNames[index].lowercaseString)
                XCTAssert(firstTag.next == nil)
            } catch {
                XCTFail("Unexpected conversion failure.")
            }
        }
    }

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

                guard let firstTag = string.firstTag(forRange: NSRange(location: 0, length: string.length)) else {
                    XCTFail("Expected to find the first tag.")
                    return
                }

                guard let secondTag = firstTag.next else {
                    XCTFail("Expected to find the second tag.")
                    return
                }

                XCTAssert(firstTag.previous == nil)
                XCTAssert(firstTag.name == tagNames[index].0.lowercaseString)
                XCTAssert(secondTag.name == tagNames[index].1.lowercaseString)
                XCTAssert(secondTag.next == nil)
            } catch {
                XCTFail("Unexpected conversion failure.")
            }
        }
    }
}
