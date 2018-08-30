import Foundation

public extension Array where Element == Attribute {
    /*
    subscript(_ name: String) -> Attribute? {
        get {
            return first() { $0.name == name }
        }
    }*/
    
    subscript(_ name: String) -> Attribute.Value? {
        get {
            return first() { $0.name == name }?.value
        }
        
        set (newValue) {
            guard let newValue = newValue else {
                remove(named: name)
                return
            }
            
            guard let existingAttribute = first(where: { $0.name == name }) else {
                let newAttribute = Attribute(name: name, value: newValue)
                append(newAttribute)
                return
            }
            
            existingAttribute.value = newValue
        }
    }
    
    public mutating func remove(named name: String) {
        guard let attributeIndex = index(where: { $0.name == name }) else {
            return
        }
        
        remove(at: attributeIndex)
    }
}
