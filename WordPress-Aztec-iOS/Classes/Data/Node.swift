extension HTML {

    /// Base class for all node types.
    ///
    public class Node: CustomDebugStringConvertible {

        private(set) var attributes = [Attribute]()
        let name: String

        public var debugDescription: String {
            get {
                return "<\(String(self.dynamicType)): {name: \(name); attributes: \(String(attributes))}>"
            }
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

        override public var debugDescription: String {
            get {
                return "<\(String(self.dynamicType)): {name: \(name); attributes: \(String(attributes)); children: \(String(children))}>"
            }
        }

        init(name: String, attributes: [Attribute], children: [Node]) {
            self.children = children

            super.init(name: name, attributes: attributes)
        }
    }

    /// Text nodes.  Cannot have child nodes (for now, not sure if we will need them).
    ///
    public class TextNode: Node {

        let text: String

        override public var debugDescription: String {
            get {
                return "<\(String(self.dynamicType)): {name: \(name); text: \(String(text)); attributes: \(String(attributes))}>"
            }
        }

        init(name: String, text: String, attributes: [Attribute]) {
            self.text = text

            super.init(name: name, attributes: attributes)
        }
    }
}