import XCTest
@testable import Aztec


// MARK: - TextListFormatter Tests
//
class TextListFormatterTests: XCTestCase
{
    // Helpers #1:
    // ===========
    //
    // Expected Output:
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
    // Expected Output:
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
    //  Line 1:       [Text]            1 [Text]
    //  Line 2:       [Text]              [Text]
    //  Line 3:       [Text]    > > >     [Text]
    //  Line 4:       [Text]              [Text]
    //  Line 5:       [Text]              [Text]
    //
    // Toggling "Ordered List" on Line 1 should switch its style, and maintain lines 2-5 unaffected.
    //
    func testApplyingOrderedListOnFirstParagraphAppliesOrderedList() {
        let string = NSMutableAttributedString(string: plainText)

        let formatter = TextListFormatter()
        formatter.toggleList(ofStyle: .Ordered, inString: string, atRange: NSRange(location: 0, length: 1))

        let ranges = paragraphRanges(inString: string)
        let lists = textListAttributes(inString: string, atRanges: ranges)
        let items = textListItemAttributes(inString: string, atRanges: ranges)

        XCTAssert(lists.count == 1)
        XCTAssert(items.count == 1)

        XCTAssert(lists[0].style == .Ordered)
        XCTAssert(items[0].number == 1)
    }


    // Scenario 2: (Mark I)
    // ===========
    //
    //  Line 1:     1 [Text]              [Text]
    //  Line 2:       [Text]              [Text]
    //  Line 3:       [Text]    > > >     [Text]
    //  Line 4:       [Text]              [Text]
    //  Line 5:       [Text]              [Text]
    //
    // Toggling "Ordered List" on Line 1 should nuke it's list, and keep lines 2-5 unaffected.
    //
    func testRemovingOrderedListOnFirstParagraphEffectivelyNukesAnyLists() {
        let string = NSMutableAttributedString(string: plainText)

        let formatter = TextListFormatter()

        // Toggle the 1st line as an Ordered List
        formatter.toggleList(ofStyle: .Ordered, inString: string, atRange: NSRange(location: 0, length: 1))

        // And... undo?
        formatter.toggleList(ofStyle: .Ordered, inString: string, atRange: NSRange(location: 0, length: 1))

        let ranges = paragraphRanges(inString: string)
        let lists = textListAttributes(inString: string, atRanges: ranges)
        let items = textListItemAttributes(inString: string, atRanges: ranges)

        XCTAssert(lists.count == 0)
        XCTAssert(items.count == 0)
    }


    // Scenario 2: (Mark II)
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


    // Scenario 2: (Mark III)
    // ===========
    //
    //  Line 1:     - [Text]            - [Text]
    //  Line 2:     1 [Text]            1 [Text]
    //  Line 3:     - [Text]    > > >     [Text]
    //  Line 4:     1 [Text]            1 [Text]
    //  Line 5:     - [Text]            - [Text]
    //
    // Toggling "Unordered List" on Line 3 should nuke it's list, and keep lines 2-5 unaffected.
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


