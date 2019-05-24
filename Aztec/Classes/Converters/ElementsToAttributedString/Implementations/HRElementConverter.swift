import UIKit


/// Returns a specialised representation for a `<hr>` element.
///
class HRElementConverter: AttachmentElementConverter {
    
    // MARK: - AttachmentElementConverter
    
    typealias T = NSTextAttachment
    
    func convert(
        _ element: ElementNode,
        inheriting attributes: [NSAttributedString.Key: Any],
        contentSerializer serialize: ContentSerializer) -> (attachment: NSTextAttachment, string: NSAttributedString) {
        
        precondition(element.type == .hr)
        
        let elementRepresentation = HTMLElementRepresentation(element)
        let representation = HTMLRepresentation(for: .element(elementRepresentation))
        
        let attributes = combine(attributes, with: representation)
        let attachment = self.attachment(for: element)
        
        let intrinsicRepresentation = NSAttributedString(attachment: attachment, attributes: attributes)
        let serialization = serialize(element, intrinsicRepresentation, attributes, false)
        
        return (attachment, serialization)
    }
    
    // MARK: - Attachment Creation
    
    private func attachment(for element: ElementNode) -> NSTextAttachment {
        return LineAttachment()
    }
    
    // MARK: - Additional HTMLRepresentation Logic
    
    private func combine(_ attributes: [NSAttributedString.Key: Any], with representation: HTMLRepresentation) -> [NSAttributedString.Key : Any] {
        var combinedAttributes = attributes
        
        combinedAttributes[.hrHtmlRepresentation] = representation
        
        return combinedAttributes
    }
}
