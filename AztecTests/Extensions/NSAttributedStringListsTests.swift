import XCTest
@testable import Aztec


// MARK: - NSAttributedStringLists Tests
//
class NSAttributedStringListsTests: XCTestCase {

    /// Tests that `rangeOfEntireString` works.
    ///
    /// Set up:
    /// - Sample (empty) NSAttributedString
    ///
    /// Expected result:
    /// - Range: (loc: 0 , length: 0)
    ///
    func testRangeOfEntireStringWorksAsExpectedWithEmptyStrings() {
        let string = NSAttributedString()
        let range = string.rangeOfEntireString

        XCTAssert(range.location == 0)
        XCTAssert(range.length == string.length)
    }

    /// Tests that `rangeOfEntireString` works.
    ///
    /// Set up:
    /// - Sample (NON empty) NSAttributedString
    ///
    /// Expected result:
    /// - Range: (loc: 0 , length: Sample String Length)
    ///
    func testRangeOfEntireStringWorksAsExpectedWithNonEmptyStrings() {
        let string = samplePlainString
        let range = string.rangeOfEntireString

        XCTAssert(range.location == 0)
        XCTAssert(range.length == string.length)
    }

    /// Tests that `textListAttribute` returns the expected TestList, when applicable.
    ///
    /// Set up:
    /// - Sample (NON empty) NSAttributedString, with no TextList.
    ///
    /// Expected result:
    /// - Nil. Always
    ///
    func testTextListAttributeReturnsNilWhenThereIsNoList() {
        let string = samplePlainString

        for index in (0 ..< string.length) {
            XCTAssertNil(string.textListAttribute(atIndex: index))
        }
    }

    /// Tests that `textListAttribute` returns the expected TestList, when applicable.
    ///
    /// Set up:
    /// - Sample (NON empty) NSAttributedString, with a TextList.
    ///
    /// Expected result:
    /// - The TextList, whenever we're within the expected range.
    ///
    func testTextListAttributeReturnsTheTextListAttributeWhenApplicable() {
        let string = sampleListString

        for index in (0 ..< string.length) {
            let attribute = string.textListAttribute(atIndex: index)
            if isIndexWithinListRange(index) {
                XCTAssertNotNil(attribute)
            } else {
                XCTAssertNil(attribute)
            }
        }
    }

    /// Tests that `textListAttribute(spanningRange:)` returns nil, whenever there is no actual text list.
    ///
    /// Set up:
    /// - Sample (NON empty) NSAttributedString, with no TextList.
    ///
    /// Expected result:
    /// - nil
    ///
    func testTextListAttributeSpanningRangeReturnsNilWhenThereIsNoList() {
        let string = samplePlainString

        for index in (0 ..< string.length) {
            let range = NSRange(location: index, length: 1)
            XCTAssertNil(string.textListAttribute(spanning: range))
        }
    }

    /// Tests that `textListAttribute(spanningRange:)` returns the expected TestList, when applicable.
    ///
    /// Set up:
    /// - Sample (NON empty) NSAttributedString, with a TextList.
    ///
    /// Expected result:
    /// - The TextList, whenever the range passed intersects the TextList range.
    ///
    func testTextListAttributeSpanningRangeReturnsTextListAttributeWhenRangeInteresects() {
        let string = sampleListString

        for index in (0 ..< string.length) {
            let range = NSRange(location: index, length: 1)
            let attribute = string.textListAttribute(spanning: range)

            if isIndexWithinListRange(index) {
                XCTAssertNotNil(attribute)
            } else {
                XCTAssertNil(attribute)
            }
        }
    }

    /// Tests that `textListAttribute(spanningRange:)` returns the expected TestList, when the full range
    /// is received.
    ///
    /// Set up:
    /// - Sample (NON empty) NSAttributedString, with a TextList.
    ///
    /// Expected result:
    /// - The TextList Attribute.
    ///
    func testTextListAttributeSpanningRangeReturnsTextListAttributeWhenPassedFullRange() {
        let string = sampleListString
        let attribute = string.textListAttribute(spanning: sampleListRange)

        XCTAssertNotNil(attribute)
    }

    /// Tests that `paragraphRanges` returns an empty array, when dealing with an empty string.
    ///
    /// Set up:
    /// - Sample (empty) NSAttributedString.
    ///
    /// Expected result:
    /// - Empty array.
    ///
    func testParagraphRangesReturnEmptyArrayForEmptyStrings() {
        let string = NSAttributedString()
        let paragraphRanges = string.paragraphRanges(spanning: NSRange(location: 0, length: 0))

        XCTAssert(paragraphRanges.isEmpty)
    }

