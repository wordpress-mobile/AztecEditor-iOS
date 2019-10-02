import Foundation

open class ForegroundColorCSSAttributeMatcher: CSSAttributeMatcher {
    
    public func check(_ cssAttribute: CSSAttribute) -> Bool {
        guard let value = cssAttribute.value else {
            return false
        }
        
        return cssAttribute.type == .foregroundColor && !value.isEmpty
    }
}
