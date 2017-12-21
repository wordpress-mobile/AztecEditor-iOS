import UIKit


/// Returns a specialised representation for a `<hr>` element.
///
class HRElementConverter: AttachmentElementConverter, ElementConverter {

    typealias T = NSTextAttachment
    
    // MARK: - ElementConverter
    
    func canConvert(element: ElementNode) -> Bool {
        return element.standardName == .hr
    }
    
    func convert(_ element: ElementNode, inheriting attributes: [AttributedStringKey: Any]) -> NSAttributedString {
        let (_, output) = convert(element, inheriting: attributes)
        
        return output
    }
    
    // MARK: - AttachmentElementConverter
    
    func convert(_ element: ElementNode, inheriting attributes: [AttributedStringKey: Any]) -> (attachment: NSTextAttachment, string: NSAttributedString) {
        let elementRepresentation = HTMLElementRepresentation(element)
        let representation = HTMLRepresentation(for: .element(elementRepresentation))
        
        let attributes = combine(attributes, with: representation)
        let attachment = self.attachment(for: element)
        
        return (attachment, NSAttributedString(attachment: attachment, attributes: attributes))
    }
    
    // MARK: - Attachment Creation
    
    private func attachment(for element: ElementNode) -> NSTextAttachment {
        return LineAttachment()
    }
    
    // MARK: - Additional HTMLRepresentation Logic
    
    private func combine(_ attributes: [AttributedStringKey: Any], with representation: HTMLRepresentation) -> [AttributedStringKey : Any] {
        var combinedAttributes = attributes
        
        combinedAttributes[.hrHtmlRepresentation] = representation
        
        return combinedAttributes
    }
}
