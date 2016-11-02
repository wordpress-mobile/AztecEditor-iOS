extension Libxml2 {

    /// Represents a basic attribute with no value.  This is also the base class for all other
    /// attributes.
    ///
    class Attribute: CustomReflectable {
        let name: String

        init(name: String) {
            self.name = name
        }

        func customMirror() -> Mirror {
            return Mirror(self, children: ["name": name])
        }
    }

    /// Represents an attribute with an generic string value.  This is useful for storing attributes
    /// that do have a value, which we don't know how to parse.  This is only meant as a mechanism
    /// to maintain the attribute's information.
    ///
    class StringAttribute: Attribute {
        var value: String

        init(name: String, value: String) {
            self.value = value

            super.init(name: name)
        }

        override func customMirror() -> Mirror {
            return Mirror(self, children: ["name": name, "value": value], ancestorRepresentation: .Suppressed)
        }
    }
}
