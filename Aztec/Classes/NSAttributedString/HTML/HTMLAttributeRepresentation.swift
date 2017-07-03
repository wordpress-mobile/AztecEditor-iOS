import Foundation


// MARK: - HTMLAttributeRepresentation
//
class HTMLAttributeRepresentation: HTMLRepresentation, Equatable, CustomReflectable {

    typealias Attribute = Libxml2.Attribute

    enum Value {
        case none
        case string(String)
        case inlineCss([CSSPropertyRepresentation])

        func toString() -> String {
            switch(self) {
            case .none:
                return ""
            case .string(let string):
                return string
            case .inlineCss(let cssProperties):
                return cssProperties.reduce("", { (previousString, property) -> String in
                    let initialString = previousString.characters.count > 0 ? previousString + "; " : ""

                    return initialString + property.toString()
                })
            }
        }
    }

    /// The element that owns this attribute.
    ///
    var element: HTMLElementRepresentation?

    /// The attribute name.
    ///
    let name: String

    /// The attribute's value, if present.
    ///
    let value: Value

    /// Initializes the HTMLAttributeRepresentation Instance
    ///
    init(for attribute: Attribute, in element: HTMLElementRepresentation? = nil) {

        self.element = element
        name = attribute.name

        if let stringAttribute = attribute as? StringAttribute {
            value = .string(stringAttribute.value)
        } else if let inlineCssAttribute = attribute as? [String] {
            value = .inlineCss(inlineCssAttribute)
        }
    }


    /// Returns the Attribute instance for the current representation
    ///
    func toAttribute() -> Attribute {
        guard let value = value else {
            return Attribute(name: name)
        }

        return StringAttribute(name: name, value: value)
    }


    // MARK: - Equatable

    static func ==(lhs: HTMLAttributeRepresentation, rhs: HTMLAttributeRepresentation) -> Bool {
        return type(of: lhs) == type(of: rhs) && lhs.name == rhs.name && lhs.value == rhs.value
    }

    // MARK: - CustomReflectable

    public var customMirror: Mirror {
        get {
            let value = self.value ?? ""

            return Mirror(self, children: ["name": name, "value": value])
        }
    }
}
