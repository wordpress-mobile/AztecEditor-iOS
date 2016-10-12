import Foundation
import UIKit


// MARK: - NSAttributedString Extension for Attachments
//
extension NSAttributedString
{
    /// Enumerates all of the available NSTextAttachment's of the specified kind, in a given range.
    /// For each one of those elements, the specified block will be called.
    ///
    /// - Parameters:
    ///     - range: The range that should be checked. Nil wil cause the whole text to be scanned
    ///     - type: The kind of Attachment we're after
    ///     - block: Closure to be executed, for each one of the elements
    ///
    func enumerateAttachmentsOfType<T : NSTextAttachment>(type: T.Type, range: NSRange? = nil, block: ((T, NSRange, UnsafeMutablePointer<ObjCBool>) -> Void)) {
        let range = range ?? NSMakeRange(0, length)
        enumerateAttribute(NSAttachmentAttributeName, inRange: range, options: []) { (object, range, stop) in
            if let object = object as? T {
                block(object, range, stop)
            }
        }
    }

    /// Determine the character ranges for an attachment
    public func ranges(forAttachment attachment: NSTextAttachment) -> [NSRange]
    {
        // find character range for this attachment
        let range = NSRange(location: 0, length: length)

        var refreshRanges = [NSRange]()

        enumerateAttribute(NSAttachmentAttributeName, inRange: range, options: []) { (value, effectiveRange, nil) in

            guard let foundAttachment = value as? NSTextAttachment where foundAttachment == attachment else
            {
                return
            }

            // add this range to the refresh ranges
            refreshRanges.append(effectiveRange)
        }
        
        return refreshRanges
    }
}
