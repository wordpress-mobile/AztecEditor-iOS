import Foundation


// MARK: - UnsupportedHTML NSAttributedString Attribute Name
//
let UnsupportedHTMLAttributeName = "UnsupportedHTMLAttributeName"


// MARK: - UnsupportedHTML
//
class UnsupportedHTML {

    /// Nodes not supported by the Editor (which will be re-serialized!!)
    ///
    private(set) var elements = [HTMLElementRepresentation]()

    /// Adds the specified Element Representation
    ///
    func add(element: HTMLElementRepresentation) {
        elements.append(element)
    }

    /// Removes the specified Element Representation
    ///
    func remove(element: HTMLElementRepresentation) {
        guard let index = elements.index(where: { $0 == element }) else {
            return
        }

        elements.remove(at: index)
    }
}
