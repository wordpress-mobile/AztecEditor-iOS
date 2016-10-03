import XCTest
@testable import Aztec


// MARK: - NSAttributedStringLists Tests
//
class NSAttributedStringListsTests: XCTestCase {

    /// Tests that `rangeOfTextList` works.
    ///
    /// Set up:
    /// - Sample NSAttributedString, with no TextList
    ///
    /// Expected result:
    /// - nil for the whole String Length
    ///
    func testRangeOfTextListReturnsNilWhenStringDoesntContainTextLists() {
        for index in (0 ... samplePlainString.length) {
            XCTAssertNil(samplePlainString.rangeOfTextList(atIndex: index))
        }
    }

    /// Tests that `rangeOfTextList` works.
    ///
    /// Set up:
    /// - Sample NSAttributedString, with a TextList associated to a substring
    ///
    /// Expected result:
    /// - The "Text List Substring" range, when applicable.
    ///
    func testRangeOfTextListReturnsTheExpectedRange() {
        let string = sampleListString
        let expected = sampleListRange

        for index in (0 ..< string.length) {
            let retrieved = string.rangeOfTextList(atIndex: index)

            if isIndexWithinListRange(index) {
                XCTAssert(retrieved != nil)
                XCTAssert(expected.location == retrieved!.location)
                XCTAssert(expected.length == retrieved!.length)
            } else {
                XCTAssert(retrieved == nil)
            }
        }
    }

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

    /// Tests that `textListContents` returns nil, whenever there is no Text List.
    ///
    /// Set up:
    /// - Sample (NON empty) NSAttributedString, but with no TextList
    ///
    /// Expected result:
    /// - nil for the whole String Length.
    ///
    func testTextListContentsReturnsNilWheneverTheReceiverHasNoTextList() {
        let string = samplePlainString

        for index in (0 ..< string.length) {
            let contents = string.textListContents(followingIndex: index)
            XCTAssertNil(contents)
        }
    }

    /// Tests that `textListContents` returns the expected TestList Contents.
    ///
    /// Set up:
    /// - Sample (NON empty) NSAttributedString, with a TextList range.
    ///
    /// Expected result:
    /// - Text List Contents. YAY!.
    ///
    func testTextListContentsReturnsTheAssociatedTextListContents() {
        let string = sampleListString
        let expectedContents = sampleListContents
        let expectedRange = sampleListRange

        for index in (0 ..< string.length) {
            let retrievedContents = string.textListContents(followingIndex: index)

            if isIndexWithinListRange(index) {
                XCTAssertNotNil(retrievedContents)
                let delta = index - expectedRange.location
                let expectedSubstring = expectedContents.substringFromIndex(expectedContents.startIndex.advancedBy(delta))
                XCTAssertEqual(retrievedContents!.string, expectedSubstring)
            } else {
                XCTAssertNil(retrievedContents)
            }
        }
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
        let paragraphRanges = string.paragraphRanges(spanningRange: NSRange(location: 0, length: 0))

        XCTAssert(paragraphRanges.count == 0)
    }

    /// Tests that `paragraphRanges` returns an empty array, when the spanning range is beyond the actual 
    /// receiver's full range.
    ///
    /// Set up:
    /// - Sample (NON empty) NSAttributedString.
    ///
    /// Expected result:
    /// - Empty array.
    ///
    func testParagraphRangesReturnEmptyArrayWhenSpanningRangeIsBiggerThanReceiverString() {
        let string = samplePlainString
        let range = NSRange(location: string.length, length: string.length)

        let paragraphRanges = string.paragraphRanges(spanningRange: range)
        XCTAssert(paragraphRanges.count == 0)
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
        let string = samplePlainString
        let expected = string.rangeOfEntireString

        for index in (0..<string.length) {
            let spanningRange = NSRange(location: index, length: 1)
            let paragraphRanges = string.paragraphRanges(spanningRange: spanningRange)

            XCTAssert(paragraphRanges.count == 1)
            guard let retrieved = paragraphRanges.first else {
                XCTFail()
                return
            }

            XCTAssert(retrieved.location == expected.location && retrieved.length == expected.length)
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

        let ranges = text.paragraphRanges(spanningRange: text.rangeOfEntireString)
        XCTAssert(ranges.count == 3)

        let paragraphs = ranges.map { text.attributedSubstringFromRange($0).string }
        for (index, retrieved) in paragraphs.enumerate() {
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
        let rangeExpected = (text.string as NSString).rangeOfString(first)

        let rangesForParagraphs = text.paragraphRanges(spanningRange: rangeExpected)
        XCTAssert(rangesForParagraphs.count == 1)

        guard let rangeRetrieved = rangesForParagraphs.first else {
            XCTFail()
            return
        }

        XCTAssert(rangeRetrieved.location == rangeExpected.location)
        XCTAssert(rangeRetrieved.length == rangeExpected.length)
    }
}



// MARK: - Helpers
//
extension NSAttributedStringListsTests
{
    var samplePlainString: NSAttributedString {
        return NSAttributedString(string: "Lord Yosemite should DEFINITELY be a Game of Thrones Character.")
    }

    var sampleListString: NSAttributedString {
        let sample = NSMutableAttributedString(string: "World Domination Plans:\n" +
            "- Build Warp Drive\n" +
            "- Rebuild Atlantis\n" +
            "- Free Internet for Everyone\n" +
            "Yay!")

        let range = (sample.string as NSString).rangeOfString(sampleListContents)
        let attributes = [TextList.attributeName: TextList(kind: .Ordered)]
        sample.addAttributes(attributes, range: range)

        return sample
    }

    var sampleListContents: String {
        return "- Build Warp Drive\n" +
            "- Rebuild Atlantis\n" +
            "- Free Internet for Everyone"
    }

    var sampleListRange: NSRange {
        return (sampleListString.string as NSString).rangeOfString(sampleListContents)
    }

    func isIndexWithinListRange(index: Int) -> Bool {
        let range = sampleListRange
        return index >= range.location && index < NSMaxRange(range)
    }
}
