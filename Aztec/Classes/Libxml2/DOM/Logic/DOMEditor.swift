import Foundation

extension Libxml2 {
    
    /// Groups all the DOM editing logic.
    ///
    class DOMEditor: DOMLogic {

        typealias NodeMatchTest = (_ node: Node) -> Bool

        private let inspector: DOMInspector

        convenience override init(with rootNode: RootNode) {
            self.init(with: rootNode, using: DOMInspector(with: rootNode))
        }

        init(with rootNode: RootNode, using inspector: DOMInspector) {
            self.inspector = inspector

            super.init(with: rootNode)
        }

        // MARK: - Node Introspection

        func canWrap(node: Node, in elementDescriptor: ElementNodeDescriptor) -> Bool {

            guard let element = node as? ElementNode else {
                return true
            }

            guard !(element is RootNode) else {
                return false
            }

            let receiverIsBlockLevel = element.isBlockLevelElement()
            let newNodeIsBlockLevel = elementDescriptor.isBlockLevel()

            let canWrapReceiverInNewNode = newNodeIsBlockLevel || !receiverIsBlockLevel

            return canWrapReceiverInNewNode
        }

        // MARK: - Wrapping Nodes

        /// Force-wraps the specified range inside a node with the specified properties.
        ///
        /// - Important: When the target range matches the receiver's full range we can just wrap the receiver in the
        ///         new node.  We do need to check, however, that either:
        ///     - The new node is block-level, or
        ///     - The receiver isn't a block-level node.
        ///
        /// - Parameters:
        ///     - targetRange: the range that must be wrapped.
        ///     - elementDescriptor: the descriptor for the element to wrap the range in.
        ///
        private func forceWrap(range targetRange: NSRange, inElement elementDescriptor: ElementNodeDescriptor) {
            forceWrap(element: rootNode, range: targetRange, inElement: elementDescriptor)
        }

        /// Force-wraps the specified range inside a node with the specified properties.
        ///
        /// - Important: When the target range matches the receiver's full range we can just wrap the receiver in the
        ///         new node.  We do need to check, however, that either:
        ///     - The new node is block-level, or
        ///     - The receiver isn't a block-level node.
        ///
        /// - Parameters:
        ///     - targetRange: the range that must be wrapped.
        ///     - elementDescriptor: the descriptor for the element to wrap the range in.
        ///
        private func forceWrap(element: ElementNode, range targetRange: NSRange, inElement elementDescriptor: ElementNodeDescriptor) {

            if NSEqualRanges(targetRange, element.range())
                && canWrap(node: element, in: elementDescriptor) {
                element.wrap(in: elementDescriptor)
                return
            }

            forceWrapChildren(of: element, intersecting: targetRange, inElement: elementDescriptor)
        }

        /// Force wraps child nodes intersecting the specified range inside new elements with the
        /// specified properties.
        ///
        /// - Important: this is almost the same as
        ///         `wrapChildren(intersectingRange:, inNodeNamed:, withAttributes:)` but this
        ///         method doesn't check if the child nodes are block-level elements or not.
        ///
        /// - Parameters:
        ///     - targetRange: the range that must be wrapped.
        ///     - elementDescriptor: the descriptor for the element to wrap the range in.
        ///
        fileprivate func forceWrapChildren(of element: ElementNode, intersecting targetRange: NSRange, inElement elementDescriptor: ElementNodeDescriptor) {

            assert(element.range().contains(range: targetRange))

            let childNodesAndRanges = element.childNodes(intersectingRange: targetRange)

            guard childNodesAndRanges.count > 0 else {
                // It's possible the range may not intersect any child node, if this node is adding
                // any special characters for formatting purposes in visual mode.  For instance some
                // nodes add a newline character at their end.
                //
                return
            }

            let firstChild = childNodesAndRanges[0].child
            let firstChildIntersection = childNodesAndRanges[0].intersection

            if !NSEqualRanges(firstChild.range(), firstChildIntersection) {
                firstChild.split(forRange: firstChildIntersection)
            }

            if childNodesAndRanges.count > 1 {
                let lastChild = childNodesAndRanges[childNodesAndRanges.count - 1].child
                let lastChildIntersection = childNodesAndRanges[childNodesAndRanges.count - 1].intersection

                if !NSEqualRanges(lastChild.range(), lastChildIntersection) {
                    lastChild.split(forRange: lastChildIntersection)
                }
            }

            let children = childNodesAndRanges.map({ (child: Node, intersection: NSRange) -> Node in
                return child
            })

            element.wrap(children: children, inElement: elementDescriptor)
        }

