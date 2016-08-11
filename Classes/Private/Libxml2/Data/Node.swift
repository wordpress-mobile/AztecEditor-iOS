extension Libxml2.HTML {

    /// Base class for all node types.
    ///
    class Node: Equatable, CustomReflectable {

        let name: String
        weak var parent: ElementNode?

        func customMirror() -> Mirror {
            return Mirror(self, children: ["name": name, "parent": parent])
        }

        init(name: String) {
            self.name = name
        }

        /// Override.
        ///
        func length() -> Int {
            assertionFailure("This method should always be overridden.")
            return 0
        }

        /// Retrieve all parent nodes for a specified node.
        ///
        /// - Parameters:
        ///     - interruptAtBlockLevel: whether the method should interrupt if it finds a
        ///             block-level element.
        ///
        /// - Returns: an ordered array of parent nodes.  Element zero is the closest parent node.
        ///
        func parentElementNodes(interruptAtBlockLevel interruptAtBlockLevel: Bool = false) -> [ElementNode] {
            var parentNodes = [ElementNode]()
            var currentNode = self.parent

            while let node = currentNode {
                parentNodes.append(node)

                if interruptAtBlockLevel && node.isBlockLevelElement() {
                    break
                }

                currentNode = node.parent
            }

            return parentNodes
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
        func parentNodeInCommon(withNode node: Node, interruptAtBlockLevel: Bool = false) -> ElementNode? {
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

// MARK: - Node Equatable

func ==(lhs: Libxml2.HTML.Node, rhs: Libxml2.HTML.Node) -> Bool {
    return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
}