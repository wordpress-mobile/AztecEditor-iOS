import Foundation

/// This class takes care of serializing shortcode attributes to represent them as `String`
///
public class ShortcodeAttributeSerializer {
    
    public init() {}
   
    /// Serializes a dictionary of attributes.
    ///
    /// - Parameters:
    ///     - attributes: the dictionary of attributes to serialize.
    ///
    /// - Returns: the `String` representation of the provided attributes.
    ///
    public func serialize(_ attributes: [String: ShortcodeAttributeValue]) -> String {
        return attributes.reduce("", { (previous, attribute) -> String in
            return previous + " " + serialize(attribute)
        })
    }
    
    /// Serializes a (key, value) pair representing an attribute.
    ///
    /// - Parameters:
    ///     - attribute: the (key, value) pair.
    ///
    /// - Returns: the `String` representation of the provided attribute.
    ///
    public func serialize(_ attribute: (key: String, value: ShortcodeAttributeValue)) -> String {
        return serialize(key: attribute.key, value: attribute.value)
    }
    
    /// Serializes a key and a value as a `String`.
    ///
    /// - Parameters:
    ///     - key: the key of the attribute.
    ///     - value: the value of the attribute.
    ///
    /// - Returns: the `String` representation of the provided key and value.
    ///
    public func serialize(key: String, value: ShortcodeAttributeValue) -> String {
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
