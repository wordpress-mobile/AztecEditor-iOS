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
        childrenSerializer serializeChildren: ChildrenSerializer) -> NSAttributedString {
        
        precondition(element.type == .gutenblock)
        
        if element.attributes.contains(where: { $0.name == GutenbergInputHTMLTreeProcessor.selfClosingBlockAttributeName }) {
            NSAttributedString(attachment: attachment, attributes: attributes)
        } else {
            let attributes = self.attributes(for: element, inheriting: attributes)
        
            return serializeChildren(element.children, attributes)
        }
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
