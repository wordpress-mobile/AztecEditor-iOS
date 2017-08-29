import Foundation

/// This enum specifies the different entities that can represent a style in HTML.
///
class HTMLRepresentation: NSObject {
    enum Kind {
        case attribute(Attribute)
        case element(HTMLElementRepresentation)
        case inlineCss(CSSAttribute)
    }

    let kind: Kind

    init(for kind: Kind) {
        self.kind = kind
    }

    public required init?(coder aDecoder: NSCoder) {
        if let attribute = aDecoder.decodeObject(forKey: Keys.attribute) as? Attribute {
            kind = .attribute(attribute)
            return
        }

        if let element = aDecoder.decodeObject(forKey: Keys.element) as? HTMLElementRepresentation {
            kind = .element(element)
            return
        }

        if let rawCSS = aDecoder.decodeObject(forKey: Keys.inline) as? String,
            let decodedCSS = CSSAttribute(for: rawCSS) {
            kind = .inlineCss(decodedCSS)
            return
        }

        fatalError()
    }
}


// MARK: - NSCoding Conformance
//
extension HTMLRepresentation: NSCoding {

    struct Keys {
        static let attribute = "attribute"
        static let element = "element"
        static let inline = "inline"
    }

    open func encode(with aCoder: NSCoder) {
        switch kind {
        case .attribute(let attribute):
            aCoder.encode(attribute, forKey: Keys.attribute)
        case .element(let element):
            aCoder.encode(element, forKey: Keys.element)
        case .inlineCss(let css):
            aCoder.encode(css.toString(), forKey: Keys.inline)
        }
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

    public required convenience init?(coder aDecoder: NSCoder) {
        guard let name = aDecoder.decodeObject(forKey: Keys.name) as? String,
            let attributes = aDecoder.decodeObject(forKey: Keys.attributes) as? [Attribute]
        else {
            fatalError()
        }

        self.init(name: name, attributes: attributes)
    }

    func attribute(named name: String) -> Attribute? {
        return attributes.first(where: { attribute -> Bool in
            return attribute.name == name
        })
    }

    func toElementNode() -> ElementNode {
        return ElementNode(name: name, attributes: attributes, children: [])
    }

    // MARK: - Equatable

    static func ==(lhs: HTMLElementRepresentation, rhs: HTMLElementRepresentation) -> Bool {
        return type(of: lhs) == type(of: rhs) && lhs.name == rhs.name && lhs.attributes == rhs.attributes
    }
}


// MARK: - NSCoding Conformance
//
extension HTMLElementRepresentation: NSCoding {

    struct Keys {
        static let name = "name"
        static let attributes = "attributes"
    }

    open func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: Keys.name)
        aCoder.encode(attributes, forKey: Keys.attributes)
    }
}
