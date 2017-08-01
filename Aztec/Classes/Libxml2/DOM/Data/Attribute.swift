import Foundation

/// Represents a basic attribute with no value.  This is also the base class for all other
/// attributes.
///
class Attribute: NSObject, CustomReflectable {

    // MARK: - Attribute Definition Properties

    let name: String
    var value: Value
    
    // MARK: - Initializers
    
    init(name: String, value: Value = .none) {
        self.name = name
        self.value = value
    }

    init(name: String, string: String?) {
        self.name = name
        self.value = Value(for: string)
    }


    // MARK: - CustomReflectable

    public var customMirror: Mirror {
        get {
            return Mirror(self, children: ["name": name, "value": value])
        }
    }

    // MARK - Hashable

    override var hashValue: Int {
        return name.hashValue ^ value.hashValue
    }

    // MARK: - NSCoding

    public required convenience init?(coder aDecoder: NSCoder) {
        guard let name = aDecoder.decodeObject(forKey: Keys.name) as? String,
            let valueAsString = aDecoder.decodeObject(forKey: Keys.value) as? String?
        else {
            fatalError()
        }

        self.init(name: name, string: valueAsString)
    }

    // MARK: - Equatable

    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? Attribute else {
            return false
        }

        return name == rhs.name && value == rhs.value
    }

    // MARK: - String Representation

    func toString() -> String {
        var result = name

        if let stringValue = value.toString() {
            result += "=\"" + stringValue + "\""
        }

        return result
    }
}


// MARK: - NSCoding Conformance
//
extension Attribute: NSCoding {

    struct Keys {
        static let name = "name"
        static let value = "value"
    }

    open func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: Keys.name)
        aCoder.encode(value.toString(), forKey: Keys.value)
    }
}


// MARK: - Attribute.Value

extension Attribute {

    /// Allowed attribute values
    ///
    enum Value: Equatable, Hashable {
        case none
        case string(String)
        case inlineCss([CSSProperty])


        // MARK: - Constants

        static let cssPropertySeparator = "; "


        // MARK: - Initializers

        init(for string: String?) {
            let components = string?.components(separatedBy: Value.cssPropertySeparator) ?? []
            if components.isEmpty {
                self = .none
                return
            }

            let properties = components.flatMap { CSSProperty(for: $0) }
            if !properties.isEmpty {
                self = .inlineCss(properties)
                return
            }

            let first = components.first ?? String()
            self = .string(first)
        }


        // MARK: - Hashable

        var hashValue: Int {
            switch(self) {
            case .none:
                return 0
            case .string(let string):
                return string.hashValue
            case .inlineCss(let cssProperties):
                var hash = 0
                for property in cssProperties {
                    hash ^= property.hashValue
                }

                return hash
            }
        }


        // MARK: - Equatable

        static func ==(lValue: Value, rValue: Value) -> Bool {
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

        static func ==(lValue: Value, rProperties: [CSSProperty]) -> Bool {
            return rProperties == lValue
        }

        static func ==(lProperties: [CSSProperty], rValue: Value) -> Bool {
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
                        result += Value.cssPropertySeparator
                    }
                }
                
                return result
            }
        }
    }
}
