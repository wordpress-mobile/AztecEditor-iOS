import Foundation
import UIKit

class UnderlineElementAttributesConverter: ElementAttributeConverter {
    
    private let cssAttributeName = "text-decoration"
    private let cssAttributeValue = "underline"
    
    func convert(
        _ attributes: [Attribute],
        inheriting inheritedAttributes: [NSAttributedStringKey: Any]) -> [NSAttributedStringKey: Any] {
        
        return attributes.reduce(inheritedAttributes, { (previous, attribute) -> [NSAttributedStringKey: Any] in
            return convert(attribute, inheriting: previous)
        })
    }
    
    func convert(
        _ attribute: Attribute,
        inheriting attributes: [NSAttributedStringKey: Any]) -> [NSAttributedStringKey: Any] {
        
        guard let cssAttribute = cssAttribute(from: attribute),
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
    
    private func cssAttribute(from attribute: Attribute) -> CSSAttribute? {
        guard case let .inlineCss(cssAttributes) = attribute.value,
            let cssAttribute = cssAttribute(from: cssAttributes) else {
                return nil
        }
        
        return cssAttribute
    }
    
    private func cssAttribute(from cssAttributes: [CSSAttribute]) -> CSSAttribute? {
        return cssAttributes.first(where: { $0.name == cssAttributeName })
    }
}
