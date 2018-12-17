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
}
