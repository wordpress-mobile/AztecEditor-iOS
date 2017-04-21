import Foundation

extension String.UnicodeScalarView {

    /// Converts a Unicode Scalar `NSRange` into a `Range<String.UnicodeScalarView.Index>`
    /// for this string.
    ///
    /// - Parameters:
    ///     - nsRange: the range to convert.
    ///
    /// - Returns: the requested `Range<String.UnicodeScalarView.Index>`
    ///
    func range(from nsRange : NSRange) -> Range<String.UnicodeScalarView.Index>? {
        let start = index(startIndex, offsetBy: nsRange.location)
        let end = index(start, offsetBy: nsRange.length)

        return start ..< end
    }
}
