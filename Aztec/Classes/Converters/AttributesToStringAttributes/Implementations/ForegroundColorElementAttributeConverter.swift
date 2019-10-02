import Foundation
import UIKit

class ForegroundColorElementAttributesConverter: ElementAttributeConverter {

    let cssAttributeMatcher = ForegroundColorCSSAttributeMatcher()
    
    func convert(
        _ attribute: Attribute,
        inheriting attributes: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
        
        guard let cssColor = attribute.firstCSSAttribute(ofType: .foregroundColor),
            let colorValue = cssColor.value,
            let color = UIColor(hexString: colorValue) else {
            return attributes
        }
        
        var attributes = attributes
        
        attributes[.foregroundColor] = color
        
        return attributes
    }
}