        /// Wraps the specified range inside a node with the specified properties.
        ///
        /// - Parameters:
        ///     - element: the element containing the specified range.
        ///     - targetRange: the range that must be wrapped.
        ///     - elementDescriptor: the descriptor for the element to wrap the range in.
        ///
        func wrap(_ element: ElementNode, range targetRange: NSRange, inElement elementDescriptor: Libxml2.ElementNodeDescriptor) {

            let mustFindLowestBlockLevelElements = !elementDescriptor.isBlockLevel()

            if mustFindLowestBlockLevelElements {
                let elementsAndIntersections = element.lowestBlockLevelElements(intersectingRange: targetRange)

                for elementAndIntersection in elementsAndIntersections {

                    let element = elementAndIntersection.element
                    let intersection = elementAndIntersection.intersection

                    forceWrapChildren(of: element, intersecting: intersection, inElement: elementDescriptor)
                }
            } else {
                forceWrap(element: element, range: targetRange, inElement: elementDescriptor)
            }
        }

        /// Wraps child nodes intersecting the specified range inside new elements with the
        /// specified properties.
        ///
        /// - Parameters:
        ///     - targetRange: the range that must be wrapped.
        ///     - elementDescriptor: the descriptor for the element to wrap the range in.
        ///
        func wrapChildren(intersectingRange targetRange: NSRange, inElement elementDescriptor: ElementNodeDescriptor) {
            wrapChildren(of: rootNode, intersectingRange: targetRange, inElement: elementDescriptor)
        }

        /// Wraps child nodes intersecting the specified range inside new elements with the
        /// specified properties.
        ///
        /// - Parameters:
        ///     - element: the element containing the specified range.
        ///     - targetRange: the range that must be wrapped.
        ///     - elementDescriptor: the descriptor for the element to wrap the range in.
        ///
        func wrapChildren(of element: ElementNode, intersectingRange targetRange: NSRange, inElement elementDescriptor: ElementNodeDescriptor) {

            let matchVerification: NodeMatchTest = { return $0 is ElementNode && elementDescriptor.matchingNames.contains($0.name) }

            element.enumerateFirstDescendants(
                in: targetRange,
                matching: matchVerification,
                onMatchFound: nil,
                onMatchNotFound: { [unowned self] range in
                    let mustFindLowestBlockLevelElements = !elementDescriptor.isBlockLevel()

                    if mustFindLowestBlockLevelElements {
                        let elementsAndIntersections = element.lowestBlockLevelElements(intersectingRange: targetRange)

                        for (element, intersection) in elementsAndIntersections {
                            // 0-length intersections are possible, but they make no sense in the context
                            // of wrapping content inside new elements.  We should ignore zero-length
                            // intersections.
                            //
                            guard intersection.length > 0 else {
                                continue
                            }

                            self.forceWrapChildren(of: element, intersecting: intersection, inElement: elementDescriptor)
                        }
                    } else {
                        self.forceWrapChildren(of: element, intersecting: targetRange, inElement: elementDescriptor)
                    }
            })
        }

        // MARK: - Unwrapping Nodes

        /// Unwraps the specified range from nodes with the specified name.  If there are multiple
        /// nodes with the specified name, the range will be unwrapped from all of them.
        ///
        /// - Parameters:
        ///     - range: the range that must be unwrapped.
        ///     - elementNames: the names of the elements the range must be unwrapped from.
        ///
        /// - Todo: this method works with node names only for now.  At some point we'll want to
        ///         modify this to be able to do more complex lookups.  For instance we'll want
        ///         to be able to unwrapp CSS attributes, not just nodes by name.
        ///
        func unwrap(range: NSRange, fromElementsNamed elementNames: [String]) {
            unwrap(rootNode, range: range, fromElementsNamed: elementNames)
        }

        /// Unwraps the specified range from nodes with the specified name.  If there are multiple
        /// nodes with the specified name, the range will be unwrapped from all of them.
        ///
        /// - Parameters:
        ///     - element: the element containing the specified range.
        ///     - range: the range that must be unwrapped.
        ///     - elementNames: the names of the elements the range must be unwrapped from.
        ///
        /// - Todo: this method works with node names only for now.  At some point we'll want to
        ///         modify this to be able to do more complex lookups.  For instance we'll want
        ///         to be able to unwrapp CSS attributes, not just nodes by name.
        ///
        func unwrap(_ element: ElementNode, range: NSRange, fromElementsNamed elementNames: [String]) {

            guard element.children.count > 0 else {
                return
            }

            unwrapChildren(of: element, intersecting: range, fromElementsNamed: elementNames)

            if elementNames.contains(element.name) {

                let rangeEndLocation = range.location + range.length

                let myLength = element.length()
                assert(range.location >= 0 && rangeEndLocation <= myLength,
                       "The specified range is out of bounds.")

                let elementDescriptor = ElementNodeDescriptor(name: element.name, attributes: element.attributes)

                if range.location > 0 {
                    let preRange = NSRange(location: 0, length: range.location)
                    wrap(element, range: preRange, inElement: elementDescriptor)
                }

                if rangeEndLocation < myLength {
                    let postRange = NSRange(location: rangeEndLocation, length: myLength - rangeEndLocation)
                    wrap(element, range: postRange, inElement: elementDescriptor)
                }
                
                element.unwrapChildren()
            }
        }

