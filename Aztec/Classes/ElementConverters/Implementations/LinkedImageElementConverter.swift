import UIKit

/// This is a very specific converter used in scenarios where we need to ensure we're dealing with
/// a linked image, and not just any regular link.
///
class LinkedImageElementConverter: AttachmentElementConverter {
    
    let imageElementConverter: ImageElementConverter
    let linkFormatter = LinkFormatter()
    unowned let serializer: AttributedStringSerializer
    
    init(using serializer: AttributedStringSerializer, and imageElementConverter: ImageElementConverter) {
        self.imageElementConverter = imageElementConverter
        self.serializer = serializer
    }
    
    // MARK: - ElementConverter
    
    func canConvert(element: ElementNode) -> Bool {
        guard element.isNodeType(.a),
            element.children.count == 1,
            let childElement = element.children[0] as? ElementNode,
            imageElementConverter.canConvert(element: childElement) else {
                return false
        }
        
        return true
    }
    
    // MARK: - AttachmentElementConverter
    
    typealias AttachmentType = ImageAttachment
    
    func convert(_ element: ElementNode, inheriting attributes: [AttributedStringKey: Any]) -> (attachment: ImageAttachment, string: NSAttributedString) {
        assert(canConvert(element: element))
        
        let elementRepresentation = HTMLElementRepresentation(element)
        let representation = HTMLRepresentation(for: .element(elementRepresentation))
        let attributes = linkFormatter.apply(to: attributes, andStore: representation)
        
        let childElement = element.children[0] as! ElementNode // canConvert() ensures this condition
        
        let (attachment, string) = imageElementConverter.convert(childElement, inheriting: attributes)
        
        return (attachment, string)
    }
}


