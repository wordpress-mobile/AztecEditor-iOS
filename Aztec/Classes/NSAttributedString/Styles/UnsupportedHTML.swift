import Foundation


// MARK: - UnsupportedHTML NSAttributedString Attribute Name
//
let UnsupportedHTMLAttributeName = "UnsupportedHTMLAttributeName"


// MARK: - UnsupportedHTML
//
class UnsupportedHTML: NSObject {

    /// HTML Snippets not supported, converted back to their ElementNode representations
    ///
    var elements = [ElementNode]()

    /// Required Initializers
    ///
    public required convenience init?(coder aDecoder: NSCoder) {
        self.init()

        guard let snippets = aDecoder.decodeObject(forKey: Keys.elements) as? [String] else {
            return
        }

        let converter = InHTMLConverter()
        self.elements = snippets.flatMap { snippet in
            // Strip the Root Node(s): Always return the first child element
            let root = converter.convert(snippet)
            return root.children.first as? ElementNode
        }
    }

    /// Appends the specified Element Representation
    ///
    func append(element: ElementNode) {
        elements.append(element)
    }
}


// MARK: - NSCoding Conformance
//
extension UnsupportedHTML: NSCoding {

    struct Keys {
        static let elements = "elements"
    }

    open func encode(with aCoder: NSCoder) {
        let converter = OutHTMLConverter()
        let snippets = elements.map { element in
            return converter.convert(element)
        }

        aCoder.encode(snippets, forKey: Keys.elements)
    }
}
