import Foundation

open class BoldCSSAttributeMatcher: CSSAttributeMatcher {
    
    public func check(_ cssAttribute: CSSAttribute) -> Bool {
        guard let value = cssAttribute.value,
            let intValue = Int(value) else {
                return false
        }
        
        return cssAttribute.type == .fontWeight && intValue >= FontWeight.bold.rawValue
    }
}
