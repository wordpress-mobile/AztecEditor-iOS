import UIKit

/// A class for handling the formatting of ordered and unordered lists.
///
class ListFormatter
{

    /// Creates a new text list, or modifies an existing text list.
    ///
    /// - Parameters
    ///     - type: The type of list.
    ///     - range: The range at which to apply the list style.
    ///     - attrString: The NSMutableAttributed string to modify.
    ///
    /// - Returns: An NSRange representing the change to the attributed string.
    ///
    func listAction(type: TextListType, atRange range: NSRange, attributedString attrString: NSMutableAttributedString) -> NSRange? {
        // get selected paragraph ranges
        let ranges = paragraphRangesInString(attrString.string, spanningRange: range)
        guard let firstRange = ranges.first else {
            return nil
        }

        // Check first paragraphs attributes
        if let attr = textListAttributeInString(attrString, atIndex: firstRange.location) {
            // What kind of list is this?
            if attr.type == type {
                return removeTextListAttributeAtRanges(ranges, fromString: attrString)

            } else {
                // For different type of list, we'll change the list style (for the whole list).
                return updateListInString(attrString, atIndex: firstRange.location, withListType: type)
            }

        } else {
            // Not already a list.  Add the list style.

            // Check the paragraphs at each range. If any have the opposite list style remove that range.
            let filtered = ranges.filter({ (range) -> Bool in
                if let attr = textListAttributeInString(attrString, atIndex: range.location) {
                    if attr.type != type {
                        return false
                    }
                }
                return true
            })

            return applyTextListAttribute(type, atParagraphRanges: filtered, inAttributedString: attrString)
        }
    }


    /// Finds the paragraph ranges in the specified string intersecting the specified range.
    ///
    /// - Parameters:
    ///     - string: The string to inspect.
    ///     - range: The range within the specified string to find paragraphs.
    ///
    /// - Returns: An array containing an NSRange for each paragraph intersected
    /// by the specified range.
    ///
    func paragraphRangesInString(string: NSString, spanningRange range: NSRange) -> [NSRange] {
        var paragraphRanges = [NSRange]()

        string.enumerateSubstringsInRange(NSRange(location: 0, length: string.length),
                                          options: .ByParagraphs,
                                          usingBlock: { (substring, substringRange, enclosingRange, stop) in
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
        })
        return paragraphRanges
    }


    /// Returns the TextList attribute in the specified NSAttributedString at the
    /// specified NSRange, or nil if one does not exist.
    ///
    /// - Parameters:
    ///     - attrString: An NSAttributedString to inspect.
    ///     - index: The index at which to inspect.
    ///
    /// - Returns: A TextList optional.
    ///
    func textListAttributeInString(attrString: NSAttributedString, atIndex index: Int) -> TextList? {
        return attrString.attribute(TextList.attributeName, atIndex: index, effectiveRange: nil) as? TextList
    }


    /// Applies a TextList attribute to the specified paragraph ranges in the
    /// specified string. Each paragraph range is treated as a list item.
    ///
    /// - Parameters:
    ///     - type: The type of text list.
    ///     - ranges: The paragraph ranges to operate upon. Each range becomes a list item.
    ///     - attrString: The NSMutableAttributedString to manipulate.
    ///
    /// - Returns: The affected NSRange, or nil if no changes were made.
    ///
    func applyTextListAttribute(type: TextListType, atParagraphRanges ranges:[NSRange], inAttributedString attrString: NSMutableAttributedString) -> NSRange? {
        if ranges.count == 0 {
            return nil
        }

        // Mutable ranges
        var ranges = ranges

        guard
            let firstRange = ranges.first,
            let lastRange = ranges.last
            else {
                return nil
        }

        //- check preceding paragraph style for same kind of list & same list level.  If found add those paragraph ranges.
        var index = firstRange.location - 1
        ranges = addParagraphRangesInString(attrString, forListOfType: type, atIndex: index, toArray: ranges)


        //- check following paragraph style for same kind of list & same list level. If found add those paragraph ranges.
        index = NSMaxRange(lastRange)
        ranges = addParagraphRangesInString(attrString, forListOfType: type, atIndex: index, toArray: ranges)

        let startingLocation = ranges.first!.location
        var length = 0

        attrString.beginEditing()
        //- Filter out other elements (blockquote, p, h1, h2, h3, etc.) from each paragraph. Each “paragraph” should be vanilla
        // TODO:


        //- Iterate over affected paragraphs in reverse order.  Insert/replace list marker (attributes) into string and assign list item.
        for (idx, range) in ranges.enumerate().reverse() {
            let str = attrString.attributedSubstringFromRange(range)
            let mstr = setTextListItemStyleForType(type, toString: str, itemIndex: idx + 1)
            length += mstr.length
            attrString.replaceCharactersInRange(range, withAttributedString: mstr)
        }

        let listRange = NSRange(location: startingLocation, length: length)
        //- set list type attribute for whole list
        let textList = TextList()
        textList.type = type
        attrString.addAttribute(TextList.attributeName, value: textList, range: listRange)


        attrString.endEditing()

        return listRange
    }


