import Foundation

extension String {

    /// Maps the specified visual range to a DOM Range.
    ///
    /// - Parameters:
    ///     - range the visual range to map
    ///
    /// - Returns: the mapped range.
    ///
    func map(visualRange: NSRange) -> NSRange {
        return map(range: visualRange, byFiltering: String(.paragraphSeparator))
    }

    /// Maps the specified visual UTF16 range to a DOM Range.
    ///
    /// - Parameters:
    ///     - range the visual range to map
    ///
    /// - Returns: the mapped range.
    ///
    func map(visualUTF16Range: NSRange) -> NSRange {
        return map(utf16NSRange: visualUTF16Range, byFiltering: String(.paragraphSeparator))
    }
}
