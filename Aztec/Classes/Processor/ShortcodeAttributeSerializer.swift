import Foundation

/// This class takes care of serializing shortcode attributes to represent them as `String`
///
public class ShortcodeAttributeSerializer {
    
    public init() {}
   
    /// Serializes an array of attributes.
    ///
    /// - Parameters:
    ///     - attributes: the array of attributes to serialize.
    ///
    /// - Returns: the `String` representation of the provided attributes.
    ///
    public func serialize(_ attributes: [ShortcodeAttribute]) -> String {
        return attributes.reduce("", { (previous, attribute) -> String in
            let previous = previous.count > 0 ? previous + " " : ""
            
            return previous + serialize(attribute)
        })
    }
    
    /// Serializes an attribute.
    ///
    /// - Parameters:
    ///     - attribute: the attribute to serialize.
    ///
    /// - Returns: the `String` representation of the provided attribute.
    ///
    public func serialize(_ attribute: ShortcodeAttribute) -> String {
        return serialize(key: attribute.key, value: attribute.value)
    }
    
    /// Serializes a value as a `String`.
    ///
    /// - Parameters:
    ///     - value: the value of the attribute.
    ///
    /// - Returns: the `String` representation of the provided key and value.
    ///
    public func serialize(_ value: ShortcodeAttribute.Value) -> String {
        switch value {
        case .nil:
            return ""
        case .string(let value):
            return value
        }
    }
    
    /// Serializes a key and a value as a `String`.
    ///
    /// - Parameters:
    ///     - key: the key of the attribute.
    ///     - value: the value of the attribute.
    ///
    /// - Returns: the `String` representation of the provided key and value.
    ///
    public func serialize(key: String, value: ShortcodeAttribute.Value) -> String {
        switch value {
        case .nil:
            return key
        case .string(let value):
            return serialize(key: key, value: value)
        }
    }
    
    
    /// Serializes a key and a value as a `String`.
    ///
    /// - Parameters:
    ///     - key: the key of the attribute.
    ///     - value: the value of the attribute.
    ///
    /// - Returns: the `String` representation of the provided key and value.
    ///
    public func serialize(key: String, value: String) -> String {
        return "\(key)=\"\(value)\""
    }
}
