import UIKit

extension NSLayoutManager
{
    /// Invalidates the layout for an attachment when some change happened to it.
    public func invalidateLayoutForAttachment(_ attachment: NSTextAttachment) {
        guard let ranges = textStorage?.ranges(forAttachment: attachment) else {
            return
        }
        for range in ranges {
            invalidateLayout(forCharacterRange: range, actualCharacterRange: nil)
            invalidateDisplay(forCharacterRange: range)
        }
    }
}
