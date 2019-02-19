import Foundation
import UIKit


/// Converts the bold style information from string attributes and aggregates it into an
/// existing array of element nodes.
///
open class BoldStringAttributeConverter: StringAttributeConverter {
    
    private let cssAttributeMatcher = BoldCSSAttributeMatcher()
    private let defaultBoldElement = Element.strong
    
    public func convert(
        attributes: [NSAttributedStringKey: Any],
        andAggregateWith elementNodes: [ElementNode]) -> [ElementNode] {
     
        var elementNodes = elementNodes
        
        // We add the representation right away, if it exists... as it could contain attributes beyond just this
        // style.  The enable and disable methods below can modify this as necessary.
        //
        if let representation = attributes[NSAttributedStringKey.boldHtmlRepresentation] as? HTMLRepresentation,
            case let .element(representationElement) = representation.kind {
            
            elementNodes.append(representationElement.toElementNode())
        }
        
        if shouldEnableBoldElement(for: attributes) {
            return enableBold(in: elementNodes)
        } else {
            return disableBold(in: elementNodes)
        }
    }
    
    // MARK: - Enabling and Disabling Bold
    
    private func disableBold(in elementNodes: [ElementNode]) -> [ElementNode] {
        
        let elementNodes = elementNodes.compactMap { (elementNode) -> ElementNode? in
            let elementIsBold = Element.b.equivalentNames.contains(elementNode.type)
            
            guard elementIsBold else {
                return elementNode
            }
            
            if elementNode.attributes.count > 0 {
                return ElementNode(type: .span, attributes: elementNode.attributes, children: elementNode.children)
            } else {
                return nil
            }
        }
        
        for elementNode in elementNodes {
            elementNode.removeCSSAttributes(matching: cssAttributeMatcher)
        }
        
        return elementNodes
    }
    
    private func enableBold(in elementNodes: [ElementNode]) -> [ElementNode] {
        
        var elementNodes = elementNodes
        
        // We can now check if we have any CSS attribute representing bold.  If that's the case we can completely skip
        // adding the element.
        //
        for elementNode in elementNodes {
            let elementIsBold = Element.b.equivalentNames.contains(elementNode.type)
            
            if elementIsBold || elementNode.containsCSSAttribute(matching: cssAttributeMatcher) {
                return elementNodes
            }
        }
        
        // Nothing was found to represent bold... just add the element.
        elementNodes.append(ElementNode(type: defaultBoldElement))
        return elementNodes
    }
    
    func shouldEnableBoldElement(for attributes: [NSAttributedString.Key : Any]) -> Bool {
        if isHeading(for: attributes) {
            // If this is a heading then shadow represents bold elements since
            // headings are bold by default
            return hasShadowTrait(for: attributes)
        }
        return hasBoldTrait(for: attributes)
    }
    
    func isHeading(for attributes: [NSAttributedString.Key : Any]) -> Bool {
        return attributes[.headingRepresentation] != nil
    }
    
    func hasShadowTrait(for attributes: [NSAttributedString.Key : Any]) -> Bool {
        return attributes[.shadow] != nil
    }
    
    func hasBoldTrait(for attributes: [NSAttributedString.Key : Any]) -> Bool {
        if let font = attributes[.font] as? UIFont,
            font.containsTraits(.traitBold) {
            return true
        }
        return false
    }
}

