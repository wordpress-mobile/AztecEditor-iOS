import UIKit


/// For any object that converts an element into an attachment.
///
protocol AttachmentElementConverter {
    associatedtype T: NSTextAttachment
    
    func convert(_ element: ElementNode, inheriting attributes: [AttributedStringKey: Any]) -> (attachment: T, string: NSAttributedString)
}

