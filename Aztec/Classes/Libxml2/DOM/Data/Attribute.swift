import Foundation

/// Represents a basic attribute with no value.  This is also the base class for all other
/// attributes.
///
public class Attribute: NSObject, CustomReflectable, NSCoding {

    // MARK: - Attribute Definition Properties

    public let name: String
    public var value: Value
    
    /// The attribute type, if it matches an existing one.
    ///
    public var type: AttributeType {
        get {
            return AttributeType(name)
        }
    }

    // MARK: - Initializers
    
    public init(name: String, value: Value = .none) {
        self.name = name
        self.value = value
    }
    
    public convenience init(type: AttributeType, value: Value = .none) {
        self.init(name: type.rawValue, value: value)
    }

    // MARK: - CustomReflectable

    public var customMirror: Mirror {
        get {
            return Mirror(self, children: ["name": name, "value": value])
        }
    }

    // MARK - Hashable
    
    override public var hash: Int {
        return name.hashValue ^ value.hashValue
    }

    // MARK: - NSCoding

    struct Keys {
        static let name = "name"
        static let value = "value"
    }

    public required convenience init?(coder aDecoder: NSCoder) {
        // TODO: This is a Work in Progress. Let's also get Attribute conforming to Codable!
        guard let name = aDecoder.decodeObject(forKey: Keys.name) as? String,
            let rawValue = aDecoder.decodeObject(forKey: Keys.value) as? Data,
            let value = try? JSONDecoder().decode(Value.self, from: rawValue) else
        {
            assertionFailure("Review the logic.")
            return nil
        }

        self.init(name: name, value: value)
    }

    open func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: Keys.name)

        // TODO: This is a Work in Progress. Let's also get Attribute conforming to Codable!
        if let encodedValue = try? JSONEncoder().encode(value) {
            aCoder.encode(encodedValue, forKey: Keys.value)
        }
    }

    // MARK: - Equatable

    public override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? Attribute else {
            return false
        }

        return name == rhs.name && value == rhs.value
    }

    // MARK: - String Representation

    public func toString() -> String {
        var result = name

        if let stringValue = value.toString() {
            result += "=\"" + stringValue + "\""
        }

        return result
    }

    // MARK: - CSS Support

    public func containsCSSAttribute(matching matcher: CSSAttributeMatcher) -> Bool {
        guard let cssAttributes = value.cssAttributes() else {
            return false
        }
        
        return cssAttributes.contains(where: { matcher.check($0) })
    }
    
    func containsCSSAttribute(where check: (CSSAttribute) -> Bool) -> Bool {
        guard let cssAttributes = value.cssAttributes() else {
            return false
        }
        
        return cssAttributes.contains(where: { check($0) })
    }
    
    public func cssAttributes() -> [CSSAttribute]? {
        return value.cssAttributes()
    }
    
    public func firstCSSAttribute(ofType type: CSSAttributeType) -> CSSAttribute? {
        return value.firstCSSAttribute(ofType: type)
    }
    
    /// Removes the CSS attributes matching a specified condition.
    ///
    /// - Parameters:
    ///     - check: the condition that defines what CSS attributes will be removed.
    ///
    public func removeCSSAttributes(matching check: (CSSAttribute) -> Bool) {
        guard case let .inlineCss(cssAttributes) = value else {
            return
        }
        
        let newCSSAttributes = cssAttributes.compactMap { (cssAttribute) -> CSSAttribute? in
            guard !check(cssAttribute) else {
                return nil
            }
            
            return cssAttribute
        }
        
        value = .inlineCss(newCSSAttributes)
    }
    
    public func removeCSSAttributes(matching matcher: CSSAttributeMatcher) {
        guard case let .inlineCss(cssAttributes) = value else {
            return
        }
        
        let newCSSAttributes = cssAttributes.compactMap { (cssAttribute) -> CSSAttribute? in
            guard !matcher.check(cssAttribute) else {
                return nil
            }
            
            return cssAttribute
        }
        
        value = .inlineCss(newCSSAttributes)
    }
}


// MARK: - Attribute.Value

extension Attribute {