        /// Unwraps all child nodes from elements with the specified names.
        ///
        /// - Parameters:
        ///     - element: the element containing the specified range.
        ///     - range: the range we want to unwrap.
        ///     - elementNames: the name of the elements we want to unwrap the nodes from.
        ///
        func unwrapChildren(of element: ElementNode, intersecting range: NSRange, fromElementsNamed elementNames: [String]) {
            if element.isBlockLevelElement() && element.text().isLastValidLocation(range.location) {
                return
            }

            let childNodesAndRanges = element.childNodes(intersectingRange: range)
            assert(childNodesAndRanges.count > 0)

            for (child, range) in childNodesAndRanges {
                guard let childElement = child as? ElementNode else {
                    continue
                }

                unwrap(childElement, range: range, fromElementsNamed: elementNames)
            }
        }

        // MARK: - Splitting Nodes

        func splitLowestBlockLevelElement(at location: Int) {

            let range = NSRange(location: location, length: 0)
            let elementsAndIntersections = rootNode.lowestBlockLevelElements(intersectingRange: range)

            guard let elementAndIntersection = elementsAndIntersections.first else {
                // If there's no block-level element to break, we simply add a line separator
                //
                rootNode.replaceCharacters(inRange: range, withString: String(.lineSeparator))
                return
            }

            let elementToSplit = elementAndIntersection.element
            let intersection = elementAndIntersection.intersection

            elementToSplit.split(atLocation: intersection.location)
        }

        // MARK: - Merging Nodes

        /// Merges the siblings found separated at the specified location.  Since the DOM is a tree
        /// only two siblings can match this separator.
        ///
        /// - Note: Block-level elements are rendered on their own line, meaning a newline is added
        ///         even though it's not part of the contents of any node.  This method implements
        ///         the logic that's executed when such visual-only newline is removed.
        ///
        /// - Parameters:
        ///     - location: the location that separates the siblings we're looking for.
        ///
        func mergeBlockLevelElementRight(endingAt location: Int) {
            guard let node = inspector.findNode(endingAt: location) else {
                return
            }

            mergeRight(node)
        }

        /// Merges the specified block-level element with the sibling(s) to its right.
        ///
        /// - Note: Block-level elements are rendered on their own line, meaning a newline is added
        ///         even though it's not part of the contents of any node.  This method implements
        ///         the logic that's executed when such visual-only newline is removed.
        ///
        /// - Parameters:
        ///     - node: the node we're merging to the right.
        ///
        private func mergeRight(_ node: Node) {
            let rightNodes = extractRightNodesForMerging(after: node)

            merge(node, withRightNodes: rightNodes)
        }

        private func merge(_ node: Node, withRightNodes rightNodes: [Node]) {

            guard let element = node as? ElementNode else {
                guard let parent = node.parent else {
                    fatalError("This method should not be called for a node without a parent set.")
                }

                let insertionIndex = parent.indexOf(childNode: node) + 1

                for (index, child) in rightNodes.enumerated() {
                    parent.insert(child, at: insertionIndex + index)
                }

                return
            }

            if element.children.count > 0,
                let lastChildElement = element.children[element.children.count - 1] as? ElementNode,
                lastChildElement.isBlockLevelElement() {

                merge(lastChildElement, withRightNodes: rightNodes)
                return
            }

            if element.standardName == .ul || element.standardName == .ol {
                let newListItem = ElementNode(name: StandardElementType.li.rawValue, attributes: [], children: rightNodes)
                element.append(newListItem)
                return
            }
            
            element.append(rightNodes)
        }

        private func extractRightNodesForMerging(after node: Node) -> [Node] {
            guard let parent = node.parent else {
                fatalError("Expected to have a parent node here.")
            }

            let nodeIndex = parent.indexOf(childNode: node)

            return extractNodesForMerging(from: parent, startingAt: nodeIndex + 1)
        }

        private func extractNodesForMerging(from parent: ElementNode, startingAt index: Int) -> [Node] {

            guard index < parent.children.count else {
                return []
            }

            var nodes = [Node]()

            var currentNode = parent.children[index]

            while true {
                let nextNodeOptional = inspector.rightSibling(of: currentNode)

                if let element = currentNode as? ElementNode {
                    if element.isBlockLevelElement() {
                        if nodes.count == 0 {
                            nodes = extractNodesForMerging(from: element, startingAt: 0)
                        }

                        break
                    } else if element.standardName == .br  {
                        element.removeFromParent()
                        break
                    }
                }

                currentNode.removeFromParent()
                nodes.append(currentNode)

                guard let nextNode = nextNodeOptional else {
                    break
                }

                currentNode = nextNode
            }

            if parent.children.count == 0 {
                parent.removeFromParent()
            }
            
            return nodes
        }
    }
}
