import Foundation
import UIKit


/// Converts the subscript style information from string attributes and aggregates it into an
/// existing array of element nodes.
///
open class SubscriptStringAttributeConverter: StringAttributeConverter {
    
    private let toggler = HTMLStyleToggler(defaultElement: .sub, cssAttributeMatcher: NeverCSSAttributeMatcher())
    
    public func convert(
        attributes: [NSAttributedString.Key: Any],
        andAggregateWith elementNodes: [ElementNode]) -> [ElementNode] {
        
        var elementNodes = elementNodes
        
        // We add the representation right away, if it exists... as it could contain attributes beyond just this
        // style.  The enable and disable methods below can modify this as necessary.
        //
        if let representation = attributes[NSAttributedString.Key.subHtmlRepresentation] as? HTMLRepresentation,
            case let .element(representationElement) = representation.kind {
            
            elementNodes.append(representationElement.toElementNode())
        }
        
        if shouldEnable(for: attributes) {
            return toggler.enable(in: elementNodes)
        } else {
            return toggler.disable(in: elementNodes)
        }
    }

    // MARK: - Style Detection

    func shouldEnable(for attributes: [NSAttributedString.Key : Any]) -> Bool {
        return hasTraits(for: attributes)
    }
    
    func hasTraits(for attributes: [NSAttributedString.Key : Any]) -> Bool {
        guard let baselineOffset = attributes[.baselineOffset] as? NSNumber else {
                return false
        }
        
        return baselineOffset.intValue < 0;
    }
}

