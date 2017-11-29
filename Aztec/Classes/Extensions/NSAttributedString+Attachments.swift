import Foundation
import UIKit


// MARK: - Constants
//
extension String {
    /// String containing the NSTextAttachment Character
    ///
    static let textAttachment = String(UnicodeScalar(NSAttachmentCharacter)!)
}


// MARK: - NSAttributedString Extension for Attachments
//
extension NSAttributedString
{
    /// Indicates the Attributed String Length of a single TextAttachment
    ///
    static let lengthOfTextAttachment = NSAttributedString(attachment: NSTextAttachment()).length



    /// Helper Initializer: returns an Attributed String, with the specified attachment, styled with a given
    /// collection of attributes.
    ///
    convenience init(attachment: NSTextAttachment, attributes: [AttributedStringKey: Any]) {
        var attributesWithAttachment = attributes
        attributesWithAttachment[.attachment] = attachment

        self.init(string: .textAttachment, attributes: attributesWithAttachment)
    }

    /// Loads any NSTextAttachment's lazy file reference, into a UIImage instance, in memory.
    ///
    func loadLazyAttachments() {
        enumerateAttachmentsOfType(NSTextAttachment.self) { (attachment, _, _) in
            guard let data = attachment.fileWrapper?.regularFileContents else {
                return
            }

            let scale = UIScreen.main.scale
            let image = UIImage(data: data, scale: scale)
            attachment.fileWrapper = nil
            attachment.image = image
        }
    }

    /// Enumerates all of the available NSTextAttachment's of the specified kind, in a given range.
    /// For each one of those elements, the specified block will be called.
    ///
    /// - Parameters:
    ///     - range: The range that should be checked. Nil wil cause the whole text to be scanned
    ///     - type: The kind of Attachment we're after
    ///     - block: Closure to be executed, for each one of the elements
    ///
    func enumerateAttachmentsOfType<T : NSTextAttachment>(_ type: T.Type, range: NSRange? = nil, block: ((T, NSRange, UnsafeMutablePointer<ObjCBool>) -> Void)) {
        let range = range ?? NSMakeRange(0, length)
        enumerateAttribute(.attachment, in: range, options: []) { (object, range, stop) in
            if let object = object as? T {
                block(object, range, stop)
            }
        }
    }

    /// Determine the character ranges for an attachment
    ///
    /// - Parameters:
    ///     - attachment: the attachment to search for
    ///
    /// - Returns: an array of ranges where the attachement can be found
    ///
    public func ranges(forAttachment attachment: NSTextAttachment) -> [NSRange] {
        let range = NSRange(location: 0, length: length)
        var attachmentRanges = [NSRange]()
        enumerateAttribute(.attachment, in: range, options: []) { (value, effectiveRange, nil) in
            guard let foundAttachment = value as? NSTextAttachment, foundAttachment == attachment else {
                return
            }
            attachmentRanges.append(effectiveRange)
        }
        
        return attachmentRanges
    }
}
