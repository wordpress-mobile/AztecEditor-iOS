import Foundation
import UIKit


/// Converts the bold style information from string attributes and aggregates it into an
/// existing array of element nodes.
///
open class BoldStringAttributeConverter: StringAttributeConverter {
    
    private let toggler = HTMLStyleToggler(defaultElement: .strong, cssAttributeMatcher: BoldCSSAttributeMatcher())
    
    public func convert(
        attributes: [NSAttributedString.Key: Any],
        andAggregateWith elementNodes: [ElementNode]) -> [ElementNode] {
     
        var elementNodes = elementNodes
        
        // We add the representation right away, if it exists... as it could contain attributes beyond just this
        // style.  The enable and disable methods below can modify this as necessary.
        //
        if let elementNode = attributes.storedElement(for: NSAttributedString.Key.boldHtmlRepresentation) {
            elementNodes.append(elementNode)
        }
        
        if shouldEnableBoldElement(for: attributes) {
            return toggler.enable(in: elementNodes)
        } else {
            return toggler.disable(in: elementNodes)
        }
    }
    
    // MARK: - Style Detection
    
    func shouldEnableBoldElement(for attributes: [NSAttributedString.Key: Any]) -> Bool {
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

