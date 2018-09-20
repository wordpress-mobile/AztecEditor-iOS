import Foundation

public protocol CSSAttributeMatcher {
    func check(_ cssAttribute: CSSAttribute) -> Bool
}
