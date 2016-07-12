import Foundation

extension NSAttributedString {

    /// Returns the first HTML tag for the specified range.
    ///
    func firstTag(matchingRange range: NSRange) -> HTMLTagMetaData? {

        let tags = tagsAtIndex(range.location)

        guard tags.count > 0 else {
            return nil
        }

        let fullRange = NSRange(location: 0, length: length)
        var tagRange = NSRange()

        for (tagKey, tagValue) in tags {
            if let attribute = attribute(tagKey, atIndex: 0, longestEffectiveRange: &tagRange, inRange: fullRange) {
                if NSEqualRanges(tagRange, range) && tagValue.parent == nil {
                    return tagValue
                }
            }
        }

        return nil
    }

    /// Returns the first HTML tag inside the specified range.
    ///
    func firstTag(insideRange range: NSRange) -> HTMLTagMetaData? {

        let tags = tagsInRange(range)

        guard tags.count > 0 else {
            return nil
        }

        let fullRange = NSRange(location: 0, length: length)
        var tagRange = NSRange()
        var bestLocation = Int.max
        var bestTag: HTMLTagMetaData? = nil

        enumerateAttributesInRange(range, options: NSAttributedStringEnumerationOptions(rawValue: 0)) { (attributes, attributesRange, stop) in
            for attributeData in attributes {
                if let tagValue = attributeData.1 as? HTMLTagMetaData {
                    let tagKey = attributeData.0

                    if let attribute = self.attribute(tagKey, atIndex: attributesRange.location, longestEffectiveRange: &tagRange, inRange: fullRange) {
                        
                        var isGoodCandidateForFirstTag =
                            NSLocationInRange(tagRange.location, range)
                                && tagRange.location > range.location
                                && tagRange.location < bestLocation
                                && tagValue.parent == nil

                        if isGoodCandidateForFirstTag {
                            bestLocation = tagRange.location
                            bestTag = tagValue
                        }
                    }
                }
            }
        }/*

        for (tagKey, tagValue) in tags {
            if let attribute = attribute(tagKey, atIndex: 0, longestEffectiveRange: &tagRange, inRange: fullRange) {
                var isGoodCandidateForFirstTag =
                    NSLocationInRange(tagRange.location, range)
                    && tagRange.location > range.location
                    && tagRange.location < bestLocation
                    && tagValue.parent == nil

                if isGoodCandidateForFirstTag {
                    bestLocation = tagRange.location
                    bestTag = tagValue
                }
            }
        }*/

        return bestTag
    }

    func tagsAtIndex(index: Int) -> [String: HTMLTagMetaData] {

        var tags = [String: HTMLTagMetaData]()

        attributesAtIndex(0, effectiveRange: nil).forEach { (key, value) in
            if let tagValue = value as? HTMLTagMetaData {
                tags[key] = tagValue
            }
        }

        return tags
    }

    func tagsInRange(range: NSRange) -> [String: HTMLTagMetaData] {

        var tags = [String: HTMLTagMetaData]()

        enumerateAttributesInRange(range, options: NSAttributedStringEnumerationOptions(rawValue: 0)) { (attributes, range, stop) in
            for attribute in attributes {
                if let tag = attribute.1 as? HTMLTagMetaData {
                    tags[attribute.0] = tag
                }
            }
        }
        
        return tags
    }
}