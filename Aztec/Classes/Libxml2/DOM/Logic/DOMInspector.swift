extension Libxml2 {
    /// Groups all the DOM inspection & node lookup logic.
    ///
    class DOMInspector: DOMLogic {

        // MARK: - Parent

        /// Call this method whenever you node the specified node MUST have a parent set.
        /// This method will interrupt program execution if a parent isn't set.
        ///
        /// - Parameters:
        ///     - node: the node you want to get the parent of.
        ///
        /// - Returns: the parent element.
        ///
        func parent(of node: Node) -> ElementNode {
            guard let parent = node.parent else {
                fatalError("This method should only be called whenever you are sure a parent is set.")
            }

            return parent
        }

        // MARK: - Siblings

        func rightSibling(of node: Node) -> Node? {
            guard let parent = node.parent else {
                assertionFailure("Shouldn't call this method in a node without a parent.")
                return nil
            }

            let nextIndex = parent.indexOf(childNode: node) + 1

            guard parent.children.count > nextIndex else {
                return nil
            }

            return parent.children[nextIndex]
        }

        // MARK: - Finding nodes

        /// Finds a node ending at the specified location.
        ///
        //// - Parameters:
        ///     - location: the location where the node is supposed to end.
        ///
        /// - Returns: the node that ends at the specified location.
        ///
        func findNode(endingAt location: Int) -> Node? {
            return findDescendant(of: rootNode, endingAt: location)
        }

        /// Finds the descendant of the specified node, ending at the specified location.
        ///
        //// - Parameters:
        ///     - startingElement: the node to search the descendant of.
        ///     - location: the location where the descendant ends.
        ///
        /// - Returns: the node that ends at the specified location.
        ///
        private func findDescendant(of startingElement: ElementNode, endingAt location: Int) -> Node? {
            
            var childStartLocation = 0

            for child in startingElement.children {

                let childEndLocation = childStartLocation + child.length()

                // Ignore empty nodes
                //
                guard childStartLocation != childEndLocation else {
                    continue
                }

                if location == childEndLocation {
                    return child
                } else if location > childStartLocation && location < childEndLocation {
                    guard let childElement = child as? ElementNode else {
                        return nil
                    }

                    return findDescendant(of: childElement, endingAt: location - childStartLocation)
                }

                childStartLocation = childEndLocation
            }

            return nil
        }
    }
}
