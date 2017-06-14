import Foundation


// MARK: - HTMLAttributeRepresentation
//
class HTMLAttributeRepresentation: HTMLRepresentation, Equatable {

    typealias Attribute = Libxml2.Attribute
    typealias StringAttribute = Libxml2.StringAttribute

    /// The element that owns this attribute.
    ///
    var element: HTMLElementRepresentation?

    /// The attribute name.
    ///
    let name: String

    /// The attribute's value, if present.
    ///
    let value: String?

    /// Initializes the HTMLAttributeRepresentation Instance
    ///
    init(for attribute: Attribute, in element: HTMLElementRepresentation? = nil) {

        self.element = element
        name = attribute.name

        let stringAttribute = attribute as? StringAttribute
        value = stringAttribute?.value
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
}
