import XCTest
@testable import Aztec


// MARK: - TextListFormatter Tests
//
class TextListFormatterTests: XCTestCase
{
    // Helpers #1:
    // ===========
    //
    //  Line 1:     - [Text]
    //  Line 2:     1 [Text]
    //  Line 3:     - [Text]
    //  Line 4:     1 [Text]
    //  Line 5:     - [Text]
    //
    // Verify that the `listWithAlternatedStyle` produces a group of alternated lists, as expected.
    //
    func testListWithAlternatedStyleBuildsMultipleListsAsExpected() {
        let list = listWithAlternatedStyle
        let ranges = paragraphRanges(inString: list)

        let lists = textListAttributes(inString: list, atRanges: ranges)
        let listItems = textListItemAttributes(inString: list, atRanges: ranges)

        XCTAssert(ranges.count == plainTextParagraphLines.count)
        XCTAssert(lists.count == plainTextParagraphLines.count)
        XCTAssert(listItems.count == plainTextParagraphLines.count)

        XCTAssert(lists[0].style == .Unordered)
        XCTAssert(lists[1].style == .Ordered)
        XCTAssert(lists[2].style == .Unordered)
        XCTAssert(lists[3].style == .Ordered)

        XCTAssert(listItems[1].number == 1)
        XCTAssert(listItems[3].number == 1)
    }

    // Helpers #2:
    // ===========
    //
    //  Line 1:     1 [Text]
    //  Line 2:     2 [Text]
    //  Line 3:     3 [Text]
    //  Line 4:     4 [Text]
    //  Line 5:     5 [Text]
    //
    // Verify that the `listWithOrderedStyle` produces a single Ordered List
    //
    func testListWithOrderedStyleBuildsSingleOrderedList() {
        let list = listWithOrderedStyle
        let ranges = paragraphRanges(inString: list)

        let lists = textListAttributes(inString: list, atRanges: ranges)
        let items = textListItemAttributes(inString: list, atRanges: ranges)

        XCTAssert(ranges.count == plainTextParagraphLines.count)
        XCTAssert(lists.count == plainTextParagraphLines.count)
        XCTAssert(items.count == plainTextParagraphLines.count)

        for list in lists {
            XCTAssert(list.style == .Ordered)
        }

        for (index, item) in items.enumerate() {
            XCTAssert(item.number == index + 1)
        }
    }

    // Scenario 1:
    // ===========
    //
    //  Line 1:     - [Text]            1 [Text]
    //  Line 2:     1 [Text]            2 [Text]
    //  Line 3:     - [Text]    > > >   - [Text]
    //  Line 4:     1 [Text]            1 [Text]
    //  Line 5:     - [Text]            - [Text]
    //
    // Toggling "Ordered List" on Line 1 should switch its style, and update Line 2's value.
    //
    func testToggleOrderedListOnFirstItem() {
        let list = listWithAlternatedStyle
        let ranges = paragraphRanges(inString: list)

        // Toggle Ordered List on the first line
        let formatter = TextListFormatter()
        formatter.toggleList(ofStyle: .Ordered, inString: list, atRange: ranges[0])

        //
        let lists = textListAttributes(inString: list, atRanges: ranges)
        let listItems = textListItemAttributes(inString: list, atRanges: ranges)

        XCTAssert(ranges.count == plainTextParagraphLines.count)
        XCTAssert(lists.count == plainTextParagraphLines.count)
        XCTAssert(listItems.count == plainTextParagraphLines.count)

        XCTAssert(lists[0].style == .Ordered)
        XCTAssert(lists[1].style == .Ordered)
        XCTAssert(lists[2].style == .Unordered)
        XCTAssert(lists[3].style == .Ordered)

        XCTAssert(listItems[0].number == 1)
        XCTAssert(listItems[1].number == 2)
        XCTAssert(listItems[3].number == 1)
    }


