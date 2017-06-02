import Foundation
import UIKit


// MARK: - NSAttributedString Lists Helpers
//
extension NSAttributedString
{
    /// Check if the location passed is the beggining of a new list line.
    ///
    /// - Parameter location: the position to check
    /// - Returns: true if beggining of a new line false otherwise
    ///
    func isStartOfNewListItem(atLocation location: Int) -> Bool {
        var isStartOfListItem = attribute(NSParagraphStyleAttributeName, at: location, effectiveRange: nil) != nil
        var isStartOfLine = length == 0 || location == 0
        if length > 0 && location > 0 {
            let previousRange = NSRange(location: location - 1, length: 1)
            let previousString = attributedSubstring(from: previousRange)
            isStartOfLine = previousString.string.isEndOfLine()
            isStartOfListItem = previousString.textListAttribute(atIndex: 0) != nil
        }
        return isStartOfLine && isStartOfListItem
    }

    /// Given a collection of NSRange's, this method will filter all of those that contain a TextList, and
    /// don't match the specified Style.
    ///
    /// - Parameters:
    ///     - ranges: Ranges to be filtered
    ///     - style: Style to be matched
    ///
    /// - Returns: A subset of the input ranges that don't contain TextLists matching the input style.
    ///
    func filterListRanges(_ ranges: [NSRange], notMatchingStyle style: TextList.Style) -> [NSRange] {
        return ranges.filter { range in
            let list = textListAttribute(spanning: range)
            return list == nil || list?.style == style
        }
    }

    /// Get the range of a TextList containing the specified index.
    ///
    /// - Parameter index: An index intersecting a TextList.
    ///
    /// - Returns: An NSRange optional containing the range of the list or nil if no list was found.
    ///
    func rangeOfTextList(atIndex index: Int) -> NSRange? {
        guard let textList = textListAttribute(atIndex: index) else {
            return nil
        }

        return range(of: textList, at: index)
    }

    /// Returns the range of the given text list that contains the given location.
    ///
    /// - Parameter list: The textList to search for.
    /// - Parameter location: The location in the text list.
    ///
    /// - Returns: An NSRange optional containing the range of the list or nil if no list was found.
    ///
    func range(of list: TextList, at location: Int) -> NSRange? {

        var effectiveRange = NSRange()
        let targetRange = rangeOfEntireString
        guard
            let paragraphStyle = attribute(NSParagraphStyleAttributeName, at: location, longestEffectiveRange: &effectiveRange, in: targetRange) as? ParagraphStyle,
            let foundList = paragraphStyle.textLists.last,
            foundList == list
        else {
            return nil
        }
        let listDepth = paragraphStyle.textLists.count

        var resultRange = effectiveRange
        //Note: The effective range will only return the range of the in location NSParagraphStyleAttributed 
        // but this can be different on preceding or suceeding range but is the same TextList, 
        // so we need to expand the range to grab all the TextList coverage.
        while resultRange.location > 0 {
            guard
                let paragraphStyle = attribute(NSParagraphStyleAttributeName, at: resultRange.location-1, longestEffectiveRange: &effectiveRange, in: targetRange) as? ParagraphStyle,
                let foundList = paragraphStyle.textLists.last
            else {
                    break;
            }
            if ((listDepth == paragraphStyle.textLists.count && foundList == list) ||
                listDepth < paragraphStyle.textLists.count) {
               resultRange = resultRange.union(withRange: effectiveRange)
            } else {
                break;
            }
        }
        while resultRange.endLocation < self.length {
            guard
                let paragraphStyle = attribute(NSParagraphStyleAttributeName, at: resultRange.endLocation, longestEffectiveRange: &effectiveRange, in: targetRange) as? ParagraphStyle,
                let foundList = paragraphStyle.textLists.last
            else {
                break;
            }
            if ((listDepth == paragraphStyle.textLists.count && foundList == list) ||
                listDepth < paragraphStyle.textLists.count) {
                resultRange = resultRange.union(withRange: effectiveRange)
            } else {
                break;
            }
        }

        return resultRange
    }

