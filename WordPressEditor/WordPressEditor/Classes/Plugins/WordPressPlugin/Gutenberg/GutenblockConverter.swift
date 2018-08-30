import Aztec
import Foundation

public extension Element {
    static let gutenblock = Element("gutenblock")    
}

class GutenblockConverter: ElementConverter {
    
    // MARK: - ElementConverter
    
    func convert(
        _ element: ElementNode,
        inheriting attributes: [NSAttributedString.Key: Any],
        childrenSerializer serializeChildren: ChildrenSerializer) -> NSAttributedString {
        
        precondition(element.type == .gutenblock)
        
        let attributes = self.attributes(for: element, inheriting: attributes)
    
        return serializeChildren(element.children, attributes)
    }
    
    private func attributes(for element: ElementNode, inheriting attributes: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
        let elementRepresentation = HTMLElementRepresentation(element)
        let representation = HTMLRepresentation(for: .element(elementRepresentation))
        
        let paragraphStyle = attributes.paragraphStyle()
        paragraphStyle.appendProperty(Gutenblock(storing: representation))
        
        var finalAttributes = attributes
        finalAttributes[.paragraphStyle] = paragraphStyle
        return finalAttributes
    }
}
