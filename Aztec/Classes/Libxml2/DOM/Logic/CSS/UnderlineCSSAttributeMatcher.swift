import Foundation

open class UnderlineCSSAttributeMatcher: CSSAttributeMatcher {
    
    public func check(_ cssAttribute: CSSAttribute) -> Bool {
        guard let value = cssAttribute.value else {
            return false
        }
        
        return cssAttribute.type == .textDecoration && value.contains(TextDecoration.underline.rawValue)
    }
}
