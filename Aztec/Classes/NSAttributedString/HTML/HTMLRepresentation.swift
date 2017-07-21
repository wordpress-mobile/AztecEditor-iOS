import Foundation

/// This enum specifies the different entities that can represent a style in HTML.
///
class HTMLRepresentation: NSObject {
    enum Kind {
        case attribute(Attribute)
        case element(HTMLElementRepresentation)
        case inlineCss(CSSProperty)
    }

    let kind: Kind

    init(kind: Kind) {
        self.kind = kind
    }

}


// MARK: - HTMLElementRepresentation
//
class HTMLElementRepresentation: NSObject {
    let name: String
    let attributes: [Attribute]

    init(name: String, attributes: [Attribute]) {
        self.name = name
        self.attributes = attributes
    }

    convenience init(_ elementNode: ElementNode) {
        self.init(name: elementNode.name, attributes: elementNode.attributes)
    }

    func attribute(named name: String) -> Attribute? {
        return attributes.first(where: { attribute -> Bool in
            return attribute.name == name
        })
    }

    func toElementNode() -> ElementNode {
        return ElementNode(name: name, attributes: attributes, children: [])
    }
}
