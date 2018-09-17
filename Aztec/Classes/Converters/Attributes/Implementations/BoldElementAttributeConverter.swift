import Foundation
import UIKit

class BoldElementAttributesConverter: ElementAttributeConverter {    

    private let cssFontWeightAttributeName = "font-weight"
    private let cssBoldFontWeight = 700

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
        
        guard let fontWeightAttribute = self.fontWeightAttribute(from: attribute),
            isBold(fontWeightAttribute) else {
                return attributes
        }
        
        var attributes = attributes
        
        // The default font should already be in the attributes.  But in case it's nil
        // we should have some way to figure out the default font.  Honestly it feels like
        // this configuration should come from elsewhere, but we'll just default to the
        // default system font of size 14 for now.
        //
        let font = attributes[.font] as? UIFont ?? UIFont.systemFont(ofSize: 14)
        let newFont = font.modifyTraits([.traitBold], enable: true)
        
        attributes[.font] = newFont
        
        return attributes
    }
    
    private func isBold(_ fontWeightAttribute: CSSAttribute) -> Bool {
        guard let weightValue = fontWeightAttribute.value,
            let weight = Int(weightValue) else {
                return false
        }
        
        return weight >= cssBoldFontWeight
    }
    
    private func fontWeightAttribute(from attribute: Attribute) -> CSSAttribute? {
        guard case let .inlineCss(cssAttributes) = attribute.value,
            let fontWeightAttribute = fontWeightAttribute(from: cssAttributes) else {
                return nil
        }
        
        return fontWeightAttribute
    }
    
    private func fontWeightAttribute(from cssAttributes: [CSSAttribute]) -> CSSAttribute? {
        return cssAttributes.first(where: { $0.name == cssFontWeightAttributeName })
    }
}
