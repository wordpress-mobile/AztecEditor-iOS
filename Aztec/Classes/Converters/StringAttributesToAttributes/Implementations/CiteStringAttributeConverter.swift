import Foundation
import UIKit


/// Converts the italic style information from string attributes and aggregates it into an
/// existing array of element nodes.
///
open class CiteStringAttributeConverter: StringAttributeConverter {
    
    public func convert(
        attributes: [NSAttributedString.Key: Any],
        andAggregateWith elementNodes: [ElementNode]) -> [ElementNode] {
        
        var elementNodes = elementNodes
        
        // We add the representation right away, if it exists... as it could contain attributes beyond just this
        // style.  The enable and disable methods below can modify this as necessary.
        //
        if let representation = attributes[NSAttributedString.Key.citeHtmlRepresentation] as? HTMLRepresentation,
            case let .element(representationElement) = representation.kind {
            
            elementNodes.append(representationElement.toElementNode())
        }
        
        if let font = attributes[.font] as? UIFont,
            font.containsTraits(.traitItalic) {
            
            return enableCite(in: elementNodes)
        } else {
            return disableCite(in: elementNodes)
        }
    }
    
    // MARK: - Enabling and Disabling Bold
    
    private func disableCite(in elementNodes: [ElementNode]) -> [ElementNode] {
        
        let elementNodes = elementNodes.compactMap { (elementNode) -> ElementNode? in
            
            guard elementNode.type != .cite else {
                if elementNode.attributes.count > 0 {
                    return ElementNode(type: .span, attributes: elementNode.attributes, children: elementNode.children)
                } else {
                    return nil
                }
            }
            
            return elementNode
        }
        
        return elementNodes
    }
    
    private func enableCite(in elementNodes: [ElementNode]) -> [ElementNode] {
        
        // We can now check if we have any CSS attribute representing bold.  If that's the case we can completely skip
        // adding the element.
        //
        for elementNode in elementNodes {
            if elementNode.type == .cite {
                return elementNodes
            }
        }
        
        var elementNodes = elementNodes
        elementNodes.append(ElementNode(type: .cite))
        return elementNodes
    }
}

