import Foundation

extension String {

    /// Maps the specified visual range to a DOM Range.
    ///
    /// - Note: this method assumes the provided range is a UTF16 range, since NSAttributedString
    ///     provides that.
    ///
    /// - Parameters:
    ///     - range the visual range to map
    ///
    /// - Returns: the mapped range.
    ///
    func map(visualRange: NSRange) -> NSRange {
        return map(utf16NSRange: visualRange, byFiltering: String(.paragraphSeparator))
    }
}
