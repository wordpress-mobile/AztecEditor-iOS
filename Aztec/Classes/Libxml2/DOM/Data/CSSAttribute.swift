import Foundation


// MARK: - CSSAttribute
//
public class CSSAttribute: Codable {

    /// Attribute Name
    ///
    let name: String

    /// Attribute Value, if any!
    ///
    let value: String?
    
    /// The attribute type, if it matches an existing one.
    ///
    public var type: CSSAttributeType {
        get {
            return CSSAttributeType(name)
        }
    }
    
    static let bold: CSSAttribute = {
        return CSSAttribute(type: .fontWeight, value: FontWeight.bold.rawValue)
    }()
    
    static let italic: CSSAttribute = {
        return CSSAttribute(type: .fontStyle, value: FontStyle.italic.rawValue)
    }()
    
    static let underline: CSSAttribute = {
       return CSSAttribute(type: .textDecoration, value: TextDecoration.underline.rawValue)
    }()


    // MARK: - Initializers

    init(name: String, value: String? = nil) {
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.value = value?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    convenience init(type: CSSAttributeType, value: String? = nil) {
        self.init(name: type.rawValue, value: value)
    }

    convenience init?(for string: String) {
        let components = string.components(separatedBy: CSSParser.keyValueSeparator)
        guard let name = components.first, let value = components.last, components.count == 2 else {
            return nil
        }

        self.init(name: name, value: value)
    }

    // MARK: - Public Methods

    func toString() -> String {
        guard let value = value else {
            return name
        }

        return name + CSSParser.keyValueSeparator + " " + value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}


// MARK: - CustomReflectable Conformance
//
extension CSSAttribute: CustomReflectable {

    public var customMirror: Mirror {
        get {
            return Mirror(self, children: ["name": name, "value": value ?? ""])
        }
    }
}


// MARK: - Hashable Conformance
//
extension CSSAttribute: Hashable {

    public func hash(into hasher: inout Hasher) {
        if let value = value {
            hasher.combine(value)
        }
        hasher.combine(name)
    }
}


// MARK: - Equatable Conformance
//
extension CSSAttribute: Equatable {

    func isEqual(_ object: Any?) -> Bool {
        guard let rightValue = object as? CSSAttribute else {
            return false
        }

        return self == rightValue
    }

    public static func ==(leftValue: CSSAttribute, rightValue: CSSAttribute) -> Bool {
        return leftValue.name == rightValue.name && leftValue.value == rightValue.value
    }
}
