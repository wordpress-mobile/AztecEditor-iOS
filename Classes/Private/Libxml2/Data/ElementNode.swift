import UIKit

extension Libxml2.HTML {

    /// Element node.  Everything but text basically.
    ///
    class ElementNode: Node {

        /// This enum provides a list of HTML5 standard element names.  The reason why this isn't
        /// used as the `name` property of `ElementNode` is that element nodes could theoretically
        /// have non-standard names.
        ///
        enum StandardName: String {
            case A = "a"
            case Address = "address"
            case B = "b"
            case Blockquote = "blockquote"
            case Dd = "dd"
            case Del = "del"
            case Div = "div"
            case Dl = "dl"
            case Dt = "dt"
            case Em = "em"
            case Fieldset = "fieldset"
            case Form = "form"
            case H1 = "h1"
            case H2 = "h2"
            case H3 = "h3"
            case H4 = "h4"
            case H5 = "h5"
            case H6 = "h6"
            case Hr = "hr"
            case I = "i"
            case Li = "li"
            case Noscript = "noscript"
            case Ol = "ol"
            case P = "Paragraph"
            case Pre = "pre"
            case S = "s"
            case Strike = "strike"
            case Strong = "strong"
            case Table = "table"
            case Tbody = "tbody"
            case Td = "td"
            case Tfoot = "tfoot"
            case Th = "th"
            case Thead = "thead"
            case Tr = "tr"
            case U = "u"
            case Ul = "ul"

            /// Returns an array with all block-level elements.
            ///
            static func blockLevelNodeNames() -> [StandardName] {
                return [.Address, .Blockquote, .Div, .Dl, .Fieldset, .Form, .H1, .H2, .H3, .H4, .H5, .H6, .Hr, .Noscript, .Ol, .P, .Pre, .Table, .Ul]
            }
        }

        private(set) var attributes = [Attribute]()
        var children: [Node]

        private var standardName: StandardName? {
            get {
                return StandardName(rawValue: name)
            }
        }

        init(name: String, attributes: [Attribute], children: [Node]) {
            self.children = children
            self.attributes.appendContentsOf(attributes)

            super.init(name: name)

            for child in children {
                child.parent = self
            }
        }

        override func customMirror() -> Mirror {
            return Mirror(self, children: ["type": "element", "name": name, "parent": parent, "attributes": attributes, "children": children], ancestorRepresentation: .Suppressed)
        }

        // MARK: - Node Queries

        /// Node length.  Calculated by adding the length of all child nodes.
        ///
        override func length() -> Int {

            var length = 0

            for child in children {
                length += child.length()
            }

            return length
        }

        /// Find out if this is a block-level element.
        ///
        /// - Returns: `true` if this is a block-level element.  `false` otherwise.
        ///
        func isBlockLevelElement() -> Bool {

            guard let standardName = standardName else {
                // For now we're treating all non-standard element names as non-block-level
                // elements.
                //
                return false
            }

            return StandardName.blockLevelNodeNames().contains(standardName)
        }

        // MARK: - DOM Branch Queries

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

        /// Returns the lowest-level block-type element nodes in this node's hierarchy that wrap the 
        /// specified range.  If no child element node wraps the specified range, this method
        /// returns this node.
        ///
        /// - Parameters:
        ///     - range: the range we want to find the wrapping node of.
        ///
        /// - Returns: an array of block-level nodes, and the sub-range (from the specified range)
        ///         that they wrap.
        ///
        func lowestBlockElementNodesWrapping(range: NSRange) -> [(node: ElementNode, range: NSRange)] {
            let mainNode = lowestElementNodeWrapping(range)

            // Look for block-level elements in children
            return []
        }

        /// Calls this method to obtain all the text nodes containing a specified range.
        ///
        /// - Parameters:
        ///     - range: the range that the text nodes must cover.
        ///
        /// - Returns: an array of text nodes and a range specifying how much of the text node
        ///         makes part of the input range.  The returned range's location is an offset
        ///         from the node's location.
        ///         The array of text nodes is ordered by order of appearance (0 being the first).
        ///
        func textNodesWrapping(range: NSRange) -> [(node: TextNode, range: NSRange)] {

            var results = [(node: TextNode, range: NSRange)]()
            var offset = 0

            for child in children {

                let childRange = NSRange(location: offset, length: child.length())
                let childInterceptsRange =
                    (range.length == 0 && NSLocationInRange(range.location, childRange))
                    || NSIntersectionRange(range, childRange).length != 0

                if childInterceptsRange {
                    if let textNode = child as? TextNode {

                        var intersection = NSIntersectionRange(range, childRange)
                        intersection.location = intersection.location - offset

                        results.append((node: textNode, range: intersection))
                    } else if let elementNode = child as? ElementNode {
                        let offsetRange = NSRange(location: range.location - offset, length: range.length)

                        results.appendContentsOf(textNodesWrapping(offsetRange))
                    } else {
                        assertionFailure("This case should not be possible. Review the logic triggering this.")
                    }

                    let fullRangeCovered = range.location + range.length <= childRange.location + childRange.length

                    if fullRangeCovered {
                        break
                    }
                }

                offset = offset + child.length()
            }

            return results
        }
    }
}
