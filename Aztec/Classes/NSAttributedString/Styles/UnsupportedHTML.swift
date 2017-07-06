import Foundation


// MARK: - UnsupportedHTML NSAttributedString Attribute Name
//
let UnsupportedHTMLAttributeName = "UnsupportedHTMLAttributeName"


// MARK: - UnsupportedHTML
//
class UnsupportedHTML {

    /// Nodes not supported by the Editor (which will be re-serialized!!)
    ///
    private(set) var elements = [ElementNode]()

    /// Adds the specified Element Representation
    ///
    func add(element: ElementNode) {
        elements.append(element)
    }

    /// Removes the specified Element Representation
    ///
    func remove(element: ElementNode) {
        guard let index = elements.index(where: { $0 == element }) else {
            return
        }

        elements.remove(at: index)
    }
}
