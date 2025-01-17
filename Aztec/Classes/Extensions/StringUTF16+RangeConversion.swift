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
      // Ensure location is non-negative and within bounds
      let validLocation = Swift.max(0, Swift.min(nsRange.location, count))
      // Ensure length does not exceed bounds from the valid location
      let validLength = Swift.max(0, Swift.min(nsRange.length, count - validLocation))

      let start = index(startIndex, offsetBy: validLocation)
      let end = index(start, offsetBy: validLength) // Safe offset calculation

      return start ..< end
    }
}
