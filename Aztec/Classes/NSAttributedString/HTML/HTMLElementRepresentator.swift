import Foundation


// MARK: - HTMLElementRepresentation
//
class HTMLElementRepresentation: HTMLRepresentation, Equatable {

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


    // MARK: - Equatable

    static func ==(lhs: HTMLElementRepresentation, rhs: HTMLElementRepresentation) -> Bool {
        return type(of: lhs) == type(of: rhs) && lhs.name == rhs.name && lhs.attributes == rhs.attributes
    }
}
