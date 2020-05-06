import Foundation

public protocol CSSAttributeMatcher {
    func check(_ cssAttribute: CSSAttribute) -> Bool
}

open class NeverCSSAttributeMatcher: CSSAttributeMatcher {
    public func check(_ cssAttribute: CSSAttribute) -> Bool {
        return false
    }
}
