import Aztec
import Foundation

public extension Element {
    static let gutenblock = Element("gutenblock")    
}

class GutenblockConverter: ElementConverter {
    
    // MARK: - ElementConverter
    
    func convert(
        _ element: ElementNode,
        inheriting attributes: [NSAttributedStringKey: Any],
        contentSerializer serialize: ContentSerializer) -> NSAttributedString {
        
        precondition(element.type == .gutenblock)
        
        let attributes = self.attributes(for: element, inheriting: attributes)
    
        return serialize(element, nil, attributes)
    }
    
    private func attributes(for element: ElementNode, inheriting attributes: [NSAttributedStringKey: Any]) -> [NSAttributedStringKey: Any] {
        let elementRepresentation = HTMLElementRepresentation(element)
        let representation = HTMLRepresentation(for: .element(elementRepresentation))
        
        let paragraphStyle = attributes.paragraphStyle()
        paragraphStyle.appendProperty(Gutenblock(storing: representation))
        
        var finalAttributes = attributes
        finalAttributes[.paragraphStyle] = paragraphStyle
        return finalAttributes
    }
}
