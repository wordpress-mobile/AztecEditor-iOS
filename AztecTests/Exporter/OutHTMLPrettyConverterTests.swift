import XCTest
@testable import Aztec


// MARK: - OutHTMLPrettyConverterTests
//
class OutHTMLPrettyConverterTests: XCTestCase {

    let inputConverter = Libxml2.In.HTMLConverter()
    let outputConverter = Libxml2.Out.HTMLPrettyConverter()


    override func setUp() {
        super.setUp()
        outputConverter.prettyPrintEnabled = false
    }

    ///
    ///
    func testConverterProperlyIndentsSingleLevelList() {
        let sample = "<ul><li>Item</li><li>Item</li></ul>"
        let expected = "<ul>\n  <li>Item</li>\n  <li>Item</li>\n</ul>"

        do {
            outputConverter.prettyPrintEnabled = true

            let inNode = try inputConverter.convert(sample)
            let outHtml = outputConverter.convert(inNode)

            XCTAssertEqual(outHtml, expected)
        } catch {
            XCTFail("Unexpected conversion failure.")
        }
    }

    ///
    ///
    func testConverterProperlyIndentsMultilevelList() {
        let sample = "<ul><li><ol><li>Nested 1</li><li>Nested 2</li></ol></li><li>Regular</li></ul>"
        let expected = "<ul>\n  <li>\n    <ol>\n      <li>Nested 1</li>\n      <li>Nested 2</li>\n    </ol>\n  </li>\n  <li>Regular</li>\n</ul>"

        do {
            outputConverter.prettyPrintEnabled = true

            let inNode = try inputConverter.convert(sample)
            let outHtml = outputConverter.convert(inNode)

            XCTAssertEqual(outHtml, expected)
        } catch {
            XCTFail("Unexpected conversion failure.")
        }
    }


    ///
    ///
    func testConverterDoesNotDropUnknownTags() {
        let sample = "something something <something>"
        let expected = "something something <something></something>"

        do {
            outputConverter.prettyPrintEnabled = true

            let inNode = try inputConverter.convert(sample)
            let outHtml = outputConverter.convert(inNode)

            XCTAssertEqual(outHtml, expected)
        } catch {
            XCTFail("Unexpected conversion failure.")
        }
    }

    ///
    ///
    func testConverterDoesNotDropProprietaryAttributes() {
        let sample = "something something <img unknown=\"true\">"
        let expected =  "something something <img unknown=\"true\">"

        do {
            outputConverter.prettyPrintEnabled = true

            let inNode = try inputConverter.convert(sample)
            let outHtml = outputConverter.convert(inNode)

            XCTAssertEqual(outHtml, expected)
        } catch {
            XCTFail("Unexpected conversion failure.")
        }
    }

    ///
    ///
    func testConverterAddsClosingTagWhenMissing() {
        let sample = "<h1><i>italic heading</h1>"
        let expected = "<h1><i>italic heading</i></h1>"

        do {
            let inNode = try inputConverter.convert(sample)
            let outHtml = outputConverter.convert(inNode)

            XCTAssertEqual(outHtml, expected)
        } catch {
            XCTFail("Unexpected conversion failure.")
        }
    }

    ///
    ///
    func testConverterProperlySerializesImportedHtml() {
        let html = "<bold><i>Hello!</i></bold>"

        do {
            let inNode = try inputConverter.convert(html)
            let outHtml = outputConverter.convert(inNode)

            XCTAssertEqual(outHtml, html)
        } catch {
            XCTFail("Unexpected conversion failure.")
        }
    }

    ///
    ///
    func testConverterProperlySerializesImportedHtmlWithComments() {
        let html = "<!--Hello Sample--><bold><i>Hello!</i></bold>"

        do {
            let inNode = try inputConverter.convert(html)
            let outHtml = outputConverter.convert(inNode)

            XCTAssertEqual(outHtml, html)
        } catch {
            XCTFail("Unexpected conversion failure.")
        }
    }
}
