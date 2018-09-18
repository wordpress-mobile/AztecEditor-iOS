import Foundation
import UIKit


/// Converts the underline style information from string attributes and aggregates it into an
/// existing array of element nodes.
///
class UnderlineStringAttributeConverter: StringAttributeConverter {
    func convert(
        attributes: [NSAttributedStringKey: Any],
        andAggregateWith elementNodes: [ElementNode]) -> [ElementNode] {
        
        var elementNodes = elementNodes
        
        // We add the representation right away, if it exists... as it could contain attributes beyond just this
        // style.  The enable and disable methods below can modify this as necessary.
        //
        if let representation = attributes[NSAttributedStringKey.underlineHtmlRepresentation] as? HTMLRepresentation,
            case let .element(representationElement) = representation.kind {
            
            elementNodes.append(representationElement.toElementNode())
        }
        
        if let underlineStyle = attributes[.underlineStyle] as? Int,
            underlineStyle != 0 {
            
            return enableUnderline(in: elementNodes)
        } else {
            return disableUnderline(in: elementNodes)
        }
    }
    
    // MARK: - Enabling and Disabling Bold
    
    private func disableUnderline(in elementNodes: [ElementNode]) -> [ElementNode] {
        
        let elementNodes = elementNodes.compactMap { (elementNode) -> ElementNode? in
            guard elementNode.type != .u || elementNode.attributes.count > 0 else {
                return nil
            }
            
            return ElementNode(type: .span, attributes: elementNode.attributes, children: elementNode.children)
        }
        
        for elementNode in elementNodes {
            elementNode.removeCSSAttributes(matching: { (cssAttribute) -> Bool in
                guard let value = cssAttribute.value else {
                    return false
                }
                
                return cssAttribute.type == .textDecoration && value.contains(textDecoration.underline.rawValue)
            })
        }
        
        return elementNodes
    }
    
    private func enableUnderline(in elementNodes: [ElementNode]) -> [ElementNode] {
        
        var elementNodes = elementNodes
        
        // We can now check if we have any CSS attribute representing bold.  If that's the case we can completely skip
        // adding the element.
        //
        for elementNode in elementNodes {
            if elementNode.containsCSSAttribute(where: { (cssAttribute) -> Bool in
                guard let value = cssAttribute.value else {
                    return false
                }
                
                return cssAttribute.type == .textDecoration && value.contains(textDecoration.underline.rawValue)
            }) {
                return elementNodes
            }
        }
        
        // Nothing was found to represent bold... just add the element.
        elementNodes.append(ElementNode(type: .u))
        return elementNodes
    }
}

