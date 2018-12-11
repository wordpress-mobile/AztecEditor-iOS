import Foundation
import UIKit


// MARK: - NSAttributedString Lists Helpers
//
extension NSAttributedString {
    
    /// Internal convenience helper. Returns the internal string as a NSString instance
    ///
    var foundationString: NSString {
        return string as NSString
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
            let paragraphStyle = attribute(.paragraphStyle, at: location, longestEffectiveRange: &effectiveRange, in: targetRange) as? ParagraphStyle,
            let foundList = paragraphStyle.lists.last,
            foundList == list
        else {
            return nil
        }
        let listDepth = paragraphStyle.lists.count

        var resultRange = effectiveRange
        //Note: The effective range will only return the range of the in location NSParagraphStyleAttributed 
        // but this can be different on preceding or suceeding range but is the same TextList, 
        // so we need to expand the range to grab all the TextList coverage.
        while resultRange.location > 0 {
            guard
                let paragraphStyle = attribute(.paragraphStyle, at: resultRange.location-1, longestEffectiveRange: &effectiveRange, in: targetRange) as? ParagraphStyle,
                let foundList = paragraphStyle.lists.last
            else {
                    break;
            }
            if ((listDepth == paragraphStyle.lists.count && foundList == list) ||
                listDepth < paragraphStyle.lists.count) {
               resultRange = resultRange.union(withRange: effectiveRange)
            } else {
                break;
            }
        }
        while resultRange.endLocation < self.length {
            guard
                let paragraphStyle = attribute(.paragraphStyle, at: resultRange.endLocation, longestEffectiveRange: &effectiveRange, in: targetRange) as? ParagraphStyle,
                let foundList = paragraphStyle.lists.last
            else {
                break;
            }
            if ((listDepth == paragraphStyle.lists.count && foundList == list) ||
                listDepth < paragraphStyle.lists.count) {
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
            let paragraphStyle = attribute(.paragraphStyle, at: location, effectiveRange: nil) as? ParagraphStyle
            else {
                return NSNotFound
        }
        let listDepth = paragraphStyle.lists.count
        guard let rangeOfList = range(of:list, at: location) else {
            return NSNotFound
        }
        var numberInList = 1
        let paragraphRanges = self.paragraphRanges(intersecting: rangeOfList)

        for (_, enclosingRange) in paragraphRanges {
            if NSLocationInRange(location, enclosingRange) {
                return numberInList
            }
            if let paragraphStyle = attribute(.paragraphStyle, at: enclosingRange.location, effectiveRange: nil) as? ParagraphStyle,
               listDepth == paragraphStyle.lists.count {
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

    /// Returns the TextList attribute at the specified NSRange, if any.
    ///
    /// - Parameter index: The index at which to inspect.
    ///
    /// - Returns: A TextList optional.
    ///
    func textListAttribute(atIndex index: Int) -> TextList? {
        return (attribute(.paragraphStyle, at: index, effectiveRange: nil) as? ParagraphStyle)?.lists.last
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

        enumerateAttribute(.paragraphStyle, in: range, options: []) { (attribute, range, stop) in
            if let paragraphStyle = attribute as? ParagraphStyle {
                list = paragraphStyle.lists.last
            }
            stop.pointee = true
        }

        return list
    }
}
