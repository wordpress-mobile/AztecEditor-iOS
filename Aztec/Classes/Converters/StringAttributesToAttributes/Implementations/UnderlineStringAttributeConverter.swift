import Foundation
import UIKit


/// Converts the underline style information from string attributes and aggregates it into an
/// existing array of element nodes.
///
open class UnderlineStringAttributeConverter: StringAttributeConverter {
    
    private let toggler = HTMLStyleToggler(defaultElement: .u, cssAttributeMatcher: UnderlineCSSAttributeMatcher())
    
    public func convert(
        attributes: [NSAttributedString.Key: Any],
        andAggregateWith elementNodes: [ElementNode]) -> [ElementNode] {
        
        var elementNodes = elementNodes
        
        // We add the representation right away, if it exists... as it could contain attributes beyond just this
        // style.  The enable and disable methods below can modify this as necessary.
        //
        if let representation = attributes[NSAttributedString.Key.underlineHtmlRepresentation] as? HTMLRepresentation,
            case let .element(representationElement) = representation.kind {
            
            elementNodes.append(representationElement.toElementNode())
        }
        
        if let underlineStyle = attributes[.underlineStyle] as? Int,
            underlineStyle != 0 {
            
            return toggler.enable(in: elementNodes)
        } else {
            return toggler.disable(in: elementNodes)
        }
    }
}

