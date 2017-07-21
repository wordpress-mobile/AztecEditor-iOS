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


    // MARK: - CustomReflectable

    public var customMirror: Mirror {
        get {
            return Mirror(self, children: ["name": name, "value": value])
        }
    }

    // MARK - Hashable

    override var hashValue: Int {
        return name.hashValue ^ value.hashValue()
    }

    // MARK: - Equatable

    static func ==(lhs: Attribute, rhs: Attribute) -> Bool {
        return type(of: lhs) == type(of: rhs) && lhs.name == rhs.name && lhs.value == rhs.value
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

// MARK: - Attribute.Value

extension Attribute {

    /// Allowed attribute values
    ///
    enum Value: Equatable {
        case none
        case string(String)
        case inlineCss([CSSProperty])

        
        // MARK: - Constants

        static let cssPropertySeparator = "; "


        // MARK: - Initializers

        init(string: String?) {
            let components = string?.components(separatedBy: Value.cssPropertySeparator) ?? []
            if components.isEmpty {
                self = .none
                return
            }

            if components.count == 1, let first = components.first {
                self = .string(first)
                return
            }

            let properties = components.flatMap { CSSProperty(string: $0) }
            self = .inlineCss(properties)
        }


        // MARK: - Hashable

        func hashValue() -> Int {
            switch(self) {
            case .none:
                return 0
            case .string(let string):
                return string.hashValue
            case .inlineCss(let cssProperties):
                return cssProperties.reduce(0, { (previousHash, property) -> Int in
                    return previousHash ^ property.hashValue
                })
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
