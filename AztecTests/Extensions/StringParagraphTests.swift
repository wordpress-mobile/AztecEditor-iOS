import XCTest
@testable import Aztec

class StringParagraphTests: XCTestCase {

    /// Verifies that isStartOfParagraph(at:) returns true on the first position of an empty string
    ///
    func testIsStartOfParagraphReturnsTrueOnEmptyStrings() {
        let sample = String()

        XCTAssertTrue(sample.isStartOfParagraph(at: sample.startIndex))
    }

    /// Verifies that isStartOfParagraph(at:) returns true when checked against the first position
    ///
    func testIsStartOfParagraphReturnsTrueAtTheBeginningOfNewParagraphs() {
        let sample = "Sample"

        XCTAssertTrue(sample.isStartOfParagraph(at: sample.startIndex))
    }

    /// Verifies that isStartOfParagraph(at:) returns false when checked against any position that is not the first one
    ///
    func testIsStartOfParagraphReturnsFalseAtAnyPositionThatIsNotTheFirstOne() {
        let sample = "Sample"

        for location in 1 ..< sample.count {
            let index = sample.indexFromLocation(location)!
            XCTAssertFalse(sample.isStartOfParagraph(at: index))
        }
    }

    /// Verifies that isEndOfParagraph(before:) returns false when checked against a Line Separator character
    /// (which effectively adds a new paragraph)
    ///
    func testIsEndOfParagraphReturnsTrueWheneverTestStringEndsWithCarriageReturn() {
        let sample = "Sample" + String(.carriageReturn)

        XCTAssertTrue(sample.isEndOfParagraph(before: sample.endIndex))
    }

    /// Verifies that isEndOfParagraph(before:) returns false when checked against a Line Separator character
    /// (which effectively adds a newline that belongs to the current paragraph)
    ///
    func testIsEndOfParagraphReturnsFalseWheneverTestStringEndsWithLineSeparator() {
        let sample = "Sample" + String(.lineSeparator)

        XCTAssertFalse(sample.isEndOfParagraph(before: sample.endIndex))
    }

    /// Verifies that isEndOfParagraph(at:) does not crash on empty strings
    ///
    func testIsEndOfParagraphDoesNotCrashOnEmptyStrings() {
        let sample = String()

        XCTAssertNoThrow(sample.isEndOfParagraph(at: sample.endIndex))
    }

    /// Verifies that isEmptyParagraph(at:) does not crash on empty strings
    ///
    func testIsEmptyParagraphDoesNotCrashOnEmptyStrings() {
        let sample = String()

        XCTAssertNoThrow(sample.isEmptyParagraph(at: sample.endIndex))
    }

    /// Verifies that isEmptyParagraph(at:) returns false on any position that does not belong to an empty paragraph.
    ///
    func testIsEmptyParagraphReturnsFalseOnNonEmptyParagraphs() {
        let sample = "Sample"

        for i in 0 ..< sample.count {
            XCTAssertFalse(sample.isEmptyParagraph(at: i))
        }
    }

    /// Verifies that isEmptyParagraph(at:) returns false on empty lines that DO belong to the previous paragraph.
    ///
    func testIsEmptyParagraphReturnsFalseOnEmptyLinesThatBelongToABiggerParagraph() {
        let sample = "Sample" + String(.lineSeparator)

        XCTAssertFalse(sample.isEmptyParagraph(at: sample.count - 1))
    }

    /// Verifies that isEmptyParagraph(at:) returns true on empty lines, that do not belong to the previous paragraph.
    ///
    func testIsEmptyParagraphReturnsTrueOnEmptyLinesThatDoNotBelongToABiggerParagraph() {
        let sample = "Sample" + String(.lineFeed)

        XCTAssertTrue(sample.isEmptyParagraph(at: sample.count))
    }
}