    /// Returns the index of the item at the given location within the list.
    ///
    /// - Parameters:
    ///   - list: The list.
    ///   - location: The location of the item.
    ///
    /// - Returns: Returns the index within the list.
    ///
    func itemNumber(in list: TextList, at location: Int) -> Int {
        guard
            let paragraphStyle = attribute(NSParagraphStyleAttributeName, at: location, effectiveRange: nil) as? ParagraphStyle
            else {
                return NSNotFound
        }
        let listDepth = paragraphStyle.textLists.count
        guard let rangeOfList = range(of:list, at: location) else {
            return NSNotFound
        }
        var numberInList = 1
        let paragraphRanges = self.paragraphRanges(spanning: rangeOfList)

        for range in paragraphRanges {
            if NSLocationInRange(location, range) {
                return numberInList
            }
            if let paragraphStyle = attribute(NSParagraphStyleAttributeName, at: range.location, effectiveRange: nil) as? ParagraphStyle,
               listDepth == paragraphStyle.textLists.count {
                numberInList += 1
            }
        }
        return NSNotFound
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

        foundationString.enumerateSubstrings(in: rangeOfEntireString, options: NSString.EnumerationOptions()) { (substring, substringRange, enclosingRange, stop) in
            guard index >= enclosingRange.location && index < NSMaxRange(enclosingRange) else {
                return
            }

            range = enclosingRange
            stop.pointee = true
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
        return attributedSubstring(from: subRange)
    }


    /// Returns the TextList attribute at the specified NSRange, if any.
    ///
    /// - Parameter index: The index at which to inspect.
    ///
    /// - Returns: A TextList optional.
    ///
    func textListAttribute(atIndex index: Int) -> TextList? {
        return (attribute(NSParagraphStyleAttributeName, at: index, effectiveRange: nil) as? ParagraphStyle)?.textLists.last
    }

    /// Returns the TextList attribute, assuming that there is one, spanning the specified Range.
    ///
    /// - Parameter range: Range to check for TextLists
    ///
    /// - Returns: A TextList optional.
    ///
    func textListAttribute(spanning range: NSRange) -> TextList? {
        // NOTE:
        // We're using this mechanism, instead of the old fashioned 'attribute:atIndex:effectiveRange:' because
        // whenever the "next substring" has a different set of attributes, the effective range gets cut, even though
        // the attribute is present in the neighbor!
        //
        var list: TextList?

        enumerateAttribute(NSParagraphStyleAttributeName, in: range, options: []) { (attribute, range, stop) in
            if let paragraphStyle = attribute as? ParagraphStyle {
                list = paragraphStyle.textLists.last
            }
            stop.pointee = true
        }

        return list
    }

    func paragraphRanges(includeParagraphSeparator: Bool = true) -> [NSRange] {
        return paragraphRanges(spanning: rangeOfEntireString, includeParagraphSeparator: includeParagraphSeparator)
    }

    /// Finds the paragraph ranges in the specified string intersecting the specified range.
    ///
    /// - Parameters range: The range within the specified string to find paragraphs.
    ///
    /// - Returns: An array containing an NSRange for each paragraph intersected by the specified range.
    ///
    func paragraphRanges(spanning range: NSRange, includeParagraphSeparator: Bool = true) -> [NSRange] {
        var paragraphRanges = [NSRange]()
        let swiftRange = string.range(fromUTF16NSRange: range)

        string.enumerateSubstrings(in: swiftRange, options: .byParagraphs) { [unowned self] (substring, substringRange, enclosingRange, stop) in
            let paragraphRange = includeParagraphSeparator ? enclosingRange : substringRange
            paragraphRanges.append(self.string.utf16NSRange(from: paragraphRange))
        }

        return paragraphRanges
    }

    /// Returns the range of characters representing the paragraph or paragraphs containing a given range.
    ///
    /// This is an attributed string wrapper for `NSString.paragraphRangeForRange()`
    ///
    func paragraphRange(for range: NSRange) -> NSRange {
        let swiftRange = string.range(fromUTF16NSRange: range)
        let outRange = string.paragraphRange(for: swiftRange)

        return string.utf16NSRange(from: outRange)
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
            let list = textListAttribute(atIndex: index), list.style == style else
        {
            return []
        }

        return paragraphRanges(spanning: range)
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
        guard let firstRange = ranges.first, let lastRange = ranges.last else {
            return ranges
        }

        // Check preceding + following paragraphs style for same kind of list & same list level.
        // If found add those paragraph ranges.
        let preceedingIndex = firstRange.location - 1
        let followingIndex = NSMaxRange(lastRange)
        var adjustedRanges = ranges

        for index in [preceedingIndex, followingIndex] {
            for range in paragraphRanges(atIndex: index, matchingListStyle: style) {
                guard adjustedRanges.contains(where: { NSEqualRanges($0, range)}) == false else {
                    continue
                }

                adjustedRanges.append(range)
            }
        }

        // Check the ranges are sorted in ascending order
        return adjustedRanges.sorted {
            $0.location < $1.location
        }
    }

    /// Enumerates all of the paragraphs spanning a NSRange
    ///
    /// - Parameters:
    ///     - range: Range that should be checked for paragraphs
    ///     - block: Closure to be executed for each paragraph
    ///
    func enumerateParagraphs(spanning range: NSRange, includeParagraphSeparator: Bool = false, using block: ((NSRange, NSAttributedString) -> Void)) {
        for range in paragraphRanges(spanning: range, includeParagraphSeparator: includeParagraphSeparator) {
            block(range, attributedSubstring(from: range))
        }
    }

    /// Internal convenience helper. Returns the internal string as a NSString instance
    ///
    var foundationString: NSString {
        return string as NSString
    }
}
