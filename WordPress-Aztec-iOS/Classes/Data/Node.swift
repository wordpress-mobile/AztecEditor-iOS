extension HTML {

    /// Base class for all node types.
    ///
    public class Node: CustomReflectable {

        private(set) var attributes = [Attribute]()
        let name: String

        public func customMirror() -> Mirror {
            return Mirror(self, children: ["name": name, "attributes": attributes])
        }

        init(name: String, attributes: [Attribute]) {
            self.name = name
            self.attributes.appendContentsOf(attributes)
        }
    }

    /// Element node.  Everything but text basically.
    ///
    public class ElementNode: Node {

        let children: [Node]

        init(name: String, attributes: [Attribute], children: [Node]) {
            self.children = children

            super.init(name: name, attributes: attributes)
        }

        override public func customMirror() -> Mirror {
            return Mirror(self, children: ["name": name, "attributes": attributes, "children": children], ancestorRepresentation: .Suppressed)
        }
    }

    /// Text nodes.  Cannot have child nodes (for now, not sure if we will need them).
    ///
    public class TextNode: Node {

        let text: String

        init(name: String, text: String, attributes: [Attribute]) {
            self.text = text

            super.init(name: name, attributes: attributes)
        }

        override public func customMirror() -> Mirror {
            return Mirror(self, children: ["name": name, "text": text, "attributes": attributes], ancestorRepresentation: .Suppressed)
        }
    }
}