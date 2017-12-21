import UIKit


/// For any object that converts an element into an attachment.
///
protocol AttachmentElementConverter {
    associatedtype AttachmentType: NSTextAttachment
    
    func convert(_ element: ElementNode, inheriting attributes: [AttributedStringKey: Any]) -> (attachment: AttachmentType, string: NSAttributedString)
}

