import Foundation


// MARK: - UnsupportedHTML NSAttributedString Attribute Name
//
let UnsupportedHTMLAttributeName = "UnsupportedHTMLAttributeName"


// MARK: - UnsupportedHTML
//
class UnsupportedHTML {

    /// Typealiases
    ///
    typealias ElementNode = Libxml2.ElementNode

    /// Nodes not supported by the Editor (which will be re-serialized!!)
    ///
    private(set) var nodes = [ElementNode]()

    /// Adds the specified ElementNode Instance
    ///
    func add(node: ElementNode) {
        nodes.append(node)
    }

    /// Removes the specified ElementNode Instance
    ///
    func remove(node: ElementNode) {
        guard let index = nodes.index(where: { $0 == node }) else {
            return
        }

        nodes.remove(at: index)
    }
}
