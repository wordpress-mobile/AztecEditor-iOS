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
        
        // MARK: - Properties: Edit Context
        
        let editContext: EditContext?
        
        // MARK: - CustomReflectable
        
        public var customMirror: Mirror {
            get {
                return Mirror(self, children: ["name": name, "parent": parent as Any])
            }
        }
        
        // MARK: - Initializers

        init(name: String, editContext: EditContext? = nil) {
            self.name = name
            self.editContext = editContext
        }

        func range() -> NSRange {
            return NSRange(location: 0, length: length())
        }

        // MARK: - Override in Subclasses

        func canHaveChildren() -> Bool {
            return false
        }

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
        func elementNodesToRoot(interruptAtBlockLevel: Bool = false) -> [ElementNode] {
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

        func isLastIn(blockLevelElement element: ElementNode) -> Bool {
            return element.isBlockLevelElement() && element.children.last == self
        }

        func isLastInBlockLevelElement() -> Bool {
            guard let parent = parent else {
                return false
            }

            guard !isLastIn(blockLevelElement: parent) else {
                return true
            }

            let index = parent.indexOf(childNode: self)

            if let sibling = parent.sibling(rightOf: index) {
                if let siblingElement = sibling as? ElementNode {
                    return siblingElement.isBlockLevelElement()
                } else {
                    return sibling.isLastInBlockLevelElement()
                }
            } else {
                return parent.isLastInBlockLevelElement()
            }
        }

        // MARK: - DOM Modification

        /// Removes this node from its parent, if it has one.
        ///
        func removeFromParent() {
            parent?.remove(self)
        }
        
        /// Wraps this node in a new node with the specified name.  Also takes care of updating
        /// the parent and child node references.
        ///
        /// - Parameters:
        ///     - elementDescriptor: the descriptor for the element to wrap the receiver in.
        ///
        /// - Returns: the newly created element.
        ///
        @discardableResult
        func wrap(inElement elementDescriptor: ElementNodeDescriptor) -> ElementNode {

            let originalParent = parent
            let originalIndex = parent?.children.index(of: self)

            let newNode = ElementNode(descriptor: elementDescriptor, editContext: editContext)

            if let parent = originalParent {
                guard let index = originalIndex else {
                    fatalError("If the node has a parent, the index should be obtainable.")
                }

                parent.insert(newNode, at: index)
            }

            return newNode
        }
        
        // MARK: - Undo support
        
        /// Registers an undo operation for an upcoming parent property change.
        ///
        private func registerUndoForParentChange() {
            
            guard let editContext = editContext else {
                return
            }
            
            let originalParent = rawParent
            
            editContext.undoManager.registerUndo(withTarget: self) { target in
                target.parent = originalParent
            }
        }
    }
}

// MARK: - Node Equatable

func ==(lhs: Libxml2.Node, rhs: Libxml2.Node) -> Bool {
    return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
}
