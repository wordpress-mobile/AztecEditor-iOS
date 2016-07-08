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

    func testSimpleBoldStringConversion() {
        let parser = HTMLToAttributedString()

        let html = "<bold>Hello</bold>"
        let htmlData = html.dataUsingEncoding(NSUTF8StringEncoding)!

        do {
            let string = try parser.convert(htmlData)
            let attributes = string.attributesAtIndex(0, effectiveRange: nil)

            XCTAssert(attributes.count == 1 && attributes.keys.contains("HTMLTag"))

            guard let boldAttribute = attributes[HTMLTagStringAttribute.key] as? HTMLTagStringAttribute else {
                XCTFail("No bold string attribute found.")
                return
            }

            XCTAssert(boldAttribute.name == "bold")
        } catch {
            XCTFail("Unexpected conversion failure.")
        }
    }
}
