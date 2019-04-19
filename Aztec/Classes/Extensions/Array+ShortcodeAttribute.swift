import Foundation

public extension Array where Element == ShortcodeAttribute {
    
    subscript(_ key: String) -> ShortcodeAttribute? {
        get {
            return first() { $0.key == key }
        }
    }
    
    mutating func set(_ value: String, forKey key: String) {
        set(.string(value), forKey: key)
    }
    
    mutating func set(_ value: ShortcodeAttribute.Value, forKey key: String) {
        let newAttribute = ShortcodeAttribute(key: key, value: value)
        
        guard let attributeIndex = index(where: { $0.key == key }) else {
            append(newAttribute)
            return
        }
        
        self[attributeIndex] = newAttribute
    }
    
    mutating func remove(key: String) {
        guard let attributeIndex = index(where: { $0.key == key }) else {
            return
        }
        
        remove(at: attributeIndex)
    }
}
