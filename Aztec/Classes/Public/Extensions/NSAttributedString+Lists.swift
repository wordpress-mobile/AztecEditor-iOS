import Foundation
import UIKit


// MARK: - NSAttributedString Lists Helpers
//
extension NSAttributedString
{
    /// Get the range of a TextList containing the specified index.
    ///
    /// - Parameter index: An index intersecting a TextList.
    ///
    /// - Returns: An NSRange optional containing the range of the list or nil if no list was found.
    ///
    func rangeOfTextList(atIndex index: Int) -> NSRange? {
        var effectiveRange = NSRange()
        let targetRange = rangeOfEntireString
        guard let _ = attribute(TextList.attributeName, atIndex: index, longestEffectiveRange: &effectiveRange, inRange: targetRange) as? TextList else {
            return nil
        }

        return effectiveRange
    }

    /// Returns a NSRange instance that covers the entire string (Location = 0, Length = Full)
    ///
    var rangeOfEntireString: NSRange {
        return NSRange(location: 0, length: length)
    }


    /// Returns the NSRange that contains a specified position.
    ///
    /// - Parameter atIndex: Text location for which we want the line range.
    ///
    /// - Returns: The text's line range, at the specified position, if possible.
    ///
    func rangeOfLine(atIndex index: Int) -> NSRange? {
        var range: NSRange?

        foundationString.enumerateSubstringsInRange(rangeOfEntireString, options: .ByLines) { (substring, substringRange, enclosingRange, stop) in
            guard index >= enclosingRange.location && index < NSMaxRange(enclosingRange) else {
                return
            }

            range = enclosingRange
            stop.memory = true
        }

        return range
    }


    /// Return the contents of a TextList following the specified index (inclusive).
    /// Used to retrieve list items that need to be renumbered.
    ///
    /// - Parameter index: An index intersecting a TextList.
    ///
    /// - Returns: An NSAttributedString optional containing the list from the specified range or nil if no list was found.
    ///
    func textListContents(followingIndex index: Int) -> NSAttributedString? {
        guard let listRange = rangeOfTextList(atIndex: index) else {
            return nil
        }

        let diff = index - listRange.location
        let subRange = NSRange(location: index, length: listRange.length - diff)
        return attributedSubstringFromRange(subRange)
    }


    /// Returns the TextList attribute at the specified NSRange, if any.
    ///
    /// - Parameter index: The index at which to inspect.
    ///
    /// - Returns: A TextList optional.
    ///
    func textListAttribute(atIndex index: Int) -> TextList? {
        return attribute(TextList.attributeName, atIndex: index, effectiveRange: nil) as? TextList
    }


    /// Returns the TextList attribute, assuming that there is one, spanning the specified Range.
    ///
    /// - Parameter range: Range to check for TextLists
    ///
    /// - Returns: A TextList optional.
    ///
    func textListAttribute(spanningRange range: NSRange) -> TextList? {
        var effectiveRange = NSRange()
        guard let list = attribute(TextList.attributeName, atIndex: range.location, effectiveRange: &effectiveRange) as? TextList else {
            return nil
        }

        guard NSEqualRanges(range, NSIntersectionRange(range, effectiveRange)) else {
            return nil
        }

        return list
    }


    /// Finds the paragraph ranges in the specified string intersecting the specified range.
    ///
    /// - Parameters range: The range within the specified string to find paragraphs.
    ///
    /// - Returns: An array containing an NSRange for each paragraph intersected by the specified range.
    ///
    func paragraphRanges(spanningRange range: NSRange) -> [NSRange] {
        var paragraphRanges = [NSRange]()
        let targetRange = rangeOfEntireString

        foundationString.enumerateSubstringsInRange(targetRange, options: .ByParagraphs) { (substring, substringRange, enclosingRange, stop) in
            // Stop if necessary.
            if enclosingRange.location >= NSMaxRange(range) {
                stop.memory = true
                return
            }

            // Bail early if the paragraph precedes the start of the selection
            if NSMaxRange(enclosingRange) <= range.location {
                return
            }

            paragraphRanges.append(enclosingRange)
        }

        return paragraphRanges
    }


