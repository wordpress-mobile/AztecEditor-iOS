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
        
        if let selfClosingBlockAttribute = element.attributes.first(where: { $0.name == GutenbergInputHTMLTreeProcessor.selfClosingBlockAttributeName }) {
            guard let selfClosingBlockData = selfClosingBlockAttribute.value.toString() else {
                // There's no scenario in which this data can be missing, and no way to handle such an
                // error in the logic.
                // If this is ever triggered, you should trace back where the block data is being lost.
                fatalError()
            }
            
            let attachment = GutenblockAttachment(selfClosingBlockData)
            
            return NSAttributedString(attachment: attachment, attributes: attributes)
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
