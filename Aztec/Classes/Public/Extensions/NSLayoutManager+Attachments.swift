import UIKit

extension NSLayoutManager
{
    /// Invalidates the layout for an attachment when some change happened to it.
    public func invalidateLayoutForAttachment(attachment: NSTextAttachment) {
        guard let ranges = textStorage?.ranges(forAttachment: attachment) else {
            return
        }
        for range in ranges {
            invalidateLayoutForCharacterRange(range, actualCharacterRange: nil)
            invalidateDisplayForCharacterRange(range)
        }
    }
}