    /// Returns all of the paragraphs, spanning at the specified index, with the given TextList Kind.
    ///
    /// - Parameters:
    ///     - index: The index at which to inspect.
    ///     - style: The type of TextList.
    ///
    /// - Return: A NSRange collection containing the paragraphs with the specified TextList Kind.
    ///
    func paragraphRanges(atIndex index: Int, matchingListStyle style: TextList.Style) -> [NSRange] {
        guard index >= 0 && index < length, let range = rangeOfTextList(atIndex: index),
            let list = textListAttribute(atIndex: index) where list.style == style else
        {
            return []
        }

        return paragraphRanges(spanningRange: range)
    }


    /// Given a collection of Ranges, this helper will attempt to infer if the previous + following
    /// paragraphs contain a TextList, of the specified kind.
    /// If so, their ranges will be returned along with the received ranges, in a sorted fashion.
    ///
    /// - Parameters:
    ///     - ranges: Ranges that should be checked
    ///     - kind: Kind of list to look for
    ///
    /// - Returns: A collection of sorted NSRange's
    ///
    func paragraphRanges(preceedingAndSucceding ranges: [NSRange], matchingListStyle style: TextList.Style) -> [NSRange] {
        guard let firstRange = ranges.first, lastRange = ranges.last else {
            return ranges
        }

        // Check preceding + following paragraphs style for same kind of list & same list level.
        // If found add those paragraph ranges.
        let preceedingIndex = firstRange.location - 1
        let followingIndex = NSMaxRange(lastRange)
        var adjustedRanges = ranges

        for index in [preceedingIndex, followingIndex] {
            for range in paragraphRanges(atIndex: index, matchingListStyle: style) {
                guard adjustedRanges.contains({ NSEqualRanges($0, range)}) == false else {
                    continue
                }

                adjustedRanges.append(range)
            }
        }

        // Make sure the ranges are sorted in ascending order
        return adjustedRanges.sort {
            $0.location < $1.location
        }
    }


    /// Returns a new NSAttributedString, with the required TextListItem attribute applied.
    ///
    /// - Parameters:
    ///     - style: The type of text list.
    ///     - itemNumber: The index of the item. This is used to number a numeric list item.
    ///
    /// - Return: An NSAttributedString.
    ///
    func attributedStringByApplyingListItemAttributes(ofStyle style: TextList.Style, withNumber number: Int) -> NSAttributedString {
        // Begin by removing any existing list marker.
        guard let output = attributedStringByRemovingListItemAttributes().mutableCopy() as? NSMutableAttributedString else {
            return self
        }

        // TODO: Need to accomodate RTL languages too.

        // Insert the range at the beginning of the string. 
        // NOTE: We insert this as a plain string, so that Paragraph + Font styles get inherited.
        //
        let markerText = style.markerText(forItemNumber: number)
        output.replaceCharactersInRange(NSRange.zero, withString: markerText)

        // Apply Item Marker
        let markerAttribute = TextListItemMarker()
        let markerRange = output.foundationString.rangeOfString(markerText)

        output.addAttribute(TextListItemMarker.attributeName, value: markerAttribute, range: markerRange)

        // Set the attributes for the list item style
        let listItem = TextListItem(number: number)

        let listItemAttributes: [String: AnyObject] = [
            TextListItem.attributeName: listItem,
            NSParagraphStyleAttributeName: NSParagraphStyle.Aztec.defaultParagraphStyle
        ]

        output.addAttributes(listItemAttributes, range: output.rangeOfEntireString)

        return output
    }

    /// Returns a new Attributed String, with the TextListItem formatting removed.
    ///
    func attributedStringByRemovingListItemAttributes() -> NSAttributedString {
        let clean = NSMutableAttributedString(attributedString: self)

        let range = clean.rangeOfEntireString
        let attributes = [TextList.attributeName, TextListItem.attributeName]

        for name in attributes {
            clean.removeAttribute(name, range: range)
        }

        // Fall back to TextKit's default Paragraph Style
        let paragraphStyle = NSParagraphStyle()
        clean.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: range)

        // Nuke the Marker
        var markerRange = NSRange()
        if let _ = clean.attribute(TextListItemMarker.attributeName, atIndex: 0, longestEffectiveRange: &markerRange, inRange: range) {
            clean.replaceCharactersInRange(markerRange, withString: String())
        }

        return clean
    }

    /// Internal convenience helper. Returns the internal string as a NSString instance
    ///
    private var foundationString: NSString {
        return string as NSString
    }
}
