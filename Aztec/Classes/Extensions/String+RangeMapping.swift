import Foundation

extension String {

    // MARK: - Range mapping by character filtering

    func map(range initialRange: NSRange, byFiltering stringToFilter: String) -> NSRange {

        let convertedRange = range(from: initialRange)
        let finalRange = map(range: convertedRange, byFiltering: stringToFilter)

        return nsRange(from: finalRange)
    }

    /// Maps a `UnicodeScalar` range after filtering the specified string.
    ///
    /// - IMPORTANT: it's important to implement this method using unicode scalars, because we
    ///     want to map a range of characters, regardless of how those characters are stored.
    ///
    /// - Parameters:
    ///     - initialRange: the range to map.
    ///     - stringToFilter: the string that will be filtered from the receiver to perform the
    ///             range mapping.
    ///
    /// - Returns: the mapped range.
    ///
    func map(range initialRange: Range<String.Index>, byFiltering stringToFilter: String) -> Range<String.Index> {

        var rangeToInspect = startIndex ..< initialRange.upperBound
        var finalRange = initialRange

        while let matchRange = range(of: stringToFilter, options: .backwards, range: rangeToInspect) {

            if finalRange.clamped(to: matchRange) == finalRange {
                finalRange = matchRange.lowerBound ..< matchRange.lowerBound
                continue
            }

            if matchRange.upperBound <= finalRange.lowerBound {
                let distance = self.distance(from: matchRange.upperBound, to: matchRange.lowerBound)

                finalRange = range(finalRange, offsetBy: distance)
            } else if matchRange.lowerBound < finalRange.lowerBound && finalRange.lowerBound < matchRange.upperBound {
                let distance = self.distance(from: matchRange.upperBound, to: finalRange.upperBound)

                let startIndex = matchRange.lowerBound
                let endIndex = index(finalRange.upperBound, offsetBy: distance)

                finalRange = startIndex ..< endIndex
            } else {
                let matchRangeLength = self.distance(from: matchRange.lowerBound, to: matchRange.upperBound)
                let finalRangeLength = self.distance(from: finalRange.lowerBound, to: finalRange.upperBound)
                let distance = finalRangeLength - matchRangeLength

                let newUpperBound = index(finalRange.lowerBound, offsetBy: distance)

                finalRange = finalRange.lowerBound ..< newUpperBound
            }

            rangeToInspect = startIndex ..< matchRange.lowerBound
        }

        return finalRange.lowerBound ..< finalRange.upperBound
    }
}
