import UIKit


// MARK: - NSLayoutManager Helpers
//
extension NSLayoutManager {

    /// Invalidates the layout for an attachment when some change happened to it.
    ///
    func invalidateLayout(for attachment: NSTextAttachment) {
        guard let ranges = textStorage?.ranges(forAttachment: attachment) else {
            return
        }

        for range in ranges {
            invalidateLayout(forCharacterRange: range, actualCharacterRange: nil)
            invalidateDisplay(forCharacterRange: range)
        }
    }

    /// Ensures the layout for all of the TextContainers.
    ///
    func ensureLayoutForContainers() {
        for textContainer in textContainers {
            ensureLayout(for: textContainer)
        }
    }
}
