import XCTest
@testable import Aztec

class NSAttributedStringParagraphRangeTests: XCTestCase {
    
    /// Tests that `paragraphRanges(intersecting:includeParagraphSeparator:)` with a zero-length
    /// input paragraph range returns the correct substring paragraph range.
    ///
    func testParagraphRangesWithoutSeparatorWorksWithAZeroLengthInputRange() {
        let attributedString = NSAttributedString(string: "Paragraph 1\nParagraph 2\n")
        let range = NSRange(location: 0, length: 0)
        let expectedRange = NSRange(location: 0, length: 11)
        
        let ranges = attributedString.paragraphRanges(intersecting: range, includeParagraphSeparator: false)
        
        XCTAssertEqual(ranges.count, 1)
        XCTAssertEqual(ranges.first, expectedRange)
    }
    
    /// Tests that `paragraphRanges(intersecting:includeParagraphSeparator:)` with a zero-length
    /// input paragraph range returns the correct enclosing paragraph range.
    ///
    func testParagraphRangesWithSeparatorWorksWithAZeroLengthInputRange() {
        let attributedString = NSAttributedString(string: "Paragraph 1\nParagraph 2\n")
        let range = NSRange(location: 0, length: 0)
        let expectedRange = NSRange(location: 0, length: 12)
        
        let ranges = attributedString.paragraphRanges(intersecting: range, includeParagraphSeparator: true)
        
        XCTAssertEqual(ranges.count, 1)
        XCTAssertEqual(ranges.first, expectedRange)
    }
    
    /// Tests that `paragraphRanges(intersecting:)` with a zero-length input paragraph range
    /// returns the correct `ParagraphRange`.
    ///
    func testParagraphRangesWorksWithAZeroLengthInputRange() {
        let attributedString = NSAttributedString(string: "Paragraph 1\nParagraph 2\n")
        let range = NSRange(location: 0, length: 0)
        let expectedRangeWithoutSeparator = NSRange(location: 0, length: 11)
        let expectedRangeWithSeparator = NSRange(location: 0, length: 12)
        
        let ranges = attributedString.paragraphRanges(intersecting: range)
        
        XCTAssertEqual(ranges.count, 1)
        XCTAssertEqual(ranges.first?.rangeExcludingParagraphSeparator, expectedRangeWithoutSeparator)
        XCTAssertEqual(ranges.first?.rangeIncludingParagraphSeparator, expectedRangeWithSeparator)
    }

    /// Tests that `paragraphRange(for:)` with a paragraph separator character
    /// returns the correct `NSRange`.
    ///
    /// This test was added due to an iOS 17 crash when calling String.paragraphRange(for: range)
    /// on a single paragraph separator character.
    ///
    func testParagraphRangeWorkWithParagraphSeparator() {
        let attributedString = NSAttributedString(string: "\u{2029}")
        let range = NSRange(location: 0, length: 1)
        let expectedRange = NSRange(location: 0, length: 1)

        let paragraphRange = attributedString.paragraphRange(for: range)

        XCTAssertEqual(paragraphRange, expectedRange)
    }

    /// Tests that `paragraphRanges(intersecting:)` with a paragraph separator character
    /// returns the correct `[NSRange]`.
    ///
    /// This test was added due to an iOS 17 crash when calling String.paragraphRange(for: range)
    /// on a single paragraph separator character.
    ///
    func testParagraphRangesWorkWithParagraphSeparator() {
        let attributedString = NSAttributedString(string: "\u{2029}")
        let range = NSRange(location: 0, length: 1)
        let expectedRange = NSRange(location: 0, length: 1)

        let ranges = attributedString.paragraphRanges(intersecting: range, includeParagraphSeparator: true)

        XCTAssertEqual(ranges.first!, expectedRange)
    }

    /// Tests that `paragraphRanges(intersecting:)` with a paragraph separator character
    /// returns the correct `ParagraphRange`.
    ///
    /// This test was added due to an iOS 17 crash when calling String.paragraphRange(for: range)
    /// on a single paragraph separator character.
    ///
    func testParagraphRangesWorkWithAndWithoutParagraphSeparator() {
        let attributedString = NSAttributedString(string: "\u{2029}")
        let range = NSRange(location: 0, length: 1)
        let expectedRangeWithoutSeparator = NSRange(location: 0, length: 0)
        let expectedRangeWithSeparator = NSRange(location: 0, length: 1)

        let ranges = attributedString.paragraphRanges(intersecting: range)

        XCTAssertEqual(ranges.first!.rangeIncludingParagraphSeparator, expectedRangeWithSeparator)
        XCTAssertEqual(ranges.first!.rangeExcludingParagraphSeparator, expectedRangeWithoutSeparator)
    }
}
