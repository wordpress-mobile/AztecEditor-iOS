extension Libxml2 {

    /// Represents a basic attribute with no value.  This is also the base class for all other
    /// attributes.
    ///
    class Attribute: CustomReflectable, Equatable, Hashable {
        let name: String
        
        // MARK: - CustomReflectable
        
        public var customMirror: Mirror {
            get {
                return Mirror(self, children: ["name": name])
            }
        }
        
        // MARK: - Initializers
        
        init(name: String) {
            self.name = name
        }


        // MARK - Hashable

        var hashValue: Int {
            return name.hashValue
        }

        // MARK: - Equatable

        static func ==(lhs: Attribute, rhs: Attribute) -> Bool {
            return type(of: lhs) == type(of: rhs) && lhs.name == rhs.name
        }
    }


    /// Represents an attribute with an generic string value.  This is useful for storing attributes
    /// that do have a value, which we don't know how to parse.  This is only meant as a mechanism
    /// to maintain the attribute's information.
    ///
    class StringAttribute: Attribute {
        var value: String
        
        // MARK: - CustomReflectable
        
        override public var customMirror: Mirror {
            return Mirror(self, children: ["name": name, "value": value], ancestorRepresentation: .suppressed)
        }
        
        // MARK: - Initializers
        
        init(name: String, value: String) {
            self.value = value

            super.init(name: name)
        }

        // MARK - Hashable

        override var hashValue: Int {
            return name.hashValue ^ value.hashValue
        }


        // MARK: - Equatable

        static func ==(lhs: StringAttribute, rhs: StringAttribute) -> Bool {
            return type(of: lhs) == type(of: rhs) && lhs.name == rhs.name && lhs.value == rhs.value
        }
    }
}
