import Foundation

/// Represents a basic attribute with no value.  This is also the base class for all other
/// attributes.
///
public class Attribute: NSObject, CustomReflectable, NSCoding {

    // MARK: - Attribute Definition Properties

    let name: String
    var value: Value

    // MARK: - CSS Support

    let cssAttributeName = "style"

    // MARK: - Initializers
    
    public init(name: String, value: Value = .none) {
        self.name = name
        self.value = value
    }

    // MARK: - CustomReflectable

    public var customMirror: Mirror {
        get {
            return Mirror(self, children: ["name": name, "value": value])
        }
    }

    // MARK - Hashable

    public override var hashValue: Int {
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

            let properties = components.flatMap { CSSAttribute(for: $0) }

            guard !properties.isEmpty else {
                self = .string(cssString)
                return
            }

            self = .inlineCss(properties)
        }


        // MARK: - Hashable

        public var hashValue: Int {
            switch(self) {
            case .none:
                return 0
            case .string(let string):
                return string.hashValue
            case .inlineCss(let cssAttributes):
                return cssAttributes.reduce(0, { (previous, cssAttribute) -> Int in
                    return previous ^ cssAttribute.hashValue
                })
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

        func toString() -> String? {
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
