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

        /// Override.
        ///
        func length() -> Int {
            assertionFailure("This method should always be overridden.")
            return 0
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

        /// Node length.  Calculated by adding the length of all child nodes.
        ///
        override func length() -> Int {

            var length = 0

            for child in children {
                length += child.length()
            }

            return length
        }

        /// Returns the lowest-level element node in this node's hierarchy that wraps the specified
        /// range.  If no child element node wraps the specified range, this method returns this
        /// node.
        ///
        /// - Parameters:
        ///     - range: the range we want to find the wrapping node of.
        ///
        /// - Returns: the lowest-level element node wrapping the specified range, or this node if
        ///         no child node fulfills the condition.
        ///
        func lowestElementNodeWrapping(range: NSRange) -> ElementNode {

            var offset = 0

            for child in children {
                let length = child.length()
                let nodeRange = NSRange(location: offset, length: length)
                let nodeWrapsRange = (NSUnionRange(nodeRange, range).length == nodeRange.length)

                if nodeWrapsRange {
                    if let elementNode = child as? ElementNode {

                        let childRange = NSRange(location: range.location - offset, length: range.length)

                        return elementNode.lowestElementNodeWrapping(range)
                    } else {
                        return self
                    }
                }

                offset = offset + length
            }

            return self
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

        /// Node length.
        ///
        override func length() -> Int {
            return text.characters.count
        }
    }
}

// MARK: - Node Equatable

func ==(lhs: Libxml2.HTML.Node, rhs: Libxml2.HTML.Node) -> Bool {
    return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
}