
class HTMLAttributeRepresentation: HTMLRepresentation {

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

    init(for attribute: Attribute, in element: HTMLElementRepresentation? = nil) {

        self.element = element
        name = attribute.name

        if let stringAttribute = attribute as? StringAttribute {
            value = stringAttribute.value
        } else {
            value = nil
        }
    }
}
