import Foundation
import UIKit


/// Converts the italic style information from string attributes and aggregates it into an
/// existing array of element nodes.
///
open class ItalicStringAttributeConverter: StringAttributeConverter {
    
    private let toggler = HTMLStyleToggler(defaultElement: .em, cssAttributeMatcher: ItalicCSSAttributeMatcher())
    
    public func convert(
        attributes: [NSAttributedString.Key: Any],
        andAggregateWith elementNodes: [ElementNode]) -> [ElementNode] {
        
        var elementNodes = elementNodes
        
        // We add the representation right away, if it exists... as it could contain attributes beyond just this
        // style.  The enable and disable methods below can modify this as necessary.
        //
        if let representation = attributes[NSAttributedString.Key.italicHtmlRepresentation] as? HTMLRepresentation,
            case let .element(representationElement) = representation.kind {
            
            elementNodes.append(representationElement.toElementNode())
        }
        
        if shouldEnableItalic(for: attributes) {
            return toggler.enable(in: elementNodes)
        } else {
            return toggler.disable(in: elementNodes)
        }
    }

    // MARK: - Style Detection

    func shouldEnableItalic(for attributes: [NSAttributedString.Key : Any]) -> Bool {
        return hasItalicTrait(for: attributes)
    }
    
    func hasItalicTrait(for attributes: [NSAttributedString.Key : Any]) -> Bool {
        guard let font = attributes[.font] as? UIFont,
            font.containsTraits(.traitItalic) else {
                return false
        }
        
        return true
    }
}

