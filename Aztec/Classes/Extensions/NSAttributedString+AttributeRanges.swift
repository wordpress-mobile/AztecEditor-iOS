import Foundation

extension NSAttributedString {
    
    // MARK: - Range mapping by attribute filtering
    
    /// Maps a range after filtering the specified attribute.
    ///
    /// - Parameters:
    ///     - initialRange: the range to map.
    ///     - attributeName: the attribute to filter from the initial range.
    ///
    /// - Returns: the mapped range.
    ///
    private func map(range initialRange: NSRange, byFilteringAttributeNamed attributeName: String) -> NSRange? {
        let ranges = self.ranges(forAttributeNamed: attributeName, within: initialRange)
        
        var mappedRange = initialRange
        let mappedRangeEndLocation = mappedRange.location + mappedRange.length
        
        for range in ranges.reversed() {
            let rangeEndLocation = range.location + range.length
            
            if rangeEndLocation <= mappedRange.location {
                mappedRange.location = mappedRange.location - range.length
            } else if range.location <= mappedRange.location && rangeEndLocation <= mappedRangeEndLocation {
                
                guard range.location != mappedRange.location && rangeEndLocation != mappedRangeEndLocation else {
                    // This means the full visual range was visual-only, and there's really nothing
                    // to map.
                    //
                    return nil
                }
                
                // Order of execution is important in the next 2 lines, as the length is updated
                // using the mappedRange location before it's updated.
                //
                mappedRange.length = mappedRangeEndLocation - mappedRange.location
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
    public func ranges(forAttributeNamed attributeName: String) -> [NSRange] {
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
    public func ranges(forAttributeNamed attributeName: String, within range: NSRange) -> [NSRange] {
        var result = [NSRange]()
        
        enumerateAttribute(attributeName, in: range, options: []) { (matchingAttributeName, matchingAttributeRange, nil) in
            guard let matchingAttributeName = matchingAttributeName as? String, matchingAttributeName == attributeName else {
                return
            }
            
            result.append(matchingAttributeRange)
        }
        
        return result
    }
}
