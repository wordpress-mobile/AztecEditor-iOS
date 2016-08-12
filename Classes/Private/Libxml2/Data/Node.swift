extension Libxml2.HTML {

    /// Base class for all node types.
    ///
    class Node: Equatable, CustomReflectable {

        let name: String
        weak var parent: Node?

        func customMirror() -> Mirror {
            return Mirror(self, children: ["name": name, "parent": parent])
        }

        init(name: String) {
            self.name = name
        }
    }

    /// Element node.  Everything but text basically.
    ///
    class ElementNode: Node {

        private(set) var attributes = [Attribute]()
        let children: [Node]

        init(name: String, attributes: [Attribute], children: [Node]) {
            self.children = children
            self.attributes.appendContentsOf(attributes)

            super.init(name: name)
        }

        override func customMirror() -> Mirror {
            return Mirror(self, children: ["type": "element", "name": name, "parent": parent, "attributes": attributes, "children": children], ancestorRepresentation: .Suppressed)
        }
    }

    /// Text nodes.  Cannot have child nodes (for now, not sure if we will need them).
    ///
    class TextNode: Node {

        let text: String

        init(text: String) {
            self.text = text

            super.init(name: "text")
        }

        override func customMirror() -> Mirror {
            return Mirror(self, children: ["type": "text", "name": name, "text": text, "parent": parent], ancestorRepresentation: .Suppressed)
        }
    }

    class RootNode: ElementNode {

        static let name = "aztec.htmltag.rootnode"

        init(children: [Node]) {
            super.init(name: self.dynamicType.name, attributes: [], children: children)
        }
    }
}

// MARK: - Node Equatable

func ==(lhs: Libxml2.HTML.Node, rhs: Libxml2.HTML.Node) -> Bool {
    return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
}