    // Scenario 2:
    // ===========
    //
    //  Line 1:     - [Text]            - [Text]
    //  Line 2:     1 [Text]            1 [Text]
    //  Line 3:     - [Text]    > > >     [Text]
    //  Line 4:     1 [Text]            1 [Text]
    //  Line 5:     - [Text]            - [Text]
    //
    // Toggling "Unordered List" on Line 3 should leave Lines 1, 2, 4, 5 untouched.
    //
    func testToggleListUpdatesStyleWhenThereWasAnExistingListWithDifferentStyles() {
        let list = listWithAlternatedStyle
        let ranges = paragraphRanges(inString: list)

        // Toggle Ordered List on the first line
        let formatter = TextListFormatter()
        formatter.toggleList(ofStyle: .Unordered, inString: list, atRange: ranges[2])

        //
        let lists = textListAttributes(inString: list, atRanges: ranges)
        let listItems = textListItemAttributes(inString: list, atRanges: ranges)

        XCTAssert(lists.count == 4)
        XCTAssert(listItems.count == 4)

        XCTAssert(lists[0].style == .Unordered)
        XCTAssert(lists[1].style == .Ordered)
        XCTAssert(lists[2].style == .Ordered)
        XCTAssert(lists[3].style == .Unordered)

        XCTAssert(listItems[1].number == 1)
        XCTAssert(listItems[2].number == 1)
    }

    // Scenario 3:
    // ===========
    //
    //  Line 1:     - [Text]            1 [Text]
    //  Line 2:     1 [Text]            2 [Text]
    //  Line 3:     - [Text]    > > >   3 [Text]
    //  Line 4:     1 [Text]            4 [Text]
    //  Line 5:     - [Text]            5 [Text]
    //
    // Toggling "Ordered List" on Lines 1-5 should make all of the text a single Ordered List.
    //
    func testToggleListAppliesTheNewStyleConsistentlyWhenTheFirstRangeDoesntMatchTheNewRange() {
        let list = listWithAlternatedStyle

        // Toggle Ordered List on the full string's range
        let formatter = TextListFormatter()
        formatter.toggleList(ofStyle: .Ordered, inString: list, atRange: list.rangeOfEntireString)

        // Verify we got a single big orderedList
        let ranges = paragraphRanges(inString: list)
        let lists = textListAttributes(inString: list, atRanges: ranges)
        let listItems = textListItemAttributes(inString: list, atRanges: ranges)

        XCTAssert(lists.count == 5)
        XCTAssert(listItems.count == 5)

        for list in lists  {
            XCTAssert(list.style == .Ordered)
        }

        for (index, item) in listItems.enumerate() {
            XCTAssert(item.number == (index + 1))
        }

        guard let listRange = list.rangeOfTextList(atIndex: 0) else {
            XCTFail()
            return
        }

        XCTAssert(listRange.length == list.length)
    }

    // Scenario 4:
    // ===========
    //
    //  Line 1:     - [Text]              [Text]
    //  Line 2:     1 [Text]              [Text]
    //  Line 3:     - [Text]    > > >     [Text]
    //  Line 4:     1 [Text]              [Text]
    //  Line 5:     - [Text]              [Text]
    //
    // Toggling "Unordered List" on Lines 1-5 should remove all of the lists / items.
    //
    func testToggleListRemovesAllOfTheListAttributesWhenTheFirstRangeStyleMatchesTheSuppliedStyle() {
        let list = listWithAlternatedStyle

        // Toggle Ordered List on the full string's range
        let formatter = TextListFormatter()
        formatter.toggleList(ofStyle: .Unordered, inString: list, atRange: list.rangeOfEntireString)

        // Verify we got a single big orderedList
        let ranges = paragraphRanges(inString: list)
        let lists = textListAttributes(inString: list, atRanges: ranges)
        let items = textListItemAttributes(inString: list, atRanges: ranges)

        XCTAssert(lists.count == 0)
        XCTAssert(items.count == 0)
    }