    /// Applies TextListItem attributes and styling of the specified type to the 
    /// specified attributed string.
    ///
    /// - Parameters:
    ///     - type: The type of text list.
    ///     - attrString: The NSAttributedString to modify.
    ///     - index: The index of the item. This is used to number a numeric list item.
    ///
    /// - Return: An NSAttributedString.
    ///
    func setTextListItemStyleForType(type: TextListType, toString attrString: NSAttributedString, itemIndex index: Int) -> NSAttributedString {
        let mStr = NSMutableAttributedString(attributedString: attrString)

        // Remove any existing list marker.
        if mStr.length > 0 {
            let strRange = NSRange(location: 0, length: mStr.length)
            var markerRange = NSRange()
            if let _ = mStr.attribute(TextListItemMarker.attributeName, atIndex: 0, longestEffectiveRange: &markerRange, inRange: strRange) {
                mStr.removeAttribute(TextListItemMarker.attributeName, range: markerRange)
                mStr.replaceCharactersInRange(markerRange, withString: "")
            }
        }

        // TODO: Need to accomodate RTL languages too.

        // Add the correct list marker. (Tabs aren't really reliable for spacing. Need a better solution.)
        let marker = type == .Ordered ? "\(index).\t" : "\u{2022}\t\t"

        let listMarker = NSAttributedString(string: marker, attributes: [TextListItemMarker.attributeName: TextListItemMarker()])
        mStr.insertAttributedString(listMarker, atIndex: 0)

        // Set the attributes for the list item style
        // TODO: Need to be smarter about indents so we take into account nested lists. Need to figure out tabstops also.
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.firstLineHeadIndent = 0
        paragraphStyle.headIndent = 16 // TODO: Need to get whatever the actual tab width is, and use that as a multiplier.  Maybe we can limit the tab width also?
        // TODO: Quick and dirty just so we can have some control.  Need to clean this up and do it better.
        paragraphStyle.tabStops = [
            NSTextTab(textAlignment: .Natural, location: 8, options: [String : AnyObject]()),
            NSTextTab(textAlignment: .Natural, location: 16, options: [String : AnyObject]()),
            NSTextTab(textAlignment: .Natural, location: 24, options: [String : AnyObject]()),
            NSTextTab(textAlignment: .Natural, location: 32, options: [String : AnyObject]()),
            NSTextTab(textAlignment: .Natural, location: 64, options: [String : AnyObject]()),
        ]
        let attributes = [
            TextListItem.attributeName: TextListItem(),
            NSParagraphStyleAttributeName: paragraphStyle
            ] as [String: AnyObject]

        mStr.addAttributes(attributes, range: NSRange(location: 0, length: mStr.length))

        // return the formatted string
        return mStr
    }


    /// Check the specified attributed string for any paragraph ranges having the
    /// specified TextListType attribute at the specified index. If found add those
    /// paragraph ranges to those passed and return all the ranges, inorder, as an array.
    ///
    /// - Parameters:
    ///     - attrString: The NSAttributedString
    ///     - type: The type of TextList.
    ///     - index: The index at which to inspect.
    ///     - ranges: An array of NSRanges representing paragraphs in sorted ascending order.
    ///
    func addParagraphRangesInString(attrString: NSAttributedString, forListOfType type: TextListType, atIndex index: Int, toArray ranges:[NSRange]) -> [NSRange] {
        if index < 0 || index >= attrString.length {
            return ranges
        }

        var listRange = NSRange()
        guard let attr = attrString.attribute(TextList.attributeName, atIndex: index, longestEffectiveRange: &listRange, inRange: NSRange(location: 0, length: attrString.length)) as? TextList
            where attr.type == type
            else {
                return ranges
        }

        var adjustedRanges = ranges

        // Get the paragraph ranges of the list
        let paragraphRanges = paragraphRangesInString(attrString.string, spanningRange: listRange)

        // Add any new ranges
        for rng in paragraphRanges {
            if !adjustedRanges.contains({ NSEqualRanges($0, rng)}) {
                adjustedRanges.append(rng)
            }
        }

        // Make sure the ranges are sorted in ascending order
        adjustedRanges.sortInPlace { (rng1, rng2) -> Bool in
            rng1.location < rng2.location
        }

        return adjustedRanges
    }


