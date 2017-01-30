import Foundation

extension NSAttributedString {
    
    // MARK: - Range mapping by attribute filtering
    
    /// Maps a range by subtracting the length of all instanced of a specified attribute in that
    /// range.
    ///
    /// - Parameters:
    ///     - initialRange: the range to map.
    ///     - attributeName: the attribute to subract from the provided range.
    ///
    /// - Returns: the mapped range.
    ///
    func map(range initialRange: NSRange, bySubtractingAttributeNamed attributeName: String) -> NSRange? {

        // We need to also inspect anything before initialRange, because attributes in that range
        // affect the mapping as well.
        //
        let rangeToInspect = NSRange(location: 0, length: initialRange.location + initialRange.length)
        let ranges = self.ranges(forAttributeNamed: attributeName, within: rangeToInspect)
        
        guard ranges.count > 0 else {
            return initialRange
        }
        
        var mappedRange = initialRange

        for range in ranges.reversed() {

            guard !range.contains(range: mappedRange) else {
                // This means the full visual range was visual-only, and there's really nothing
                // to map.
                //
                return nil
            }

            let rangeEndLocation = range.location + range.length
            let mappedRangeEndLocation = mappedRange.location + mappedRange.endLocation

            if rangeEndLocation <= mappedRange.location {
                mappedRange.location = mappedRange.location - range.length
            } else if range.location < mappedRange.location && mappedRange.location < rangeEndLocation {

                // Order of execution is important in the next 2 lines, as mappedRange.location
                // is read first and written-to afterwards.
                //
                mappedRange.length = mappedRangeEndLocation - rangeEndLocation
                mappedRange.location = range.location
            } else {
                mappedRange.length = mappedRange.length - range.length
            }
        }
        
        return mappedRange
    }

    
    // MARK: - Finding attribute ranges
    
    /// Determine the ranges in which an attribute is present.
    ///
    /// - Parameters:
    ///     - attributeName: the name of the attribute to find the ranges of.
    ///     - range: the subrange in which the search will be performed.  All found ranges will
    ///         be inside this range.
    ///
    /// - Returns: an array of ranges where the attribute can be found
    ///
    func ranges(forAttributeNamed attributeName: String) -> [NSRange] {
        return ranges(forAttributeNamed: attributeName, within: NSRange(location: 0, length: length))
    }
    
    /// Determine the ranges in which an attribute is present.
    ///
    /// - Parameters:
    ///     - attributeName: the name of the attribute to find the ranges of.
    ///     - range: the subrange in which the search will be performed.  All found ranges will
    ///         be inside this range.
    ///
    /// - Returns: an array of ranges where the attribute can be found
    ///
    func ranges(forAttributeNamed attributeName: String, within range: NSRange) -> [NSRange] {
        var result = [NSRange]()
        
        enumerateAttribute(attributeName, in: range, options: []) { (matchingValue, matchingRange, nil) in
            guard matchingValue != nil else {
                return
            }
        
            result.append(matchingRange)
        }
        
        return result
    }
}
