import UIKit


/// For any object that converts an element into an attachment.
///
public protocol AttachmentElementConverter: ElementConverter {
    associatedtype AttachmentType: NSTextAttachment
    
    func convert(
        _ element: ElementNode,
        inheriting attributes: [NSAttributedString.Key: Any],
        childrenSerializer serializeChildren: ChildrenSerializer) -> (attachment: AttachmentType, string: NSAttributedString)
}

public extension AttachmentElementConverter {
    
    /// For most classes implementing this protocol, this is the default `convert` implementation from `ElementConverter`.
    ///
    func convert(
        _ element: ElementNode,
        inheriting attributes: [NSAttributedString.Key: Any],
        childrenSerializer serializeChildren: ChildrenSerializer) -> NSAttributedString {
        
        let (_, output) = convert(element, inheriting: attributes, childrenSerializer: serializeChildren)
        
        return output
    }
}

