import XCTest
@testable import Aztec

class NSAttributedStringParagraphRangeTests: XCTestCase {
    
    func testParagraphRangesWithoutSeparator() {
        let attributedString = NSAttributedString(string: "Paragraph 1\nParagraph 2\n")
        let range = NSRange(location: 0, length: 0)
        let expectedRange = NSRange(location: 0, length: 11)
        
        let ranges = attributedString.paragraphRanges(spanning: range, includeParagraphSeparator: false)
        
        XCTAssertEqual(ranges.count, 1)
        XCTAssertEqual(ranges.first, expectedRange)
    }
    
    func testParagraphRangesWithSeparator() {
        let attributedString = NSAttributedString(string: "Paragraph 1\nParagraph 2\n")
        let range = NSRange(location: 0, length: 0)
        let expectedRange = NSRange(location: 0, length: 12)
        
        let ranges = attributedString.paragraphRanges(spanning: range, includeParagraphSeparator: true)
        
        XCTAssertEqual(ranges.count, 1)
        XCTAssertEqual(ranges.first, expectedRange)
    }
    
    func testParagraphRanges() {
        let attributedString = NSAttributedString(string: "Paragraph 1\nParagraph 2\n")
        let range = NSRange(location: 0, length: 0)
        let expectedRangeWithoutSeparator = NSRange(location: 0, length: 11)
        let expectedRangeWithSeparator = NSRange(location: 0, length: 12)
        
        let ranges = attributedString.paragraphRanges(spanning: range)
        
        XCTAssertEqual(ranges.count, 1)
        XCTAssertEqual(ranges.first?.0, expectedRangeWithoutSeparator)
        XCTAssertEqual(ranges.first?.1, expectedRangeWithSeparator)
    }
}
