import Foundation

extension String.UTF16View {

    /// Converts a UTF16 `NSRange` into a `Range<String.UTF16View.Index>` for this string.
    ///
    /// - Parameters:
    ///     - nsRange: the UTF16 NSRange to convert.
    ///
    /// - Returns: the requested `Range<String.UTF16View.Index>` or `nil` if the conversion fails.
    ///
    func range(from nsRange: NSRange) -> Range<String.UTF16View.Index> {
        let start = index(startIndex, offsetBy: nsRange.location)
        let offset = count < nsRange.length ? count : nsRange.length
        let end = index(start, offsetBy: offset)

        return start ..< end
    }
}
