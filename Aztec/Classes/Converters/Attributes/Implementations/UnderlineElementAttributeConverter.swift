import Foundation
import UIKit

class UnderlineElementAttributesConverter: ElementAttributeConverter {

    private let cssAttributeType = CSSAttributeType.fontDecoration
    private let cssAttributeValue = FontDecoration.underline
    
    func convert(
        _ attribute: Attribute,
        inheriting attributes: [NSAttributedStringKey: Any]) -> [NSAttributedStringKey: Any] {
        
        guard let cssAttribute = attribute.firstCSSAttribute(ofType: cssAttributeType),
            isUnderline(cssAttribute) else {
                return attributes
        }
        
        var attributes = attributes
        
        attributes[.underlineStyle] = 1
        
        return attributes
    }
    
    private func isUnderline(_ fontStyleAttribute: CSSAttribute) -> Bool {
        guard let decoration = fontStyleAttribute.value  else {
                return false
        }
        
        return decoration.contains(cssAttributeValue.rawValue)
    }
}
