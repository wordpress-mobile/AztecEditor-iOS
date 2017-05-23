import Foundation

extension Libxml2 {

    /// Base class for all node types.
    ///
    class Node: Equatable, CustomReflectable {
        
        let name: String
        
        // MARK: - Properties: Parent reference
        
        /// A weak reference to the parent of this node.
        ///
        private weak var rawParent: ElementNode? = nil
        
        /// Parent-node-reference setter and getter, with undo support.
        ///
        var parent: ElementNode? {
            get {
                return rawParent
            }
            
            set {
                registerUndoForParentChange()
                rawParent = newValue
            }
        }

        // MARK: - Properties: Editing traits

        var canEditTextRepresentation: Bool = true
        
        // MARK: - CustomReflectable
        
        public var customMirror: Mirror {
            get {
                return Mirror(self, children: ["name": name, "parent": parent as Any])
            }
        }
        
        // MARK: - Initializers

        init(name: String) {
            self.name = name
        }

        func range() -> NSRange {
            return NSRange(location: 0, length: length())
        }

        // MARK: - Override in Subclasses

        /// Override.
        ///
        func length() -> Int {
            assertionFailure("This method should always be overridden.")
            return 0
        }
        
        /// Override.
        ///
        func text() -> String {
            assertionFailure("This method should always be overridden.")
            return ""
        }

        /// Finds the absolute location of a node inside a tree.
        func absoluteLocation() -> Int {
            var currentParent = self.parent
            var currentNode = self
            var absoluteLocation = 0
            while currentParent != nil {
                let certainParent = currentParent!
                for child in certainParent.children {
                    if child !== currentNode {
                        absoluteLocation += child.length()
                    } else {
                        currentNode = certainParent
                        currentParent = certainParent.parent
                        break
                    }
                }
            }
            return absoluteLocation
        }

        // MARK: - DOM Queries

/*
        /// Retrieves the right sibling for a node.
        ///
        /// - Returns: the right sibling, or `nil` if none exists.
        ///
        func rightSibling() -> ElementNode? {

            guard let parent = parent else {
                return nil
            }

            let index = parent.indexOf(childNode: self)

            guard let sibling = parent.sibling(rightOf: index) else {
                return nil
            }

            return sibling as? ElementNode
        }*/

        // MARK: - Paragraph Separation Logic
/*
        /// Checks if the specified node requires a closing paragraph separator.
        ///
        func needsClosingParagraphSeparator() -> Bool {

            if let rightSibling = rightSibling(),
                rightSibling.isBlockLevelElement() {

                return true
            }

            return !isLastInTree() && isLastInBlockLevelAncestor()
        }
*/
        // MARK: - DOM Modification

        /*
        /// Wraps this node in a new node with the specified name.  Also takes care of updating
        /// the parent and child node references.
        ///
        /// - Parameters:
        ///     - elementDescriptor: the descriptor for the element to wrap the receiver in.
        ///
        /// - Returns: the newly created element.
        ///
        @discardableResult
        func wrap(in elementDescriptor: ElementNodeDescriptor) -> ElementNode {

            let originalParent = parent
            let originalIndex = parent?.children.index(of: self)

            let newNode = ElementNode(descriptor: elementDescriptor)

            if let parent = originalParent {
                guard let index = originalIndex else {
                    fatalError("If the node has a parent, the index should be obtainable.")
                }

                parent.insert(newNode, at: index)
            }

            return newNode
        }
 */
        
        // MARK: - Undo support
        
        /// Registers an undo operation for an upcoming parent property change.
        ///
        private func registerUndoForParentChange() {
            /*
            let originalParent = rawParent

            SharedEditor.currentEditor?.undoManager.registerUndo(withTarget: self) { target in
                target.parent = originalParent
            }
 */
        }
    }
}

// MARK: - Node Equatable

func ==(lhs: Libxml2.Node, rhs: Libxml2.Node) -> Bool {
    return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
}
