import Foundation

public class ShortcodeAttribute: CustomReflectable {
    
    // MARK: Value
    
    public enum Value: Equatable, CustomReflectable {
        case `nil`
        case string(String)
        
        // MARK: - Equatable
        
        public static func == (lhs: ShortcodeAttribute.Value, rhs: ShortcodeAttribute.Value) -> Bool {
            switch (lhs, rhs) {
            case (.nil, .nil):
                return true
            case let (.string(l), .string(r)):
                return l == r
            default:
                return false
            }
        }
        
        // MARK: - CustomReflectable
        
        public var customMirror: Mirror {
            get {
                switch self {
                case .nil:
                    return Mirror(self, children: ["value": 0])
                case .string(let string):
                    return Mirror(self, children: ["value": string])
                }
            }
        }
    }
    
    // MARK: - Attribute definition
    
    public let key: String
    public let value: Value
    
    // MARK: - Initializers
    
    public init(key: String, value: Value) {
        self.key = key
        self.value = value
    }
    
    public init(key: String, value: String) {
        self.key = key
        self.value = .string(value)
    }
    
    public init(key: String) {
        self.key = key
        self.value = .nil
    }
    
    // MARK: - CustomReflectable
    
    public var customMirror: Mirror {
        get {
            return Mirror(self, children: ["key": key, "value": value])
        }
    }
}
