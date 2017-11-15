import Foundation


// MARK: - String NSRange and Location convertion Extensions
//
public extension String {
    
    func compatibleSubstring(with range: Range<String.Index>) -> String {
        #if swift(>=4.0)
            return String(self[range])
        #else
            return self.substring(with: range)
        #endif
    }

    /// Converts a UTF16 NSRange into a Swift String NSRange for this string.
    ///
    /// - Parameters:
    ///     - nsRange: the UTF16 NSRange to convert.
    ///
    /// - Returns: the requested `Swift String NSRange`
    ///
    func nsRange(fromUTF16NSRange nsRange: NSRange) -> NSRange? {

        let utf16Range = utf16.range(from: nsRange)

        guard let range = range(from: utf16Range) else {
            return nil
        }

        let location = distance(from: startIndex, to: range.lowerBound)
        let length = distance(from: range.lowerBound, to: range.upperBound)

        return NSRange(location: location, length: length)
    }

    /// Converts a Swift String NSRange into a UTF16 NSRange for this string.
    ///
    /// - Parameters:
    ///     - nsRange: the Swift String NSRange to convert.
    ///
    /// - Returns: the requested `UTF16 NSRange`
    ///
    func utf16NSRange(from nsRange: NSRange) -> NSRange {
        let swiftRange = range(from: nsRange)
        let utf16NSRange = self.utf16NSRange(from: swiftRange)

        return utf16NSRange
    }

    /// Converts an NSRange into a `Range<String.Index>` for this string.
    ///
    /// - Parameters:
    ///     - nsRange: the NSRange to convert.
    ///
    /// - Returns: the requested `Range<String.Index>`
    ///
    func range(from nsRange: NSRange) -> Range<String.Index> {
        let lowerBound = index(startIndex, offsetBy: nsRange.location)
        let upperBound = index(lowerBound, offsetBy: nsRange.length)

        return lowerBound ..< upperBound
    }

    func range(fromUTF16NSRange utf16NSRange: NSRange) -> Range<String.Index> {

        let swiftUTF16Range = utf16.range(from: utf16NSRange)

        guard let swiftRange = range(from: swiftUTF16Range) else {
            fatalError("Out of bounds!")
        }

        return swiftRange
    }

    /// Converts a UTF16 NSRange into a `Range<String.Index>` for this string.
    ///
    /// - Parameters:
    ///     - nsRange: the UTF16 NSRange to convert.
    ///
    /// - Returns: the requested `Range<String.Index>`
    ///
    func range(from utf16Range: Range<String.UTF16View.Index>) -> Range<String.Index>? {
        guard let start = utf16Range.lowerBound.samePosition(in: self),
            let end = utf16Range.upperBound.samePosition(in: self) else {
                return nil
        }

        return start ..< end
    }

    func nsRange(of string: String) -> NSRange? {
        guard let range = self.range(of: string) else {
            return nil
        }

        return nsRange(from: range)
    }

    /// Converts a `Range<String.Index>` into an UTF16 NSRange.
    ///
    /// - Parameters:
    ///     - range: the range to convert.
    ///
    /// - Returns: the requested `NSRange`.
    ///
    func nsRange(from range: Range<String.Index>) -> NSRange {

        let location = distance(from: startIndex, to: range.lowerBound)
        let length = distance(from: range.lowerBound, to: range.upperBound)

        return NSRange(location: location, length: length)
    }

    /// Converts a `Range<String.Index>` into an UTF16 NSRange.
    ///
    /// - Parameters:
    ///     - range: the range to convert.
    ///
    /// - Returns: the requested `NSRange`.
    ///
    func utf16NSRange(from range: Range<String.Index>) -> NSRange {

        guard let lowerBound = range.lowerBound.samePosition(in: utf16),
            let upperBound = range.upperBound.samePosition(in: utf16) else
        {
            fatalError()
        }

        let location = utf16.distance(from: utf16.startIndex, to: lowerBound)
        let length = utf16.distance(from: lowerBound, to: upperBound)

        return NSRange(location: location, length: length)
    }

    /// Returns a NSRange with a starting location at the very end of the string
    ///
    func endOfStringNSRange() -> NSRange {
        return NSRange(location: count, length: 0)
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
        guard let after16 = afterIndex.samePosition(in: utf16) else {
            return nil
        }

        return utf16.distance(from: utf16.startIndex, to: after16)
    }

    func location(before: Int) -> Int? {
        guard let currentIndex = indexFromLocation(before), currentIndex != startIndex else {
            return nil
        }

        let beforeIndex = index(before: currentIndex)
        guard let before16 = beforeIndex.samePosition(in: utf16) else {
            return nil
        }

        return utf16.distance(from: utf16.startIndex, to: before16)
    }

    func range(_ range: Range<String.Index>, offsetBy offset: String.IndexDistance) -> Range<String.Index> {

        let startIndex = index(range.lowerBound, offsetBy: offset)
        let endIndex = index(range.upperBound, offsetBy: offset)

        return startIndex ..< endIndex
    }
}
