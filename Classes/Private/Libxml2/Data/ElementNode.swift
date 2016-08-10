import UIKit

extension Libxml2.HTML {

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
