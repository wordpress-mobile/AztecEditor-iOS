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
    @discardableResult
    func toggleList(ofStyle style: TextList.Style, inString string: NSMutableAttributedString, atRange range: NSRange) -> NSRange? {
        // Load Paragraph Ranges
        let paragraphRanges = string.paragraphRanges(spanningRange: range)
        guard paragraphRanges.isEmpty == false else {
            return nil
        }

        // 1st Paragraph: No List >> Apply, skipping paragraphs that currently contain TextLists
        guard let listRange = string.rangeOfTextList(atIndex: paragraphRanges[0].location) else {
            let filtered = string.filterListRanges(paragraphRanges, notMatchingStyle: style)
            return applyLists(ofStyle: style, toString: string, atNonContiguousRanges: filtered)
        }

        // 1st Paragraph: Matching List Style >> Remove
        guard let listAttribute = string.textListAttribute(spanningRange: listRange), listAttribute.style != style else {
            return removeList(fromString: string, atRanges: paragraphRanges)
        }

        // 1st Paragraph: Non Matching Style >> Update!
        let listParagraphs = string.paragraphRanges(spanningRange: listRange)
        return applyList(ofStyle: style, toString: string, atRanges: listParagraphs)
    }

    /// Updates the list attributes on the specified range
    ///
    /// - Parameters:
    ///   - string: the string to update
    ///   - range: the range where to check for list
    /// - Returns: the total range that was affected by the method
    ///
    @discardableResult
    func updatesList(inString string: NSMutableAttributedString, atRange range: NSRange) -> NSRange? {

        var styleOptional: TextList.Style?
        // Load Paragraph Ranges

        let paragraphRanges = string.paragraphRanges(spanningRange: range)
        guard let firstParagraphRange = paragraphRanges.first else {
            if let paragraphRange = string.rangeOfLine(atIndex: range.location) {
                return removeList(fromString: string, atRanges: [paragraphRange])
            }
            return nil
        }
        if let textList = string.attribute(TextList.attributeName, at: firstParagraphRange.location, effectiveRange: nil) as? TextList {
            styleOptional = textList.style
        }

        guard let style = styleOptional else {
            return removeList(fromString: string, atRanges: [firstParagraphRange])
        }


        guard let listRange = string.rangeOfTextList(atIndex: firstParagraphRange.location) else {
            return nil
        }

        let listParagraphs = string.paragraphRanges(spanningRange: listRange)
        return applyList(ofStyle: style, toString: string, atRanges: listParagraphs)
    }


    /// Removes any list attributes on the provided string that exist on the specified range.
    /// This method also updates any surrounding lists of the specified range
    ///
    /// - Parameters:
    ///   - string: the string to update
    ///   - range: the range to where remove the list attributes
    /// - Returns: the total range that was affected by this method
    ///
    @discardableResult
    func removeList(inString string: NSMutableAttributedString, atRange range: NSRange) -> NSRange? {
        return removeList(fromString: string, atRanges: [range])
    }
}