    // Scenario 5:
    // ===========
    //
    //  Line 1:     1 [Text]              [Text]
    //  Line 2:     2 [Text]            1 [Text]
    //  Line 3:     3 [Text]    > > >   2 [Text]
    //  Line 4:     4 [Text]            3 [Text]
    //  Line 5:     5 [Text]            4 [Text]
    //
    // Toggling "Ordered List" on Line 1 should update Line 2-5.
    //
    func testToggleOrderedListOnFirstOrderedListItemUpdatesTheRemainingItemNumbers() {
        let list = listWithOrderedStyle
        let ranges = paragraphRanges(inString: list)

        let formatter = TextListFormatter()
        formatter.toggleList(ofStyle: .Ordered, inString: list, atRange: ranges[0])

        let lists = textListAttributes(inString: list, atRanges: ranges)
        let items = textListItemAttributes(inString: list, atRanges: ranges)

        XCTAssert(lists.count == 4)
        XCTAssert(items.count == 4)

        for list in lists {
            XCTAssert(list.style == .Ordered)
        }

        for (index, item) in items.enumerate() {
            XCTAssert(item.number == index + 1)
        }
    }

    // Scenario 6:
    // ===========
    //
    //  Line 1:     1 [Text]            - [Text]
    //  Line 2:     2 [Text]            1 [Text]
    //  Line 3:     3 [Text]    > > >   2 [Text]
    //  Line 4:     4 [Text]            3 [Text]
    //  Line 5:     5 [Text]            4 [Text]
    //
    // Toggling "Unordered List" on Line 1 should update Lines 2-5, and toggle Line 1.
    //
    func testToggleUnorderedListOnFirstOrderedListItemUpdatesTheRemainingItemNumbers() {
        let list = listWithOrderedStyle
        let ranges = paragraphRanges(inString: list)

        let formatter = TextListFormatter()
        formatter.toggleList(ofStyle: .Unordered, inString: list, atRange: ranges[0])

        let lists = textListAttributes(inString: list, atRanges: ranges)
        let items = textListItemAttributes(inString: list, atRanges: ranges)

        XCTAssert(lists.count == 5)
        XCTAssert(items.count == 5)


        XCTAssert(lists[0].style == .Unordered)
        XCTAssert(lists[1].style == .Ordered)
        XCTAssert(lists[2].style == .Ordered)
        XCTAssert(lists[3].style == .Ordered)
        XCTAssert(lists[4].style == .Ordered)

        XCTAssert(items[1].number == 1)
        XCTAssert(items[2].number == 2)
        XCTAssert(items[3].number == 3)
        XCTAssert(items[4].number == 4)
    }
}


// MARK: - TextListFormatterTests
//
private extension TextListFormatterTests
{
    typealias Style = TextList.Style

    var plainText: String {
        return plainTextParagraphLines.joinWithSeparator("")
    }

    var plainTextParagraphLines: [String] {
        return ["First line.\n", "Second Line.\n", "Third line!.\n", "Last but not least?.\n", "Last One!"]
    }

    var plainTextParagraphRanges: [NSRange] {
        let foundationString = plainText as NSString

        return plainTextParagraphLines.map {
            foundationString.rangeOfString($0)
        }
    }

    var listWithOrderedStyle: NSMutableAttributedString {
        let string = NSMutableAttributedString(string: plainText)
        let formatter = TextListFormatter()

        formatter.toggleList(ofStyle: .Ordered, inString: string, atRange: string.rangeOfEntireString)

        return string
    }

    var listWithAlternatedStyle: NSMutableAttributedString {
        let string = NSMutableAttributedString(string: plainText)
        let formatter = TextListFormatter()
        var style = Style.Unordered

        for range in plainTextParagraphRanges.reverse() {
            formatter.toggleList(ofStyle: style, inString: string, atRange: range)

            style = (style == .Unordered) ? .Ordered : .Unordered
        }

        return string
    }

    func paragraphRanges(inString string: NSAttributedString) -> [NSRange] {
        return string.paragraphRanges(spanningRange: string.rangeOfEntireString)
    }

    func textListAttributes(inString string: NSAttributedString, atRanges ranges: [NSRange]) -> [TextList] {
        return ranges.flatMap {
            string.textListAttribute(spanningRange: $0)
        }
    }

    func textListItemAttributes(inString string: NSAttributedString, atRanges ranges: [NSRange]) -> [TextListItem] {
        return ranges.flatMap {
            string.textListItemAttribute(spanningRange: $0)
        }
    }
}
