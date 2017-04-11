import Foundation


// MARK: - String NSRange and Location convertion Extensions
//
extension String
{
    /// Converts a UTF16 NSRange into a `Range<String.Index>` for this string.
    ///
    /// - Parameters:
    ///     - nsRange: the UTF16 NSRange to convert.
    ///
    /// - Returns: the requested `Range<String.Index>`
    ///
    func range(from nsRange : NSRange) -> Range<String.Index>? {
        let utf16Start = utf16.index(utf16.startIndex, offsetBy: nsRange.location)
        let utf16End = utf16.index(utf16Start, offsetBy: nsRange.length)

        guard
            let start = utf16Start.samePosition(in: self),
            let end = utf16End.samePosition(in: self) else {
                return nil
        }

        return start ..< end
    }

    /// Converts a `Range<String.Index>` into an UTF16 NSRange.
    ///
    /// - Parameters:
    ///     - range: the range to convert.
    ///
    /// - Returns: the requested `NSRange`.
    ///
    func nsRange(from range: Range<String.Index>) -> NSRange {

        let lowerBound = range.lowerBound.samePosition(in: utf16)
        let upperBound = range.upperBound.samePosition(in: utf16)

        let location = utf16.distance(from: utf16.startIndex, to: lowerBound)
        let length = utf16.distance(from: lowerBound, to: upperBound)

        return NSRange(location: location, length: length)
    }

    func indexFromLocation(_ location: Int) -> String.Index? {
        guard
            let unicodeLocation = utf16.index(utf16.startIndex, offsetBy: location, limitedBy: utf16.endIndex),
            let location = unicodeLocation.samePosition(in: self) else {
                return nil
        }

        return location
    }

    func isLastValidLocation(_ location: Int) -> Bool {
        if self.isEmpty {
            return false
        }
        return index(before: endIndex) == indexFromLocation(location)
    }

    func location(after: Int) -> Int? {
        guard let currentIndex = indexFromLocation(after), currentIndex != endIndex else {
            return nil
        }
        let afterIndex = index(after: currentIndex)
        let after16 = afterIndex.samePosition(in: utf16)
        return utf16.distance(from: utf16.startIndex, to: after16)
    }

    func location(before: Int) -> Int? {
        guard let currentIndex = indexFromLocation(before), currentIndex != startIndex else {
            return nil
        }

        let beforeIndex = index(before: currentIndex)
        let before16 = beforeIndex.samePosition(in: utf16)
        return utf16.distance(from: utf16.startIndex, to: before16)
    }
}
