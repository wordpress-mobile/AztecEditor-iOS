import Foundation
import UIKit


// MARK: - A helper for handling the formatting of ordered and unordered lists.
//
struct TextListFormatter
{
    /// Creates a new text list, or modifies an existing text list.
    ///
    /// - Parameters
    ///     - range: The range at which to apply the list style.
    ///     - string: The NSMutableAttributed string to modify.
    ///
    /// - Returns: An NSRange representing the change to the attributed string.
    ///
    func toggleStyle(style: TextList.Style, inString storage: NSMutableAttributedString, atRange range: NSRange) -> NSRange? {
        let ranges = storage.paragraphRanges(spanningRange: range)
        guard let firstRange = ranges.first else {
            return nil
        }

        // Existing list: Same kind? > remove. Else > Apply!
        if let list = storage.textListAttribute(atIndex: firstRange.location) {
            switch list.style {
            case style:
                return removeStyle(fromString: storage, atRanges: ranges)
            default:
                return updateStyle(style, inString: storage, atIndex: firstRange.location)
            }
        }

        // Check the paragraphs at each range. If any have the opposite list style remove that range.
        let filtered = ranges.filter { range in
            let paragraphListStyle = storage.textListAttribute(atIndex: range.location)?.style
            return paragraphListStyle == nil || paragraphListStyle == style
        }

        return applyStyle(style, toString: storage, atRanges: filtered)
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
    ///     - kind: The kind of List to apply
    ///     - ranges: The paragraph ranges to operate upon. Each range becomes a list item.
    ///     - string: The NSMutableAttributedString to manipulate.
    ///     - startingNumber: The starting item number for an ordered list.
    ///
    /// - Returns: The affected NSRange, or nil if no changes were made.
    ///
    func applyStyle(style: TextList.Style, toString storage: NSMutableAttributedString, atRanges range: [NSRange], startingNumber: Int = 1) -> NSRange? {
        // Adjust Ranges: Add preceeding + following ranges, if needed
        let adjustedRanges = storage.paragraphRanges(preceedingAndSucceding: range, matchingListStyle: style)
        guard let startingLocation = adjustedRanges.first?.location else {
            return nil
        }

        //
        var length = 0

        storage.beginEditing()
        //- Filter out other elements (blockquote, p, h1, h2, h3, etc.) from each paragraph. Each “paragraph” should be vanilla
        // TODO:


        //- Iterate over affected paragraphs in reverse order.  Insert/replace list marker (attributes) into string and assign list item.
        for (index, range) in adjustedRanges.enumerate().reverse() {
            let number = index + startingNumber
            let unformatted = storage.attributedSubstringFromRange(range)
            let formatted = unformatted.attributedStringByAddingTextListItemAtributes(style, number: number)
            length += formatted.length
            storage.replaceCharactersInRange(range, withAttributedString: formatted)
        }

        let textList = TextList(style: style)
        let listRange = NSRange(location: startingLocation, length: length)
        storage.addAttribute(TextList.attributeName, value: textList, range: listRange)

        storage.endEditing()

        return listRange
    }


    /// Removes TextList attributes from the specified ranges in the specified string.
    ///
    /// - Parameters:
    ///     - ranges: The ranges to modify.
    ///     - attrString: The NSMutableAttributed string to modify.
    ///
    /// - Returns: The NSRange of the changes.
    ///
    func removeStyle(fromString storage: NSMutableAttributedString, atRanges ranges: [NSRange]) -> NSRange? {
        guard let firstRange = ranges.first else {
            return nil
        }

        var listRangeLength = 0
        for range in ranges {
            listRangeLength += range.length
        }
        let fullRange = NSRange(location: firstRange.location, length: listRangeLength)

        storage.removeAttribute(TextList.attributeName, range: fullRange)
        storage.removeAttribute(TextListItem.attributeName, range: fullRange)

        // For the same type of list, we'll remove the list style. A bit tricky.  We need to remove the style
        // (and attributes) from the selected paragraph ranges, then if the following range was an ordered list,
        // we need to update its markers. (Maybe some other attribute clean up?)

        var length = 0
        //- Iterate over affected paragraphs in reverse order.  Remove list marker and attributes
        for range in ranges.reverse() {
            let clean = storage.attributedSubstringFromRange(range).attributedStringByRemovingTextListItemAtributes()
            length += clean.length
            storage.replaceCharactersInRange(range, withAttributedString: clean)
        }

        let adjustedRange = NSRange(location: firstRange.location, length: length)
        storage.fixAttributesInRange(adjustedRange)

        // Update the following list if necessary.
        let followingIdx = NSMaxRange(adjustedRange) + 1 // Add two. if just one we're pointing at the newline character and we'll end up captureing the paragraph range we just edited.
        if followingIdx < storage.length {
            if let list = storage.textListAttribute(atIndex: followingIdx) {
                updateStyle(list.style, inString: storage, atIndex: followingIdx)
            }
        }

        return adjustedRange
    }


    /// Updates the TextListTpe for a TextList at the specified index.
    ///
    /// - Parameters:
    ///     - attrString: An NSMutableAttributedString to modify.
    ///     - index: An index intersecting the TextList within `attrString`.
    ///     - type: The type of list to become.
    ///
    func updateStyle(style: TextList.Style, inString storage: NSMutableAttributedString, atIndex index: Int) -> NSRange? {
        // TODO: Confirm using longest effective range is actually safe. We don't want to consume neighboring
        // lists of a different type.
        // (NOTE: probably not an issue when searching for custom aztec markup attributes?)
        //
        guard let listRange = storage.rangeOfTextList(atIndex: index) else {
            return nil
        }

        let paragraphRanges = storage.paragraphRanges(spanningRange: listRange)
        return applyStyle(style, toString: storage, atRanges: paragraphRanges)
    }
}
