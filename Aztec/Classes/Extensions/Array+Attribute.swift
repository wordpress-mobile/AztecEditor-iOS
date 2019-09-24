import Foundation

public extension Array where Element == Attribute {
    
    subscript(_ name: String) -> Attribute.Value? {
        get {
            return first(where: { $0.name == name })?.value
        }
        
        set {
            guard let newValue = newValue else {
                remove(named: name)
                return
            }
            
            set(newValue, for: name)
        }
    }
    
    mutating func set(_ value: String, for name: String) {
        set(.string(value), for: name)
    }
    
    mutating func set(_ value: Attribute.Value, for name: String) {
        guard let attributeIndex = firstIndex(where: { $0.name == name }) else {
            let newAttribute = Attribute(name: name, value: value)
            
            append(newAttribute)
            return
        }
        
        self[attributeIndex].value = value
    }
    
    mutating func remove(named name: String) {
        guard let attributeIndex = firstIndex(where: { $0.name == name }) else {
            return
        }
        
        remove(at: attributeIndex)
    }
}
