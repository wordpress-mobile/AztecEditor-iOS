import Foundation
import UIKit

public protocol BaseAttachmentToElementConverter {
    func convert(_ attachment: NSTextAttachment, attributes: [NSAttributedString.Key: Any]) -> [Node]?
}

/// Just a convenience base class to share some code.  It's recommended to inherit from this protocol
/// rather than from `BaseAttachmentToElementConverter`.
///
/// This protocol is separated to avoid type restrictions when adding the converter to
/// a collection.
///
public protocol AttachmentToElementConverter: BaseAttachmentToElementConverter {
    associatedtype Attachment: NSTextAttachment
    
    func cast(attachment: NSTextAttachment) -> Attachment?
    func convert(_ attachment: Attachment, attributes: [NSAttributedString.Key: Any]) -> [Node]
}

public extension AttachmentToElementConverter {
    func cast(attachment: NSTextAttachment) -> Attachment? {
        return attachment as? Attachment
    }
    
    func convert(_ attachment: NSTextAttachment, attributes: [NSAttributedString.Key: Any]) -> [Node]? {
        guard let castedAttachment = cast(attachment: attachment) else {
            return nil
        }
        
        // The `as [Node]` below is a hint for the compiler which was failing to select the proper method
        // and was resulting in an endless recursive call stack.
        return convert(castedAttachment, attributes: attributes) as [Node]
    }
}

