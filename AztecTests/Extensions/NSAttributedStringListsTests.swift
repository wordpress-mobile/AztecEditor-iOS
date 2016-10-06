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

    /// Tests that `rangeOfLine` returns, effectively, the range of the line that matches with the given index.
    ///
    /// Set up:
    /// - Sample text with two lines
    ///
    /// Expected result:
    /// - Range of the first (OR) second line, whenever the index parameter falls within the required values.
    ///
    func testRangeOfLineEffectivelyReturnsTheRangeOfTheCurrentLine() {
        // Setup
        let firstText = "this would be a line\n"
        let secondText = "and this too\n"
        let fullText = NSAttributedString(string: firstText + secondText)

        // Expected Ranges
        let foundationText = fullText.string as NSString
        let firstRange = foundationText.rangeOfString(firstText)
        let secondRange = foundationText.rangeOfString(secondText)


        // Check
        for index in (0 ..< fullText.length) {
            guard let range = fullText.rangeOfLine(atIndex: index) else {
                XCTFail()
                return
            }

            var target = secondRange
            if index >= firstRange.location && index < NSMaxRange(firstRange) {
                target = firstRange
            }

            XCTAssert(range.location == target.location && range.length == target.length)
        }
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
            XCTAssertNil(string.textListAttribute(spanningRange: range))
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
            let attribute = string.textListAttribute(spanningRange: range)

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

        XCTAssert(paragraphRanges.isEmpty)
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


    /// Tests that `paragraphRanges(atIndex: matchingListStyle)` returns the pargraph ranges, whenever the list
    /// style matches.
    ///
    /// Set up:
    /// - Attributed String with three list-paragraphs
    ///
    /// Expected result:
    /// - Array with three ranges, whenever the method is passed an index that lies within the list range.
    ///
    func testParagraphRangesOfListStyleReturnsTheListRangeAtTheSpecifiedIndexWhenStyleMatches() {
        let string = sampleListString

        for index in (0 ..< string.length) {
            let ranges = string.paragraphRanges(atIndex: index, matchingListStyle: sampleListStyle)
            if isIndexWithinListRange(index) {
                XCTAssert(ranges.count == 4)
            } else {
                XCTAssert(ranges.isEmpty)
            }
        }
    }

    /// Tests that `paragraphRanges(atIndex: matchingListStyle)` returns an empty array, whenever the list
    /// style doesn't match.
    ///
    /// Set up:
    /// - Attributed String with three list-paragraphs
    ///
    /// Expected result:
    /// - Array with zero entities.
    ///
    func testParagraphRangesOfListStyleReturnsAnEmptyArrayWheneverStyleWontMatch() {
        let string = sampleListString

        for index in (0 ..< string.length) {
            for listStyle in listStyles where listStyle != sampleListStyle {
                let ranges = string.paragraphRanges(atIndex: index, matchingListStyle: listStyle)
                XCTAssert(ranges.isEmpty)
            }
        }
    }

    /// Tests that `paragraphRanges(atIndex: matchingListStyle)` returns an empty array, whenever there is no textList.
    ///
    /// Set up:
    /// - Attributed String with no text lists.
    ///
    /// Expected result:
    /// - Array with zero entities.
    ///
    func testParagraphRangesOfListStyleReturnsAnEmptyArrayWheneverThereIsNoList() {
        let string = samplePlainString

        for index in (0 ..< string.length) {
            for listStyle in listStyles {
                let ranges = string.paragraphRanges(atIndex: index, matchingListStyle: listStyle)
                XCTAssert(ranges.isEmpty)
            }
        }
    }

    /// Tests that `paragraphRanges(preceedingAndSucceding: matchingListStyle)` the same ranges received, whenever there is no
    /// surrounding list.
    ///
    /// Set up:
    /// - Attributed String with no text lists.
    /// - Ranges of all of the string's paragraphs
    ///
    /// Expected result:
    /// - Same Input Ranges
    ///
    func testParagraphRangesPreceedingAndSucceedingRangesReturnTheReceivedRangesIfThereIsNoSurroundingList() {
        let string = samplePlainString
        let ranges = string.paragraphRanges(spanningRange: string.rangeOfEntireString)

        for style in listStyles {
            let retrieved = string.paragraphRanges(preceedingAndSucceding: ranges, matchingListStyle: style)
            XCTAssert(retrieved.count == ranges.count)
        }
    }

    /// Tests that `paragraphRanges(preceedingAndSucceding: matchingListStyle)` returns all of the list's paragraph ranges,
    /// when a single paragraph is fed.
    ///
    /// Set up:
    /// - Attributed String with a text list.
    /// - Ranges of all of the string's paragraphs
    ///
    /// Expected result:
    /// - Full List Ranges, whenever each one of the List Item Ranges is sent over
    ///
    func testParagraphRangesPreceedingAndSucceedingRangesEffectivelyInjectSurroundingListRanges() {
        let listString = sampleListString
        let listRange = sampleListRange
        let listParagraphRanges = listString.paragraphRanges(spanningRange: listRange)
        XCTAssert(listParagraphRanges.count == 4)

        for itemRange in listParagraphRanges {
            let retrievedRanges = listString.paragraphRanges(preceedingAndSucceding: [itemRange], matchingListStyle: sampleListStyle)
            XCTAssert(retrievedRanges.count == listParagraphRanges.count)
            XCTAssertEqual(listParagraphRanges, retrievedRanges)
        }
    }

    /// Tests that `attributedStringByApplyingListItemAttributes` effectively applies a TextListItem and + Marker.
    ///
    /// Set up:
    /// - Plain raw string
    ///
    /// Expected result:
    /// - TextListItem Style + Marker
    ///
    func testAttributedStringByApplyingListItemAttributesEffectivelyAppliesListItemStyle() {
        let original = sampleSingleLine
        let applied = original.attributedStringByApplyingListItemAttributes(ofStyle: .Ordered, withNumber: 5)

        for index in (0 ..< applied.length) {
            let item = applied.attribute(TextListItem.attributeName, atIndex: index, effectiveRange: nil) as? TextListItem
            XCTAssertNotNil(item)
        }

        let marker = applied.attribute(TextListItemMarker.attributeName, atIndex: 0, effectiveRange: nil) as? TextListItemMarker
        XCTAssertNotNil(marker)
    }

    /// Tests that `attributedStringByApplyingListItemAttributes` effectively removes the TextListItem Attribute.
    ///
    /// Set up:
    /// - Attributed String with a TextItem style
    ///
    /// Expected result:
    /// - No style after running the clean method
    ///
    func testAttributedStringByRemovingListItemAttributesEffectivelyNukesListItemStyle() {
        let original = sampleSingleLine
        let applied = original.attributedStringByApplyingListItemAttributes(ofStyle: .Unordered, withNumber: 2)
        let clean = applied.attributedStringByRemovingListItemAttributes()

        for index in (0 ..< applied.length) {
            let item = applied.attribute(TextListItem.attributeName, atIndex: index, effectiveRange: nil) as? TextListItem
            XCTAssertNotNil(item)
        }

        for index in (0 ..< clean.length) {
            let nothing = clean.attribute(TextListItem.attributeName, atIndex: index, effectiveRange: nil) as? TextListItem
            XCTAssertNil(nothing)
        }
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

        let range = (sample.string as NSString).rangeOfString(sampleListContents)
        let attributes = [TextList.attributeName: TextList(style: sampleListStyle)]
        sample.addAttributes(attributes, range: range)

        return sample
    }

    var sampleListStyle: TextList.Style {
        return .Ordered
    }

    var sampleListContents: String {
        return "- Build Warp Drive\n" +
            "- Rebuild Atlantis\n" +
            "- Free Internet for Everyone\n" +
            "- Buy Cookies"
    }

    var sampleListRange: NSRange {
        return (sampleListString.string as NSString).rangeOfString(sampleListContents)
    }

    var listStyles: [TextList.Style] {
        return [.Ordered, .Unordered]
    }

    func isIndexWithinListRange(index: Int) -> Bool {
        let range = sampleListRange
        return index >= range.location && index < NSMaxRange(range)
    }
}
