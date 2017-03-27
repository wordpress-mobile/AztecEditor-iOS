extension Libxml2 {
    /// Groups all the DOM inspection & node lookup logic.
    ///
    class DOMInspector: DOMLogic {

        /// Finds the two siblings separated at the specified location.
        ///
        //// - Parameters:
        ///     - location: the location that separates the two siblings.
        ///
        /// - Returns: the two siblings, if they exist, or `nil` in any other scenario.
        ///
        func findSiblings(separatedAt location: Int) -> (leftSibling: Node, rightSibling: Node)? {
            return findSiblings(of: rootNode, separatedAt: location)
        }

        /// Finds the two siblings separated at the specified location.
        ///
        //// - Parameters:
        ///     - location: the location that separates the two siblings.
        ///
        /// - Returns: the two siblings, if they exist, or `nil` in any other scenario.
        ///
        private func findSiblings(of element: ElementNode, separatedAt location: Int) -> (leftSibling: Node, rightSibling: Node)? {

            var leftSibling: Node?
            var rightSibling: Node?
            var childStartLocation = 0

            for child in element.children {

                let childEndLocation = childStartLocation + child.length()

                // Ignore empty nodes
                //
                guard childStartLocation != childEndLocation else {
                    continue
                }

                if location == childStartLocation {
                    rightSibling = child
                    break
                } else if location == childEndLocation {
                    leftSibling = child
                } else if location > childStartLocation && location < childEndLocation {
                    guard let childElement = child as? ElementNode else {
                        return nil
                    }

                    return findSiblings(of: childElement, separatedAt: location - childStartLocation)
                }

                childStartLocation = childEndLocation
            }

            if let leftSibling = leftSibling,
                let rightSibling = rightSibling {
                return (leftSibling, rightSibling)
            } else {
                return nil
            }
        }
    }
}