// MARK: - Private Helpers
//
private extension TextListFormatter
{
    /// Applies a TextList attribute to the specified non contiguous ranges.
    ///
    /// - Parameters:
    ///     - style: Style of TextList to be applied.
    ///     - string: Target String.
    ///     - ranges: Segments of the receiver string to be transformed into lists.
    ///
    /// - Returns: The affected NSRange, or nil if no changes were made.
    ///
    /// - Notes: The returned NSRange, if any, will *INCLUDE* any String Ranges that lie between the non contiguous
    ///   groups. Specifically...
    ///
    ///     [Line 1]  Text                          [Line 1]  1. Text
    ///     [Line 2]  - Unordered List      >>      [Line 2]  - Unordered List
    ///     [Line 3]  More Text                     [Line 3]  1. More Text
    ///     [Line 4]  Something Else                [Line 4]  Something Else
    ///
    ///   Calling ApplyLists over Lines 1-3 should produce the results at the right hand, and lines 1-3 should
    ///   remain selected. Capicci?
    ///
    func applyLists(ofStyle style: TextList.Style, toString string: NSMutableAttributedString, atNonContiguousRanges ranges: [NSRange]) -> NSRange? {
        guard let first = ranges.first, let last = ranges.last else {
            return nil
        }

        let grouped = groupContiguousRanges(ranges)
        var textLengthDelta = 0

        for group in grouped.reversed() {
            // Apply List Style to the current group
            guard let listRange = applyList(ofStyle: style, toString: string, atRanges: group) else {
                continue
            }

            // Calculate the Length Delta between SUM(group.range.length) and "EFFECTIVE List Length"
            textLengthDelta += calculateLengthDelta(betweenContiguousRanges: group, andConsolidatedRange: listRange)
        }

        // Simply calculate the "Effective List Range"
        let length = last.endLocation - first.location + textLengthDelta
        return NSRange(location: first.location, length: length)
    }


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
    @discardableResult
    func applyList(ofStyle style: TextList.Style, toString string: NSMutableAttributedString, atRanges range: [NSRange], startingAt number: Int = 1) -> NSRange? {
        // Adjust Ranges: Add preceeding + following ranges, if needed
        let adjustedRanges = string.paragraphRanges(preceedingAndSucceding: range, matchingListStyle: style)
        guard let startingLocation = adjustedRanges.first?.location else {
            return nil
        }

        // TextListItem: Apply to each one of the paragraphs
        var length = 0

        string.beginEditing()

        for (index, range) in adjustedRanges.enumerated().reversed() {
            let number = index + number
            let unformatted = string.attributedSubstring(from: range)
            let formatted = unformatted.attributedStringByApplyingListItemAttributes(ofStyle: style, withNumber: number)

            string.replaceCharacters(in: range, with: formatted)
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

        for range in ranges.reversed() {
            let formatted = string.attributedSubstring(from: range)
            let clean = formatted.attributedStringByRemovingListItemAttributes()

            string.replaceCharacters(in: range, with: clean)
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

        guard let nextListAttribute = string.textListAttribute(atIndex: nextListIndex), nextListAttribute.style != .unordered else {
            return
        }

        let nextListParagraphs = string.paragraphRanges(atIndex: nextListIndex, matchingListStyle: nextListAttribute.style)
        applyList(ofStyle: nextListAttribute.style, toString: string, atRanges: nextListParagraphs)
    }
}


// MARK: - Private Helpers
//
private extension TextListFormatter
{
    /// This helper groups contiguous ranges, and returns each group inside their own array.
    ///
    /// - Parameter ranges: The ranges to be grouped.
    ///
    /// - Returns: An array of grouped contiguous-ranges.
    ///
    func groupContiguousRanges(_ ranges: [NSRange]) -> [[NSRange]] {
        var grouped = [[NSRange]]()
        var current = [NSRange]()
        var last: NSRange?

        for range in ranges {
            if let endLocation = last?.endLocation, range.location != endLocation {
                grouped.append(current)
                current.removeAll()
                last = nil
            }

            current.append(range)
            last = range
        }

        if !current.isEmpty {
            grouped.append(current)
        }
        
        return grouped
    }


    /// Calculates the difference, in length, between a group of contiguous ranges, and another NSRange instance.
    ///
    /// - Parameters:
    ///     - contiguous: Collection of contiguous NSRange instances.
    ///     - consolidated: A single NSRange instance.
    ///
    /// - Returns: Delta between the SUM(contiguous.length) and consolidated.length
    ///
    func calculateLengthDelta(betweenContiguousRanges contiguous: [NSRange], andConsolidatedRange consolidated: NSRange) -> Int {
        let contiguousLength = contiguous.reduce(0) { $0 + $1.length }
        return consolidated.length - contiguousLength
    }
}