    /// Removes TextList attributes from the specified ranges in the specified string.
    ///
    /// - Parameters:
    ///     - ranges: The ranges to modify.
    ///     - attrString: The NSMutableAttributed string to modify.
    ///
    /// - Returns: The NSRange of the changes.
    ///
    func removeTextListAttributeAtRanges(ranges: [NSRange], fromString attrString: NSMutableAttributedString) -> NSRange? {
        guard let firstRange = ranges.first else {
            return nil
        }

        var listRangeLength = 0
        for range in ranges {
            listRangeLength += range.length
        }
        let fullRange = NSRange(location: firstRange.location, length: listRangeLength)

        attrString.removeAttribute(TextList.attributeName, range: fullRange)
        attrString.removeAttribute(TextListItem.attributeName, range: fullRange)

        // For the same type of list, we'll remove the list style. A bit tricky.  We need to remove the style
        // (and attributes) from the selected paragraph ranges, then if the following range was an ordered list,
        // we need to update its markers. (Maybe some other attribute clean up?)

        var length = 0
        //- Iterate over affected paragraphs in reverse order.  Remove list marker and attributes
        for range in ranges.reverse() {
            let str = attrString.attributedSubstringFromRange(range)
            let mstr = removeTextListItemStyleFromString(str)
            length += mstr.length
            attrString.replaceCharactersInRange(range, withAttributedString: mstr)
        }

        let adjustedRange = NSRange(location: firstRange.location, length: length)
        attrString.fixAttributesInRange(adjustedRange)

        // Update the following list if necessary.
        let followingIdx = NSMaxRange(adjustedRange) + 1 // Add two. if just one we're pointing at the newline character and we'll end up captureing the paragraph range we just edited.
        if followingIdx < attrString.length {
            if let attr = textListAttributeInString(attrString, atIndex: followingIdx) {
                updateListInString(attrString, atIndex: followingIdx, withListType: attr.type)
            }
        }

        return adjustedRange
    }


    /// Removes TextListItem formatting from the specified attributed string.
    ///
    /// - Parameters:
    ///     attrString: The NSAttributedString to modify.
    ///
    /// - Returns: An NSAttributedString with the TextListItem formatting removed.
    ///
    func removeTextListItemStyleFromString(attrString: NSAttributedString) -> NSAttributedString {
        let mstr = NSMutableAttributedString(attributedString: attrString)

        let range = NSRange(location: 0, length: mstr.length)
        mstr.removeAttribute(TextList.attributeName, range: range)
        mstr.removeAttribute(TextListItem.attributeName, range: range)
        mstr.removeAttribute(NSParagraphStyleAttributeName, range: range)

        // TODO: Might need to account for other indentation.
        let paragraphStyle = NSParagraphStyle()
        mstr.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: range)

        var markerRange = NSRange()
        if let _ = mstr.attribute(TextListItemMarker.attributeName, atIndex: 0, longestEffectiveRange: &markerRange, inRange: range) {
            mstr.replaceCharactersInRange(markerRange, withString: "")
        }

        return mstr
    }


    /// Updates the TextListTpe for a TextList at the specified index.
    ///
    /// - Parameters:
    ///     - attrString: An NSMutableAttributedString to modify.
    ///     - index: An index intersecting the TextList within `attrString`.
    ///     - type: The type of list to become.
    ///
    func updateListInString(attrString: NSMutableAttributedString, atIndex index: Int, withListType type: TextListType) -> NSRange? {
        // For different type of list, we'll change the list style (for the whole list).
        var listRange = NSRange()

        // TODO: Confirm using longest effective range is actually safe. We don't want to consume neighboring lists of a different type. (NOTE: probably not an issue when searching for custom aztec markup attributes?)
        guard let _ = attrString.attribute(TextList.attributeName, atIndex: index, longestEffectiveRange: &listRange, inRange: NSRange(location: 0, length: attrString.length)) else {
            return nil
        }

        let paragraphRanges = paragraphRangesInString(attrString.string, spanningRange: listRange)
        return applyTextListAttribute(type, atParagraphRanges: paragraphRanges, inAttributedString: attrString)
    }

}
