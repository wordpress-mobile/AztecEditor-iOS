import Foundation
import UIKit


// MARK: - A helper for handling the formatting of ordered and unordered lists.
//
class TextListFormatter
{
    /// Creates a new text list, or modifies an existing text list.
    ///
    /// - Parameters
    ///     - ofStyle: The kind of List to apply
    ///     - inString: The NSMutableAttributed string to modify.
    ///     - atRange: The range at which to apply the list style.
    ///
    /// - Returns: An NSRange representing the change to the attributed string.
    ///
    func toggleList(ofStyle style: TextList.Style, inString string: NSMutableAttributedString, atRange range: NSRange) -> NSRange? {
        // Load Paragraph Ranges
        let paragraphRanges = string.paragraphRanges(spanningRange: range)
        guard paragraphRanges.isEmpty == false else {
            return nil
        }

        // 1st Paragraph: No List >> Apply
        guard let listRange = string.rangeOfTextList(atIndex: paragraphRanges[0].location) else {
            return applyList(ofStyle: style, toString: string, atRanges: paragraphRanges)
        }

        // 1st Paragraph: Matching List Style >> Remove
        guard let listAttribute = string.textListAttribute(spanningRange: listRange) where listAttribute.style != style else {
            return removeList(fromString: string, atRanges: paragraphRanges)
        }

        // 1st Paragraph: Non Matching Style >> Update!
        let listParagraphs = string.paragraphRanges(spanningRange: listRange)
        return applyList(ofStyle: style, toString: string, atRanges: listParagraphs)
    }
}


// MARK: - Private Helpers
//
private extension TextListFormatter
{
    /// Applies a TextList attribute to the specified paragraph ranges in the
    /// specified string. Each paragraph range is treated as a list item.
    ///
    /// - Parameters:
    ///     - ofStyle: The kind of List to apply
    ///     - toString: The NSMutableAttributedString to manipulate.
    ///     - atRanges: The paragraph ranges to operate upon. Each range becomes a list item.
    ///     - startingAt: The starting item number for an ordered list.
    ///
    /// - Returns: The affected NSRange, or nil if no changes were made.
    ///
    func applyList(ofStyle style: TextList.Style, toString string: NSMutableAttributedString, atRanges range: [NSRange], startingAt number: Int = 1) -> NSRange? {
        // Adjust Ranges: Add preceeding + following ranges, if needed
        let adjustedRanges = string.paragraphRanges(preceedingAndSucceding: range, matchingListStyle: style)
        guard let startingLocation = adjustedRanges.first?.location else {
            return nil
        }

        // TextListItem: Apply to each one of the paragraphs
        var length = 0

        string.beginEditing()

        for (index, range) in adjustedRanges.enumerate().reverse() {
            let number = index + number
            let unformatted = string.attributedSubstringFromRange(range)
            let formatted = unformatted.attributedStringByApplyingListItemAttributes(ofStyle: style, withNumber: number)

            string.replaceCharactersInRange(range, withAttributedString: formatted)
            length += formatted.length
        }

        // TextList: Apply Attribute
        let textList = TextList(style: style)
        let listRange = NSRange(location: startingLocation, length: length)
        string.addAttribute(TextList.attributeName, value: textList, range: listRange)

        // Done Editing!
        string.endEditing()

        return listRange
    }


    /// Removes TextList attributes from the specified ranges in the specified string.
    ///
    /// - Parameters:
    ///     - froMString: The NSMutableAttributed string to modify.
    ///     - atRanges: The ranges to modify.
    ///
    /// - Returns: The NSRange of the changes.
    ///
    func removeList(fromString string: NSMutableAttributedString, atRanges ranges: [NSRange]) -> NSRange? {
        guard let firstRange = ranges.first else {
            return nil
        }

        // Nuke TextList Attribute
        let listLength = ranges.reduce(0) { return $1.length }
        let listRange = NSRange(location: firstRange.location, length: listLength)

        string.removeAttribute(TextList.attributeName, range: listRange)

        // Nuke TextListItem + TextListMarker Attributes
        var length = 0

        for range in ranges.reverse() {
            let formatted = string.attributedSubstringFromRange(range)
            let clean = formatted.attributedStringByRemovingListItemAttributes()

            string.replaceCharactersInRange(range, withAttributedString: clean)
            length += clean.length
        }

        // Update the (SUCCEDING) List, if needed.
        let adjustedRange = NSRange(location: firstRange.location, length: length)
        updateList(inString: string, succeedingRange: adjustedRange)

        return adjustedRange
    }


    /// Updates the TextListTpe for a TextList at the specified index.
    ///
    /// - Parameters:
    ///     - inString: An NSMutableAttributedString to modify.
    ///     - atIndex: An index intersecting the TextList within `attrString`.
    ///     - toStyle: The type of list to become.
    ///
    func updateList(inString string: NSMutableAttributedString, succeedingRange range: NSRange) {
        // Update its markers if the following range was an ordered list
        let nextListIndex = NSMaxRange(range) + 1

        guard nextListIndex < string.length else {
            return
        }

        guard let nextListAttribute = string.textListAttribute(atIndex: nextListIndex) where nextListAttribute.style != .Unordered else {
            return
        }

        let nextListParagraphs = string.paragraphRanges(atIndex: nextListIndex, matchingListStyle: nextListAttribute.style)
        applyList(ofStyle: nextListAttribute.style, toString: string, atRanges: nextListParagraphs)
    }
}
