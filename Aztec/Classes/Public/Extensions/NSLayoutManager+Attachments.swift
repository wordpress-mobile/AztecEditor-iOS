import UIKit

extension NSLayoutManager
{
    /// Determine the character ranges for an attachment
    public func ranges(forAttachment attachment: NSTextAttachment) -> [NSRange]
    {
        guard let attributedString = self.textStorage else
        {
            return []
        }

        // find character range for this attachment
        let range = NSRange(location: 0, length: attributedString.length)

        var refreshRanges = [NSRange]()

        attributedString.enumerateAttribute(NSAttachmentAttributeName, inRange: range, options: []) { (value, effectiveRange, nil) in

            guard let foundAttachment = value as? NSTextAttachment where foundAttachment == attachment else
            {
                return
            }

            // add this range to the refresh ranges
            refreshRanges.append(effectiveRange)
        }

        return refreshRanges
    }

    /// Invalidates the layout for an attachment when some change happened to it.
    public func invalidateLayoutForAttachment(attachment: NSTextAttachment) {

        for range in ranges(forAttachment: attachment) {
            invalidateLayoutForCharacterRange(range, actualCharacterRange: nil)
            invalidateDisplayForCharacterRange(range)
        }
    }
}
