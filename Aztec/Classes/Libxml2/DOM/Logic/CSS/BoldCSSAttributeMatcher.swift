import Foundation

open class BoldCSSAttributeMatcher: CSSAttributeMatcher {
    
    public func check(_ cssAttribute: CSSAttribute) -> Bool {
        guard let value = cssAttribute.value,
            cssAttribute.type == .fontWeight else {
                return false
        }
        
        if let weight = FontWeight(rawValue: value) {
            return weight.isBold()
        } else if let weight = Int(value) {
            return FontWeightNumeric.isBold(weight)
        }
        
        return false
    }
}
