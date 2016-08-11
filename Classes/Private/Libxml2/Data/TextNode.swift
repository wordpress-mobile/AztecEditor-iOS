import Foundation

extension Libxml2.HTML {
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

        /// Node length.
        ///
        override func length() -> Int {
            return text.characters.count
        }

        /// This method returns the first parent `ElementNode` in common between the receiver and
        /// the specified input parameter.
        ///
        /// - Parameters:
        ///     - node: the algorythm will search for the parent nodes of the receiver, and this
        ///             input `TextNode`.
        ///     - interruptAtBlockLevel: whether the search should stop when a block-level
        ///             element has been found.
        ///
        /// - Returns: the parent node in common, or `nil` if none was found.
        ///
        func parentNodeInCommon(withNode node: TextNode, interruptAtBlockLevel: Bool) -> ElementNode? {
            let myParents = parentElementNodes(interruptAtBlockLevel: interruptAtBlockLevel)
            let hisParents = node.parentElementNodes(interruptAtBlockLevel: interruptAtBlockLevel)

            for currentParent in hisParents {
                if myParents.contains(currentParent) {
                    return currentParent
                }
            }

            return nil
        }
    }
}
