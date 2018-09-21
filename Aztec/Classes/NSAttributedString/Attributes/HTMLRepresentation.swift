import Foundation

/// This enum specifies the different entities that can represent a style in HTML.
///
public class HTMLRepresentation: NSObject, NSCoding {
    public enum Kind {
        case attribute(Attribute)
        case element(HTMLElementRepresentation)
        case inlineCss(CSSAttribute)
    }

    public let kind: Kind

    public init(for kind: Kind) {
        self.kind = kind
    }

    // MARK: - NSCoding

    struct Keys {
        static let attribute = "attribute"
        static let element = "element"
        static let inline = "inline"
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
public class HTMLElementRepresentation: NSObject, CustomReflectable, NSCoding {
    @objc let name: String
    @objc let attributes: [Attribute]

    init(name: String, attributes: [Attribute]) {
        self.name = name
        self.attributes = attributes
    }
    
    public convenience init(type: AttributeType, attributes: [Attribute]) {
        self.init(name: type.rawValue, attributes: attributes)
    }

    public convenience init(_ elementNode: ElementNode) {
        self.init(name: elementNode.name, attributes: elementNode.attributes)
    }

    // MARK: - NSCoding

    public required convenience init?(coder aDecoder: NSCoder) {
        guard let name = aDecoder.decodeObject(forKey: #keyPath(name)) as? String,
            let attributes = aDecoder.decodeObject(forKey: #keyPath(attributes)) as? [Attribute]
        else {
            fatalError()
        }

        self.init(name: name, attributes: attributes)
    }

    open func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: #keyPath(name))
        aCoder.encode(attributes, forKey: #keyPath(attributes))
    }

    // MARK: - CustomReflectable

    public var customMirror: Mirror {
        get {
            return Mirror(self, children: ["name": name, "attributes": attributes], ancestorRepresentation: .suppressed)
        }
    }

    // MARK: - Misc

    func attribute(named name: String) -> Attribute? {
        return attributes.first(where: { attribute -> Bool in
            return attribute.name == name
        })
    }
    
    func attribute(ofType type: AttributeType) -> Attribute? {
        return attributes.first(where: { attribute -> Bool in
            return attribute.type == type
        })
    }

    public func toElementNode() -> ElementNode {
        return ElementNode(name: name, attributes: attributes, children: [])
    }

    // MARK: - Equatable

    static func ==(lhs: HTMLElementRepresentation, rhs: HTMLElementRepresentation) -> Bool {
        return lhs.name == rhs.name && lhs.attributes == rhs.attributes
    }
}
