import Foundation


// MARK: - HTMLElementRepresentation
//
class HTMLElementRepresentation: HTMLRepresentation, Equatable, CustomReflectable {

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

    func valueForAttribute(named name: String) -> String? {
        for attribute in attributes {
            guard attribute.name == name else {
                continue
            }

            return attribute.value
        }

        return nil
    }


    /// Returns the ElementNode Instance for the current definition.
    ///
    func toNode() -> ElementNode {
        let attributes = self.attributes.flatMap { representation in
            return representation.toAttribute()
        }

        return ElementNode(name: name, attributes: attributes, children: [])
    }


    // MARK: - Equatable

    static func ==(lhs: HTMLElementRepresentation, rhs: HTMLElementRepresentation) -> Bool {
        return type(of: lhs) == type(of: rhs) && lhs.name == rhs.name && lhs.attributes == rhs.attributes
    }

    // MARK: - CustomReflectable

    public var customMirror: Mirror {
        get {
            return Mirror(self, children: ["name": name, "attributes": attributes])
        }
    }
}
