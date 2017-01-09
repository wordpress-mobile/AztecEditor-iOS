import XCTest
@testable import Aztec

class OutHTMLConverterTests: XCTestCase {

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

    func testSimpleNodeConversion() {
        let inParser = Libxml2.In.HTMLConverter()
        let outParser = Libxml2.Out.HTMLConverter()

        let html = "<bold><i>Hello!</i></bold>"

        do {
            let inNode = try inParser.convert(html)
            let outHtml = outParser.convert(inNode)
            
            XCTAssertEqual(outHtml, html)
        } catch {
            XCTFail("Unexpected conversion failure.")
        }
    }

    func testCommentNodeConversion() {
        let inParser = Libxml2.In.HTMLConverter()
        let outParser = Libxml2.Out.HTMLConverter()

        let html = "<!--Hello Sample--><bold><i>Hello!</i></bold>"

        do {
            let inNode = try inParser.convert(html)
            let outHtml = outParser.convert(inNode)

            XCTAssertEqual(outHtml, html)
        } catch {
            XCTFail("Unexpected conversion failure.")
        }
    }

}
