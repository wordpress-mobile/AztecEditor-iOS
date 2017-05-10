import XCTest
@testable import Aztec


// MARK: - OutHTMLPrettyConverterTests
//
class OutHTMLPrettyConverterTests: XCTestCase {

    let inputConverter = Libxml2.In.HTMLConverter()
    let outputConverter = Libxml2.Out.HTMLPrettyConverter()

    ///
    ///
    func testPrettifyUnclosedTagDoesNotCauseDataLoss() {
        let sample = "<ul><li>Item</li><li>Item</li></ul>"
        let expected = "<ul>\n  <li>Item</li>\n  <li>Item</li>\n</ul>"

        let node = try! inputConverter.convert(sample)

        outputConverter.prettyPrintEnabled = true
        XCTAssertEqual(outputConverter.convert(node), expected)
    }

    ///
    ///
    func testPrettifyDoesNotDropUnknownTags() {
        let sample = "something something <something>"
        let expected = "something something <something></something>"

        let node = try! inputConverter.convert(sample)

        outputConverter.prettyPrintEnabled = true
        XCTAssertEqual(outputConverter.convert(node), expected)
    }

    ///
    ///
    func testPrettifyDoesNotDropProprietaryAttributes() {
        let sample = "something something <img unknown=\"true\">"
        let expected =  "something something <img unknown=\"true\">"

        let node = try! inputConverter.convert(sample)

        outputConverter.prettyPrintEnabled = true
        XCTAssertEqual(outputConverter.convert(node), expected)
    }

    ///
    ///
    func testPrettifyDoesNotAttemptToCloseUnclosedTags() {
        let sample = "<h1><i>italic heading</h1>"
        let expected = "<h1><i>italic heading</i></h1>"

        let node = try! inputConverter.convert(sample)

        outputConverter.prettyPrintEnabled = true
        XCTAssertEqual(outputConverter.convert(node), expected)
    }
}
