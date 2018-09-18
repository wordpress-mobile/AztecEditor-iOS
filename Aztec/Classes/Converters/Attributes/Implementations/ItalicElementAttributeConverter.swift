import Foundation
import UIKit

class ItalicElementAttributesConverter: ElementAttributeConverter {
    
    private let cssAttributeType = CSSAttributeType.fontStyle
    private let cssAttributeValue = FontStyle.italic
    
    func convert(
        _ attribute: Attribute,
        inheriting attributes: [NSAttributedStringKey: Any]) -> [NSAttributedStringKey: Any] {
        
        guard let cssAttribute = attribute.firstCSSAttribute(ofType: cssAttributeType),
            isItalic(cssAttribute) else {
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
    
    private func isItalic(_ fontStyleAttribute: CSSAttribute) -> Bool {
        guard let decoration = fontStyleAttribute.value else {
            return false
        }
        
        return decoration.contains(cssAttributeValue.rawValue)
    }
}