    /// Tests that `paragraphRanges` always returns the same paragraph ranges, wherever the "Range Location"
    /// is, as long as it falls within the string's length.
    ///
    /// Set up:
    /// - Sample (NON empty) NSAttributedString, single paragraph.
    ///
    /// Expected result:
    /// - Array with the single paragraph's range.
    ///
    func testParagraphRangesReturnSameRangeConsistentlyForSingleParagraphString() {
        let string = sampleSingleLine
        let expected = string.rangeOfEntireString

        for index in (0 ..< string.length) {
            let targetRange = NSRange(location: index, length: 1)
            let paragraphRange = string.paragraphRange(for: targetRange)

            XCTAssert(paragraphRange == expected)
        }
    }

    /// Tests that `paragraphRanges` returns an array of Ranges, containing the locations and lengths of all
    /// of the receiver's paragraphs.
    ///
    /// Set up:
    /// - Attributed String with three paragraphs.
    ///
    /// Expected result:
    /// - Array with three Ranges, matching each one of the paragraphs' location + length.
    ///
    func testParagraphRangesReturnsCorrectlyEachParagraphRange() {
        let first = "I'm the first paragraph.\n"
        let second = "I would be the second?\n"
        let third = "I guess this is the third one!.\n"

        let expected = [first, second, third]
        let text = NSAttributedString(string: first + second + third)

        let ranges = text.paragraphRanges(spanning: text.rangeOfEntireString)
        XCTAssert(ranges.count == 3)

        let paragraphs = ranges.map { (_, enclosingRange) in
            text.attributedSubstring(from: enclosingRange).string
        }

        for (index, retrieved) in paragraphs.enumerated() {
            let expected = expected[index]
            XCTAssert(expected == retrieved)
        }
    }

    /// Tests that `paragraphRanges` returns an array of Ranges that *ONLY* fall within the specified spanning range.
    ///
    /// Set up:
    /// - Attributed String with two paragraphs.
    /// - Spanning range matching the first paragraph's range.
    ///
    /// Expected result:
    /// - Array with a single range, matching the first paragraph's length + location.
    ///
    func testParagraphRangesDisregardsAnythingBeyondTheSpecifiedSpanningRange() {
        let first = "I'm the first paragraph.\n"
        let second = "I would be the second?\n"

        let text = NSAttributedString(string: first + second)
        let rangeExpected = (text.string as NSString).range(of: first)

        let rangesForParagraphs = text.paragraphRanges(spanning: rangeExpected)
        XCTAssert(rangesForParagraphs.count == 1)

        guard let (_, encapsulatedRange) = rangesForParagraphs.first else {
            XCTFail()
            return
        }

        XCTAssert(encapsulatedRange.location == rangeExpected.location)
        XCTAssert(encapsulatedRange.length == rangeExpected.length)
    }
}



// MARK: - Helpers
//
extension NSAttributedStringListsTests
{
    var sampleSingleLine: NSAttributedString {
        return NSAttributedString(string: "Lord Yosemite should DEFINITELY be a Game of Thrones Character.")
    }

    var samplePlainString: NSAttributedString {
        return NSAttributedString(string: "Shopping List:\n" +
            "- Cookies with chocolate.\n" +
            "- Red Red Wine.\n" +
            "- More Red Wine.\n" +
            "- Perhaps more cookies as well.\n")
    }

    var sampleListString: NSAttributedString {
        let sample = NSMutableAttributedString(string: "World Domination Plans:\n" +
            "- Build Warp Drive\n" +
            "- Rebuild Atlantis\n" +
            "- Free Internet for Everyone\n" +
            "- Buy Cookies\n" +
            "Yay!")

        let range = (sample.string as NSString).range(of: sampleListContents)
        let listParagraphStyle = ParagraphStyle()
        listParagraphStyle.textLists.append(TextList(style: .ordered))
        let attributes = [NSParagraphStyleAttributeName: listParagraphStyle]
        sample.addAttributes(attributes, range: range)

        return sample
    }

    var sampleListStyle: TextList.Style {
        return .ordered
    }

    var sampleListContents: String {
        return "- Build Warp Drive\n" +
            "- Rebuild Atlantis\n" +
            "- Free Internet for Everyone\n" +
            "- Buy Cookies"
    }

    var sampleListRange: NSRange {
        return (sampleListString.string as NSString).range(of: sampleListContents)
    }

    var listStyles: [TextList.Style] {
        return [.ordered, .unordered]
    }

    func isIndexWithinListRange(_ index: Int) -> Bool {
        let range = sampleListRange
        return index >= range.location && index < NSMaxRange(range)
    }
}
