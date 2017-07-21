import Foundation


// MARK: - UnsupportedHTML NSAttributedString Attribute Name
//
let UnsupportedHTMLAttributeName = "UnsupportedHTMLAttributeName"


// MARK: - UnsupportedHTML
//
class UnsupportedHTML: NSObject {

    /// HTML Snippets not (natively) supported by the Editor (which will be re-serialized!!)
    ///
    private(set) var snippets = [String]()

    /// HTML Snippets not supported, converted back to their ElementNode representations
    ///
    var elements: [ElementNode] {
        let converter = InHTMLConverter()

        return snippets.flatMap { snippet in
            // Strip the Root Node(s): Always return the first child element
            let root = converter.convert(snippet)
            return root.children.first as? ElementNode
        }
    }

    /// Required Initializers
    ///
    public required convenience init?(coder aDecoder: NSCoder) {
        self.init()
        self.snippets = aDecoder.decodeObject(forKey: Keys.elements) as? [String] ?? []
    }

    /// Appends the specified Element Representation
    ///
    func append(element: ElementNode) {
        let snippet = OutHTMLConverter().convert(element)
        snippets.append(snippet)
    }
}


// MARK: - NSCoding Conformance
//
extension UnsupportedHTML: NSCoding {

    struct Keys {
        static let elements = "elements"
    }

    open func encode(with aCoder: NSCoder) {
        aCoder.encode(snippets, forKey: Keys.elements)
    }
}
