import Foundation

extension Libxml2 {

    /// Base class for all node types.
    ///
    class Node: Equatable, CustomReflectable, Hashable {
        
        let name: String
        
        // MARK: - Properties: Parent reference
        
        /// A weak reference to the parent of this node.
        ///
        private weak var rawParent: ElementNode? = nil
        
        /// Parent-node-reference setter and getter, with undo support.
        ///
        var parent: ElementNode?

        // MARK: - Properties: Editing traits

        var canEditTextRepresentation: Bool = true
        
        // MARK: - CustomReflectable
        
        public var customMirror: Mirror {
            get {
                return Mirror(self, children: ["name": name, "parent": parent as Any])
            }
        }


        // MARK - Hashable

        public var hashValue: Int {
            return name.hashValue
        }

        // MARK: - Initializers

        init(name: String) {
            self.name = name
        }

        // MARK: - DOM Queries

        func isLastIn(blockLevelElement element: ElementNode) -> Bool {
            return element.isBlockLevelElement() && element.children.last == self
        }

        /// Checks if the receiver is the last node in its parent.
        /// Empty text nodes are filtered to avoid false positives.
        ///
        func isLastInParent() -> Bool {

            guard let parent = parent else {
                return true
            }

            // We are filtering empty text nodes from being considered the last node in our
            // parent node.
            //
            let lastMatchingChildInParent = parent.lastChild(matching: { node -> Bool in
                guard let textNode = node as? TextNode,
                    textNode.length() == 0 else {
                        return true
                }

                return false
            })

            return self === lastMatchingChildInParent
        }

        /// Checks if the receiver is the last node in the tree.
        ///
        /// - Note: The verification excludes all child nodes, since this method only cares about
        ///     siblings and parents in the tree.
        ///
        func isLastInTree() -> Bool {

            guard let parent = parent else {
                return true
            }

            return isLastInParent() && parent.isLastInTree()
        }

        /// Checks if the receiver is the last node in a block-level ancestor.
        ///
        /// - Note: The verification excludes all child nodes, since this method only cares about
        ///     siblings and parents in the tree.
        ///
        func isLastInBlockLevelAncestor() -> Bool {

            guard let parent = parent else {
                return false
            }

            return isLastInParent() &&
                (parent.isBlockLevelElement() || parent.isLastInBlockLevelAncestor())
        }

        func hasRightBlockLevelSibling() -> Bool {
            if let rightSibling = rightSibling() as? ElementNode, rightSibling.isBlockLevelElement() {
                return true
            } else {
                return false
            }
        }

        func isLastInAncestorEndingInBlockLevelSeparation() -> Bool {
            guard let parent = parent else {
                return false
            }

            return parent.children.last == self
                && (parent.isBlockLevelElement()
                    || parent.hasRightBlockLevelSibling()
                    || parent.isLastInAncestorEndingInBlockLevelSeparation())
        }

        /// Retrieves the right sibling for a node.
        ///
        /// - Returns: the right sibling, or `nil` if none exists.
        ///
        func rightSibling() -> Node? {

            guard let parent = parent else {
                return nil
            }

            let index = parent.indexOf(childNode: self)

            return parent.sibling(rightOf: index)
        }

        // MARK: - DOM Modification

        /// Removes this node from its parent, if it has one.
        ///
        func removeFromParent() {
            parent?.remove(self)
        }
    }
}

// MARK: - Node Equatable

func ==(lhs: Libxml2.Node, rhs: Libxml2.Node) -> Bool {
    return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
}
