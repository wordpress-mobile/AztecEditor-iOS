import Foundation
import UIKit


/// Converts the italic style information from string attributes and aggregates it into an
/// existing array of element nodes.
///
class ItalicStringAttributeConverter: StringAttributeConverter {
    
    let cssAttributeMatcher = ItalicCSSAttributeMatcher()
    
    func convert(
        attributes: [NSAttributedStringKey: Any],
        andAggregateWith elementNodes: [ElementNode]) -> [ElementNode] {
        
        var elementNodes = elementNodes
        
        // We add the representation right away, if it exists... as it could contain attributes beyond just this
        // style.  The enable and disable methods below can modify this as necessary.
        //
        if let representation = attributes[NSAttributedStringKey.italicHtmlRepresentation] as? HTMLRepresentation,
            case let .element(representationElement) = representation.kind {
            
            elementNodes.append(representationElement.toElementNode())
        }
        
        if let font = attributes[.font] as? UIFont,
            font.containsTraits(.traitItalic) {
            
            return enableItalic(in: elementNodes)
        } else {
            return disableItalic(in: elementNodes)
        }
    }

    // MARK: - Enabling and Disabling Bold

    private func disableItalic(in elementNodes: [ElementNode]) -> [ElementNode] {
        
        let elementNodes = elementNodes.compactMap { (elementNode) -> ElementNode? in
            guard elementNode.type != .em || elementNode.attributes.count > 0 else {
                return ElementNode(type: .span, attributes: elementNode.attributes, children: elementNode.children)
            }
            
            return elementNode
        }
        
        for elementNode in elementNodes {
            elementNode.removeCSSAttributes(matching: cssAttributeMatcher)
        }
        
        return elementNodes
    }
    
    private func enableItalic(in elementNodes: [ElementNode]) -> [ElementNode] {
        
        var elementNodes = elementNodes
        
        // We can now check if we have any CSS attribute representing bold.  If that's the case we can completely skip
        // adding the element.
        //
        for elementNode in elementNodes {
            if elementNode.containsCSSAttribute(matching: cssAttributeMatcher) {
                return elementNodes
            }
        }
        
        // Nothing was found to represent bold... just add the element.
        elementNodes.append(ElementNode(type: .em))
        return elementNodes
    }
}

