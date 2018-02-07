import UIKit


/// For any object that converts an element into an attachment.
///
protocol AttachmentElementConverter: ElementConverter {
    associatedtype AttachmentType: NSTextAttachment
    
    func convert(_ element: ElementNode, inheriting attributes: [NSAttributedStringKey: Any]) -> (attachment: AttachmentType, string: NSAttributedString)
}

extension AttachmentElementConverter {
    
    /// For most classes implementing this protocol, this is the default `convert` implementation from `ElementConverter`.
    ///
    func convert(_ element: ElementNode, inheriting attributes: [NSAttributedStringKey: Any]) -> NSAttributedString {
        let (_, output) = convert(element, inheriting: attributes)
        
        return output
    }
}

