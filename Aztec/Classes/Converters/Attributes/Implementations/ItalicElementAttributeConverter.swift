import Foundation
import UIKit

class ItalicElementAttributesConverter: ElementAttributeConverter {
    
    private let cssFontStyleAttributeName = "font-style"
    private let cssFontStyleItalicValue = "italic"
    
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
        
        guard let fontStyleAttribute = fontStyleAttribute(from: attribute),
            isBold(fontStyleAttribute) else {
                return attributes
        }
        
        var attributes = attributes
        
        // The default font should already be in the attributes.  But in case it's nil
        // we should have some way to figure out the default font.  Honestly it feels like
        // this configuration should come from elsewhere, but we'll just default to the
        // default system font of size 14 for now.
        //
        let font = attributes[.font] as? UIFont ?? UIFont.systemFont(ofSize: 14)
        let newFont = font.modifyTraits([.traitItalic], enable: true)
        
        attributes[.font] = newFont
        
        return attributes
    }
    
    private func isBold(_ fontStyleAttribute: CSSAttribute) -> Bool {
        guard let decoration = fontStyleAttribute.value else {
            return false
        }
        
        return decoration == cssFontStyleItalicValue
    }
    
    private func fontStyleAttribute(from attribute: Attribute) -> CSSAttribute? {
        guard case let .inlineCss(cssAttributes) = attribute.value,
            let fontStyleAttribute = fontStyleAttribute(from: cssAttributes) else {
                return nil
        }
        
        return fontStyleAttribute
    }
    
    private func fontStyleAttribute(from cssAttributes: [CSSAttribute]) -> CSSAttribute? {
        return cssAttributes.first(where: { $0.name == cssFontStyleAttributeName })
    }
}