    /// Allowed attribute values
    ///
    public enum Value: Equatable, Hashable {
        case none
        case string(String)
        case inlineCss([CSSAttribute])

        // MARK: - Initializers

        init(withString string: String) {
            self = .string(string)
        }

        init(withCSSString cssString: String) {

            let components = cssString.components(separatedBy: CSSParser.attributeSeparator)

            guard !components.isEmpty else {
                self = .none
                return
            }

            let properties = components.compactMap { CSSAttribute(for: $0) }

            guard !properties.isEmpty else {
                self = .string(cssString)
                return
            }

            self = .inlineCss(properties)
        }


        // MARK: - Hashable

        public func hash(into hasher: inout Hasher) {
            switch(self) {
            case .none:
                hasher.combine(0)
            case .string(let string):
                hasher.combine(string)
            case .inlineCss(let cssAttributes):
                hasher.combine(cssAttributes)
            }
        }


        // MARK: - Equatable

        public static func ==(lValue: Value, rValue: Value) -> Bool {
            switch(lValue) {
            case .none:
                return true
            case .string(let string):
                return string == rValue
            case .inlineCss(let cssProperties):
                return cssProperties == rValue
            }
        }

        static func ==(lValue: Value, rString: String) -> Bool {
            return rString == lValue
        }

        static func ==(lString: String, rValue: Value) -> Bool {
            switch(rValue) {
            case .string(let rString):
                return lString == rString
            default:
                return false
            }
        }

        static func ==(lValue: Value, rProperties: [CSSAttribute]) -> Bool {
            return rProperties == lValue
        }

        static func ==(lProperties: [CSSAttribute], rValue: Value) -> Bool {
            switch(rValue) {
            case .inlineCss(let rProperties):
                return lProperties == rProperties
            default:
                return false
            }
        }


        // MARK: - String Representation

        public func toString() -> String? {
            switch(self) {
            case .none:
                return nil
            case .string(let string):
                return string
            case .inlineCss(let properties):
                var result = ""

                for (index, property) in properties.enumerated() {
                    result += property.toString()

                    if index < properties.count - 1 {
                        result += CSSParser.attributeSeparator + " "
                    }
                }
                
                return result
            }
        }
        
        // MARK: - CSS
        
        public func firstCSSAttribute(named name: String) -> CSSAttribute? {
            guard let cssAttributes = cssAttributes()  else {
                return nil
            }
            
            return cssAttributes.first(where: { $0.name == name })
        }
        
        public func firstCSSAttribute(ofType type: CSSAttributeType) -> CSSAttribute? {
            guard let cssAttributes = cssAttributes()  else {
                return nil
            }
            
            return cssAttributes.first(where: { $0.type == type })
        }
        
        public func cssAttributes() -> [CSSAttribute]? {
            guard case let .inlineCss(cssAttributes) = self else {
                return nil
            }
            
            return cssAttributes
        }
    }
}


// MARK: - Attribute.Value Codable Conformance
//
extension Attribute.Value: Codable {

    enum CodingError: Error {
        case missingTypeKey
    }

    private enum ValueKey: String, CodingKey {
        case none
        case string
        case inlineCss
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: ValueKey.self)

        guard let rootKey = values.allKeys.first, let valueKind = ValueKey(rawValue: rootKey.rawValue) else {
            throw CodingError.missingTypeKey
        }

        switch valueKind {
        case .none:
            // IMPORTANT: the `Value` prefix serves as disambiguation, since optionals also have
            // a .none value!!!  Don't remove it!
            //
            self = Attribute.Value.none
        case .string:
            let string = try? values.decode(String.self, forKey: .string)
            self = .string(string ?? "")
        case .inlineCss:
            let attributes = try? values.decode([CSSAttribute].self, forKey: .inlineCss)
            self = .inlineCss(attributes ?? [])
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ValueKey.self)

        switch self {
        case .none:
            try container.encodeNil(forKey: .none)
        case .string(let string):
            try container.encode(string, forKey: .string)
        case .inlineCss(let attributes):
            try container.encode(attributes, forKey: .inlineCss)
        }
    }
}
