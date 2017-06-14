

class HTMLElementRepresentation: HTMLRepresentation, CustomReflectable {

    typealias ElementNode = Libxml2.ElementNode

    /// The element's name.
    ///
    let name: String

    /// The meta-data for the associated HTML attributes.
    ///
    var attributes = [HTMLAttributeRepresentation]()

    init(for element: ElementNode) {
        name = element.name

        for attribute in element.attributes {
            attributes.append(HTMLAttributeRepresentation(for: attribute))
        }
    }

    // MARK: - CustomReflectable

    public var customMirror: Mirror {
        get {
            return Mirror(self, children: ["name": name, "attributes": attributes])
        }
    }
}
