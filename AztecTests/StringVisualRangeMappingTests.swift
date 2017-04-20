import XCTest
@testable import Aztec

class StringVisualRangeMappingTests: XCTestCase {

    // MARK: - Single visual-only character: full range

    /// Maps the full range of a string (containing a single visual-only character) from visual to
    /// DOM.  The visual-only character is placed at the beginning of the string.
    ///
    func testMapFullUTF16VisualRangeWithParagraphSeparator1() {
        let originalString = "\(String(.paragraphSeparator))Hello World!"
        let domString = originalString.replacingOccurrences(of: String(.paragraphSeparator), with: "")

        let stringDefiningFinalRange = "Hello World!"

        let rangeToMap = (originalString as NSString).range(of: originalString)
        let expectedResult = (domString as NSString).range(of: stringDefiningFinalRange)

        let mappedRange = originalString.map(visualRange: rangeToMap)
        XCTAssertEqual(mappedRange, expectedResult)
    }

    /// Maps the full range of a string (containing a single visual-only character) from visual to
    /// DOM.  The visual-only character is placed at the end of the string.
    ///
    func testMapFullUTF16VisualRangeWithParagraphSeparator2() {
        let originalString = "Hello World!\(String(.paragraphSeparator))"
        let domString = originalString.replacingOccurrences(of: String(.paragraphSeparator), with: "")

        let stringDefiningFinalRange = "Hello World!"

        let rangeToMap = (originalString as NSString).range(of: originalString)
        let expectedResult = (domString as NSString).range(of: stringDefiningFinalRange)

        let mappedRange = originalString.map(visualRange: rangeToMap)
        XCTAssertEqual(mappedRange, expectedResult)
    }

    /// Maps the full range of a string (containing a single visual-only character) from visual to
    /// DOM.  The visual-only character is placed in the middle of the string.
    ///
    func testMapFullUTF16VisualRangeWithParagraphSeparator3() {
        let originalString = "Hello\(String(.paragraphSeparator)) World!"
        let domString = originalString.replacingOccurrences(of: String(.paragraphSeparator), with: "")

        let stringDefiningFinalRange = "Hello World!"

        let rangeToMap = (originalString as NSString).range(of: originalString)
        let expectedResult = (domString as NSString).range(of: stringDefiningFinalRange)

        let mappedRange = originalString.map(visualRange: rangeToMap)
        XCTAssertEqual(mappedRange, expectedResult)
    }

    // MARK: - Single visual-only character: partial range

    /// Maps a partial range of a string (containing a single visual-only character) from visual to
    /// DOM.  The visual-only character is placed in the middle of the string.
    ///
    func testMapPartialUTF16VisualRangeWithParagraphSeparator1() {
        let originalString = "\(String(.paragraphSeparator))Hello World!"
        let domString = originalString.replacingOccurrences(of: String(.paragraphSeparator), with: "")

        let stringDefiningRangeToMap = "World!"

        let rangeToMap = (originalString as NSString).range(of: stringDefiningRangeToMap)
        let expectedResult = (domString as NSString).range(of: stringDefiningRangeToMap)

        let mappedRange = originalString.map(visualRange: rangeToMap)
        XCTAssertEqual(mappedRange, expectedResult)
    }

    /// Maps a partial range of a string (containing a single visual-only character) from visual to
    /// DOM.  The visual-only character is placed in the middle of the string.
    ///
    func testMapPartialUTF16VisualRangeWithParagraphSeparator2() {
        let originalString = "Hello World!\(String(.paragraphSeparator))"
        let domString = originalString.replacingOccurrences(of: String(.paragraphSeparator), with: "")

        let stringDefiningRangeToMap = "Hello"

        let rangeToMap = (originalString as NSString).range(of: stringDefiningRangeToMap)
        let expectedResult = (domString as NSString).range(of: stringDefiningRangeToMap)

        let mappedRange = originalString.map(visualRange: rangeToMap)
        XCTAssertEqual(mappedRange, expectedResult)
    }

    /// Maps a partial range of a string (containing a single visual-only character) from visual to
    /// DOM.  The visual-only character is placed in the middle of the string.
    ///
    func testMapPartialUTF16VisualRangeWithParagraphSeparator3() {
        let originalString = "Hello Wor\(String(.paragraphSeparator))ld!"
        let domString = originalString.replacingOccurrences(of: String(.paragraphSeparator), with: "")

        let stringDefiningRangeToMap = "Wor\(String(.paragraphSeparator))ld"
        let stringDefiningFinalRange = "World"

        let rangeToMap = (originalString as NSString).range(of: stringDefiningRangeToMap)
        let expectedResult = (domString as NSString).range(of: stringDefiningFinalRange)

        let mappedRange = originalString.map(visualRange: rangeToMap)
        XCTAssertEqual(mappedRange, expectedResult)
    }
}
