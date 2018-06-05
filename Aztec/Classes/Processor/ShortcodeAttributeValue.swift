import Foundation

public enum ShortcodeAttributeValue: Equatable {
    case `nil`
    case string(String)

    public static func == (lhs: ShortcodeAttributeValue, rhs: ShortcodeAttributeValue) -> Bool {
        switch (lhs, rhs) {
        case (.nil, .nil):
            return true
        case let (.string(l), .string(r)):
            return l == r
        default:
            return false
        }
    }
}
