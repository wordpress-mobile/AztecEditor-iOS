import XCTest
@testable import Aztec


// MARK: - OutHTMLConverterTests
//
class OutHTMLConverterTests: XCTestCase {

    typealias InConverter   = Libxml2.In.HTMLConverter
    typealias OutConverter  = Libxml2.Out.HTMLConverter


    /// Verifies that single level lists gets properly prettified and indented.
    ///
    func testConverterProperlyIndentsSingleLevelList() {
        let sample = "<ul><li>Item</li><li>Item</li></ul>"
        let expected = "<ul>\n  <li>Item</li>\n  <li>Item</li>\n</ul>"

        do {
            let inNode = try InConverter().convert(sample)
            let outHtml = OutConverter(prettyPrint: true).convert(inNode)

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
            let inNode = try InConverter().convert(sample)
            let outHtml = OutConverter(prettyPrint: true).convert(inNode)

            XCTAssertEqual(outHtml, expected)
        } catch {
            XCTFail("Unexpected conversion failure.")
        }
    }


    /// Verifies that Blocklevel Elements get a tailing newline
    ///
    func testConverterProperlyAddsNewlineAfterBlocklevelElement() {
        let sample = "<h1>Header</h1>Tail"
        let expected = "<h1>Header</h1>\nTail"

        do {
            let inNode = try InConverter().convert(sample)
            let outHtml = OutConverter(prettyPrint: true).convert(inNode)

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
            let inNode = try InConverter().convert(sample)
            let outHtml = OutConverter(prettyPrint: true).convert(inNode)

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
            let inNode = try InConverter().convert(sample)
            let outHtml = OutConverter(prettyPrint: true).convert(inNode)

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
            let inNode = try InConverter().convert(sample)
            let outHtml = OutConverter().convert(inNode)

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
            let inNode = try InConverter().convert(html)
            let outHtml = OutConverter().convert(inNode)

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
            let inNode = try InConverter().convert(html)
            let outHtml = OutConverter().convert(inNode)

            XCTAssertEqual(outHtml, html)
        } catch {
            XCTFail("Unexpected conversion failure.")
        }
    }
}
