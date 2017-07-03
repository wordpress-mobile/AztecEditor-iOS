extension Libxml2 {

    /// Represents a basic attribute with no value.  This is also the base class for all other
    /// attributes.
    ///
    class Attribute: CustomReflectable, Equatable, Hashable {

        /// Allowed attribute values
        ///
        enum Value {
            case none
            case string(String)
            case inlineCss([CSSProperty])

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
        }

        // MARK: - Attribute Definition Properties

        let name: String
        let value: Value
        
        // MARK: - CustomReflectable
        
        public var customMirror: Mirror {
            get {
                return Mirror(self, children: ["name": name, "value": value])
            }
        }
        
        // MARK: - Initializers
        
        init(name: String, value: Value = .none) {
            self.name = name
            self.value = value
        }

        // MARK - Hashable

        var hashValue: Int {
            return name.hashValue ^ value.hashValue
        }

        // MARK: - Equatable

        static func ==(lhs: Attribute, rhs: Attribute) -> Bool {
            return type(of: lhs) == type(of: rhs) && lhs.name == rhs.name && lhs.value == rhs.value
        }
    }
}
