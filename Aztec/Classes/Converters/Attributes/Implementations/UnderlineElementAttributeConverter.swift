import Foundation
import UIKit

class UnderlineElementAttributesConverter: ElementAttributeConverter {
    
    private let cssAttributeName = "text-decoration"
    private let cssAttributeValue = "underline"
    
    func convert(
        _ attribute: Attribute,
        inheriting attributes: [NSAttributedStringKey: Any]) -> [NSAttributedStringKey: Any] {
        
        guard let cssAttribute = attribute.value.cssAttribute(named: cssAttributeName),
            isUnderline(cssAttribute) else {
                return attributes
        }
        
        var attributes = attributes
        
        attributes[.underlineStyle] = 1
        
        return attributes
    }
    
    private func isUnderline(_ fontStyleAttribute: CSSAttribute) -> Bool {
        guard let decoration = fontStyleAttribute.value else {
            return false
        }
        
        return decoration == cssAttributeValue
    }
}
