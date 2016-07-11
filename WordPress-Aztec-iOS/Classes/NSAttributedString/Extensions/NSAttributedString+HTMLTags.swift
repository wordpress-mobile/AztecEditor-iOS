import Foundation

extension NSAttributedString {

    func tagsAtIndex(index: Int) -> [String: HTMLTagMetaData] {

        var tags = [String: HTMLTagMetaData]()

        attributesAtIndex(0, effectiveRange: nil).forEach { (key, value) in
            if let tagValue = value as? HTMLTagMetaData {
                tags[key] = tagValue
            }
        }

        return tags
    }

    /// Returns the first HTML tag for the specified range.
    ///
    func firstTag(forRange desiredRange: NSRange) -> HTMLTagMetaData? {

        let tags = tagsAtIndex(desiredRange.location)

        guard tags.count > 0 else {
            return nil
        }

        let fullRange = NSRange(location: 0, length: length)
        var tagRange = NSRange()

        for (tagKey, tagValue) in tags {
            attribute(tagKey, atIndex: 0, longestEffectiveRange: &tagRange, inRange: fullRange)

            if NSEqualRanges(tagRange, desiredRange) && tagValue.previous == nil {
                return tagValue
            }
        }

        return nil
    }
}