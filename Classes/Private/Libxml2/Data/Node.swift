extension Libxml2.HTML {

    /// Base class for all node types.
    ///
    class Node: Equatable, CustomReflectable {

        private(set) var attributes = [Attribute]()
        let name: String
        weak var parent: Node?

        func customMirror() -> Mirror {
            return Mirror(self, children: ["name": name, "parent": parent, "attributes": attributes])
        }

        init(name: String, attributes: [Attribute]) {
            self.name = name
            self.attributes.appendContentsOf(attributes)
        }
    }

    /// Element node.  Everything but text basically.
    ///
    class ElementNode: Node {

        let children: [Node]

        init(name: String, attributes: [Attribute], children: [Node]) {
            self.children = children

            super.init(name: name, attributes: attributes)
        }

        override func customMirror() -> Mirror {
            return Mirror(self, children: ["name": name, "parent": parent, "attributes": attributes, "children": children], ancestorRepresentation: .Suppressed)
        }
    }

    /// Text nodes.  Cannot have child nodes (for now, not sure if we will need them).
    ///
    class TextNode: Node {

        let text: String

        init(text: String, attributes: [Attribute]) {
            self.text = text

            super.init(name: "text", attributes: attributes)
        }

        override func customMirror() -> Mirror {
            return Mirror(self, children: ["name": name, "text": text, "parent": parent, "attributes": attributes], ancestorRepresentation: .Suppressed)
        }
    }
}

// MARK: - Node Equatable

func ==(lhs: Libxml2.HTML.Node, rhs: Libxml2.HTML.Node) -> Bool {
    return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
}