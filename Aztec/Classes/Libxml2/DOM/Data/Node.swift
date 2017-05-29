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
