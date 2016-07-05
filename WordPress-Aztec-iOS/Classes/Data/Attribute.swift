extension HTML {

    /// Represents a basic attribute with no value.  This is also the base class for all other
    /// attributes.
    ///
    class Attribute: CustomDebugStringConvertible {
        let name: String

        init(name: String) {
            self.name = name
        }

        public var debugDescription: String {
            get {
                return "<\(String(self.dynamicType))> {\n  ▿ name: \(name)\n}"
            }
        }
    }

    /// Represents an attribute with an generic string value.  This is useful for storing attributes
    /// that do have a value, which we don't know how to parse.  This is only meant as a mechanism
    /// to maintain the attribute's information.
    ///
    class StringAttribute: Attribute {
        let value: String

        init(name: String, value: String) {
            self.value = value

            super.init(name: name)
        }

        override public var debugDescription: String {
            get {
                return "<\(String(self.dynamicType))> {\n  ▿ name: \(name);\n  ▿ value: \(value)\n}"
            }
        }
    }
}