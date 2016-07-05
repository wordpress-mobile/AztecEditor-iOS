extension HTML {

    /// Base class for all node types.
    ///
    public class Node: CustomDebugStringConvertible {

        private(set) var attributes = [Attribute]()
        let name: String

        public var debugDescription: String {
            get {
                return "<\(self.dynamicType)> {\n  name: \(name);\n  attributes: \(attributes)\n}"
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
                return "<\(self.dynamicType)> {\n  ▿ name: \(name);\n  ▿ attributes: \(attributesDebugDescription())  ▿ children: \(childrenDebugDescription())}"
            }
        }

        init(name: String, attributes: [Attribute], children: [Node]) {
            self.children = children

            super.init(name: name, attributes: attributes)
        }

        private func attributesDebugDescription() -> String {
            let attributesDebugDescription = "\(attributes)"
            var indentedDebugDescription = ""

            attributesDebugDescription.enumerateLines { (line, stop) in
                var newLine = line

                if line.characters.first != "[" {
                    newLine = "    \(newLine)"
                }

                newLine = "\(newLine)\n"

                indentedDebugDescription.appendContentsOf(newLine)
            }
            
            return indentedDebugDescription
        }

        private func childrenDebugDescription() -> String {
            let childrenDebugDescription = "\(children)"
            var indentedDebugDescription = ""

            childrenDebugDescription.enumerateLines { (line, stop) in
                var newLine = line

                if line.characters.first != "[" {
                    newLine = "    \(newLine)"
                }

                newLine = "\(newLine)\n"

                indentedDebugDescription.appendContentsOf(newLine)
            }

            return indentedDebugDescription
        }
    }

    /// Text nodes.  Cannot have child nodes (for now, not sure if we will need them).
    ///
    public class TextNode: Node {

        let text: String

        override public var debugDescription: String {
            get {
                return "<\(self.dynamicType)> {\n  ▿ name: \(name);\n  ▿ text: \(text);\n  ▿ attributes: \(attributes)\r\n}"
            }
        }

        init(name: String, text: String, attributes: [Attribute]) {
            self.text = text

            super.init(name: name, attributes: attributes)
        }
    }
}