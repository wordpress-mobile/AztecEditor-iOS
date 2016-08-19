extension Libxml2 {

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

        /// Retrieve all element nodes between the receiver and the root node.
        /// The root node is included in the results.  The receiver is only included if it's an
        /// element node.
        ///
        /// - Parameters:
        ///     - interruptAtBlockLevel: whether the method should interrupt if it finds a
        ///             block-level element.
        ///
        /// - Returns: an ordered array of nodes.  Element zero is the receiver if it's an element
        ///         node, otherwise its the receiver's parent node.  The last element is the root
        ///         node.
        ///
        func elementNodesToRoot(interruptAtBlockLevel interruptAtBlockLevel: Bool = false) -> [ElementNode] {
            var nodes = [ElementNode]()
            var currentNode = self.parent

            if let elementNode = self as? ElementNode {
                nodes.append(elementNode)
            }

            while let node = currentNode {
                nodes.append(node)

                if interruptAtBlockLevel && node.isBlockLevelElement() {
                    break
                }

                currentNode = node.parent
            }

            return nodes
        }

        /// This method returns the first `ElementNode` in common between the receiver and
        /// the specified input parameter, going up both branches.
        ///
        /// - Parameters:
        ///     - node: the algorythm will search for the parent nodes of the receiver, and this
        ///             input `TextNode`.
        ///     - interruptAtBlockLevel: whether the search should stop when a block-level
        ///             element has been found.
        ///
        /// - Returns: the first element node in common, or `nil` if none was found.
        ///
        func firstElementNodeInCommon(withNode node: Node, interruptAtBlockLevel: Bool = false) -> ElementNode? {
            let myParents = elementNodesToRoot(interruptAtBlockLevel: interruptAtBlockLevel)
            let hisParents = node.elementNodesToRoot(interruptAtBlockLevel: interruptAtBlockLevel)

            for currentParent in hisParents {
                if myParents.contains(currentParent) {
                    return currentParent
                }
            }

            return nil
        }

        /// Wraps this node in a new node with the specified name.  Also takes care of updating
        /// the parent and child node references.
        ///
        /// - Parameters:
        ///     - name: the new node name.
        ///     - attributes: the new node attributes.
        ///
        /// - Returns: the newly created element.
        ///
        func wrapInNewNode(named name: String, attributes: [Attribute] = []) -> ElementNode {

            let originalParent = parent

            let newNode = ElementNode(name: name, attributes: attributes, children: [self])

            if let parent = originalParent {
                guard let index = parent.children.indexOf(self) else {
                    assertionFailure("A node's parent should contain the node. Review the child/parent updating logic.")
                    return newNode
                }

                parent.children[index] = newNode
                newNode.parent = parent
            }

            return newNode
        }
    }
}

// MARK: - Node Equatable

func ==(lhs: Libxml2.Node, rhs: Libxml2.Node) -> Bool {
    return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
}