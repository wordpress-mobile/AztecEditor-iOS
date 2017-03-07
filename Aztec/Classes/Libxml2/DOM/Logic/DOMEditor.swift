extension Libxml2 {
    
    /// Groups all the DOM editing logic.
    ///
    class DOMEditor: DOMLogic {

        let inspector: DOMInspector

        override init(with rootNode: RootNode) {
            inspector = DOMInspector(with: rootNode)

            super.init(with: rootNode)
        }

        /// Merges the siblings found separated at the specified location.  Since the DOM is a tree
        /// only two siblings can match this separator.
        ///
        /// - Parameters:
        ///     - location: the location that separates the siblings we're looking for.
        ///
        func mergeNodes(separatedAt location: Int) {
            guard let theSiblings = inspector.findSiblings(separatedAt: location) else {
                return
            }

            mergeSiblings(leftSibling: theSiblings.leftSibling, rightSibling: theSiblings.rightSibling)
        }

        /// Merges the siblings found separated at the specified location.  Since the DOM is a tree
        /// only two siblings can match this separator.
        ///
        /// - Parameters:
        ///     - leftSibling: the left sibling to merge.
        ///     - rightSibling: the right sibling to merge.
        ///
        func mergeSiblings(leftSibling: Node, rightSibling: Node) {
            let finalRightNodes: [Node]

            if let rightElement = rightSibling as? ElementNode,
                rightElement.isBlockLevelElement() {

                finalRightNodes = rightElement.unwrapChildren()
            } else {
                finalRightNodes = [rightSibling]
            }

            if let leftElement = leftSibling as? ElementNode,
                leftElement.isBlockLevelElement() {
                
                leftElement.append(finalRightNodes)
            }
        }
    }
}
