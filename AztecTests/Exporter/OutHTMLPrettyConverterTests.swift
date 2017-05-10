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

    /// Verifies that single level lists gets properly prettified and indented.
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

    /// Verifies that multilevel lists gets properly prettified and indented.
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


    /// Verifies that unknown tags do not get dropped, and closed, if needed.
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

    /// Verifies that unknown TAG Attributes do not get removed.
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

    /// Verifies that closing tags get added, when originally missing.
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

    /// Verifies that simple HTML gets exported, exactly the way it was initially imported.
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

    /// Verifies that Comment HTML does not get lost during I/O Conversions.
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