    // Scenario 3: (Mark I)
    // ===========
    //
    //  Line 1:     1 [Text]            - [Text]
    //  Line 2:     2 [Text]            - [Text]
    //  Line 3:     3 [Text]    > > >   - [Text]
    //  Line 4:     4 [Text]            - [Text]
    //  Line 5:     5 [Text]            - [Text]
    //
    // Toggling "Unordered List" on Line 1 should switch everything to an Unordered List
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
        XCTAssert(lists[1].style == .Unordered)
        XCTAssert(lists[2].style == .Unordered)
        XCTAssert(lists[3].style == .Unordered)
        XCTAssert(lists[4].style == .Unordered)
    }


    // Scenario 3: (Mark II)
    // ===========
    //
    //  Line 1:     - [Text]            1 [Text]
    //  Line 2:     1 [Text]            2 [Text]
    //  Line 3:     - [Text]    > > >   - [Text]
    //  Line 4:     1 [Text]            1 [Text]
    //  Line 5:     - [Text]            - [Text]
    //
    // Toggling "Ordered List" on Line 1 should switch the list to which it's associated. Since the
    // "lower" neighbor has the same type, they should be merged.
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


    // Scenario 3: (Mark III)
    // ===========
    //
    //  Line 1:     - [Text]            1 [Text]
    //  Line 2:     1 [Text]            2 [Text]
    //  Line 3:     - [Text]    > > >   - [Text]
    //  Line 4:     1 [Text]            1 [Text]
    //  Line 5:     - [Text]            - [Text]
    //
    // Toggling "Ordered List" on Lines 1-5 should convert Line 1 into an Ordered List, and skip the rest.
    //
    func testToggleListAppliesTheNewStyleOnTheFirstParagraphWhenTheFirstRangeContainsAnotherListOfDifferentStyle() {
        let list = listWithAlternatedStyle

        // Toggle Ordered List on the full string's range
        let formatter = TextListFormatter()
        formatter.toggleList(ofStyle: .Ordered, inString: list, atRange: list.rangeOfEntireString)

        // Verify we got a single big orderedList
        let ranges = paragraphRanges(inString: list)
        let lists = ranges.flatMap { list.textListAttribute(spanningRange: $0) }
        let items = ranges.flatMap { list.textListItemAttribute(spanningRange: $0) }

        XCTAssert(lists[0].style == .Ordered)
        XCTAssert(lists[1].style == .Ordered)
        XCTAssert(lists[2].style == .Unordered)
        XCTAssert(lists[3].style == .Ordered)
        XCTAssert(lists[4].style == .Unordered)

        XCTAssert(items[0].number == 1)
        XCTAssert(items[1].number == 2)
        XCTAssert(items[3].number == 1)
    }


    // Scenario 4:
    // ===========
    //
    //  Line 1:       [Text]            1 [Text]
    //  Line 2:       [Text]            2 [Text]
    //  Line 3:     1 [Text]    > > >   3 [Text]
    //  Line 4:     2 [Text]            4 [Text]
    //  Line 5:     3 [Text]            5 [Text]
    //
    // Toggling "Ordered List" on lines 1-2 converts the text into a single list.
    //
    func testToggleOrderedListOnPlainTextFollowedByOrderedListUpdatesAllOfTheItemNumbers() {
        let string = NSMutableAttributedString(string: plainText)
        let formatter = TextListFormatter()

        // Apply the Ordered List style to the last three paragraphs
        for (index, range) in paragraphRanges(inString: string).enumerate() where index >= 2 {
            formatter.toggleList(ofStyle: .Ordered, inString: string, atRange: range)
        }

        // Now... toggle an Ordered List on the full text
        formatter.toggleList(ofStyle: .Ordered, inString: string, atRange: string.rangeOfEntireString)

        // Verify
        let paragraphs = paragraphRanges(inString: string)
        for (index, range) in paragraphs.enumerate() {
            let list = string.textListAttribute(spanningRange: range)
            XCTAssertNotNil(list)
            XCTAssert(list!.style == .Ordered)

            let item = string.textListItemAttribute(spanningRange: range)
            XCTAssertNotNil(item)

            XCTAssert(item?.number == index + 1)
        }
    }


    // Scenario 5:
    // ===========
    //
    //  Line 1:       [Text]            1 [Text]
    //  Line 2:       [Text]            2 [Text]
    //  Line 3:     - [Text]    > > >   - [Text]
    //  Line 4:       [Text]            1 [Text]
    //  Line 5:       [Text]            2 [Text]
    //
    // Toggling "Ordered List" on lines 1-5 creates new lists on the selected paragraphs, skipping any lists
    // that don't match the new style.
    //
    func testToggleOrderedListOnParagraphIntersectingUnorderedListEffectivelySkipsListWithNoMatchingStyle() {
        let string = NSMutableAttributedString(string: plainText)
        let formatter = TextListFormatter()

        // Line 3 > Unordered List
        let ranges = paragraphRanges(inString: string)
        formatter.toggleList(ofStyle: .Unordered, inString: string, atRange: ranges[2])

        // Entire Text > Ordered List
        formatter.toggleList(ofStyle: .Ordered, inString: string, atRange: string.rangeOfEntireString)

        // Verify
        let paragraphs = paragraphRanges(inString: string)
        for (index, range) in paragraphs.enumerate() {
            guard let list = string.textListAttribute(spanningRange: range),
                let item = string.textListItemAttribute(spanningRange: range) else
            {
                XCTFail()
                return
            }

            if index == 2 {
                XCTAssert(list.style == .Unordered)
                continue
            }

            // Map (0, 1) > (1, 2) and (3, 4) > (1, 2)
            let number = (index < 2) ? (index + 1) : (index - 2)
            XCTAssert(item.number == number)
            XCTAssert(list.style == .Ordered)
        }
    }


    // Scenario 6:
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
    func testToggleListRemovesAllOfTheListAttributesWhenTheFirstParagraphListStyleMatchesTheSuppliedStyle() {
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


    // Scenario 7:
    // ===========
    //
    //  Line 1:     - [Text]            1 [Text]
    //  Line 2:     - [Text]            2 [Text]
    //  Line 3:       [Text]    > > >     [Text]
    //  Line 4:       [Text]              [Text]
    //  Line 5:       [Text]              [Text]
    //
    // Toggling "Ordered List" on Lines 1-5 should only switch Lines 1 and 2 to Ordered Lists.
    //
    func testToggleListChangesTheStyleWhenTheFirstTwoSelectedParagraphsHaveDifferentStyles() {
        let list = NSMutableAttributedString(string: plainText)
        let plainRanges = plainTextParagraphRanges
        let formatter = TextListFormatter()

        // First TWO lines: Unordered List
        let length = plainRanges[1].location + plainRanges[1].length
        let range = NSRange(location: 0, length: length)

        formatter.toggleList(ofStyle: .Unordered, inString: list, atRange: range)

        // Verify
        XCTAssert(textListItemAttributes(inString: list, atRanges: paragraphRanges(inString: list)).count == 2)

        // Toggle
        formatter.toggleList(ofStyle: .Ordered, inString: list, atRange: list.rangeOfEntireString)

        // Verify
        let items = textListItemAttributes(inString: list, atRanges: paragraphRanges(inString: list))

        XCTAssert(items.count == 2)

        XCTAssert(items[0].number == 1)
        XCTAssert(items[1].number == 2)
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
