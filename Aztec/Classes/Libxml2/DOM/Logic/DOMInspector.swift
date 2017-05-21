import Foundation

extension Libxml2 {
    /// Groups all the DOM inspection & node lookup logic.
    ///
    class DOMInspector: DOMLogic {

        private typealias Test = (_ node: Node, _ startLocation: Int, _ endLocation: Int) -> TestResult

        /// Used as a result type for searching the DOM tree.
        ///
        private enum TestResult {

            /// The test didn't succeed.
            ///
            case failure

            /// The test was successful for this node.
            ///
            case success

            /// One or more descendants of the provided element fulfill the condition
            ///
            case descendant(element: ElementNode)
        }

        private typealias MatchTest = (_ node: Node, _ startLocation: Int, _ endLocation: Int) -> MatchType

        /// Used as a result type for searching the DOM tree.
        ///
        private enum MatchType {

            /// No match.
            ///
            case noMatch

            /// The reference node is a match.
            ///
            case match

            /// One of the descendants of the reference element is a match.
            ///
            case descendant(element: ElementNode)
        }

        typealias ElementAndIntersection = (element: ElementNode, intersection: NSRange)
        typealias ElementAndOffset = (element: ElementNode, offset: Int)

        typealias NodeAndIntersection = (node: Node, intersection: NSRange)
        typealias NodeAndOffset = (node: Node, offset: Int)
        
        private typealias EnumerationStep = (_ node: Node, _ startLocation: Int, _ endLocation: Int) -> NextStep

        /// An enum used for enumerating through a DOM tree.  Defines how enumeration continues
        /// after the reference step.
        ///
        private enum NextStep {

            /// Stop enumerating
            ///
            case stop

            /// Continue enumerating siblings from left to right.  Exits if no other sibling is
            /// found.
            ///
            case continueWithSiblings

            /// Enumerate the children of the reference element (from left to right).
            ///
            case continueWithChildren(element: ElementNode)
        }

        // MARK: - Parent & Siblings

        /// Retrieves the right sibling of a specified node.
        ///
        /// - Parameters:
        ///     - node: the reference node to find the right sibling of.
        ///
        /// - Returns: the right sibling, or `nil` if there's none.
        ///
        func leftSibling(of node: Node) -> Node? {

            let parent = self.parent(of: node)
            let nextIndex = parent.indexOf(childNode: node) - 1

            guard nextIndex > 0 else {
                return nil
            }

            return parent.children[nextIndex]
        }

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

        /// Retrieves the right sibling of a specified node.
        ///
        /// - Parameters:
        ///     - node: the reference node to find the right sibling of.
        ///
        /// - Returns: the right sibling, or `nil` if there's none.
        ///
        func rightSibling(of node: Node) -> Node? {

            let parent = self.parent(of: node)
            let nextIndex = parent.indexOf(childNode: node) + 1

            guard parent.children.count > nextIndex else {
                return nil
            }

            return parent.children[nextIndex]
        }

        // MARK: - Node Introspection

        func isEmptyTextNode(_ node: Node) -> Bool {
            return node is TextNode && node.length() == 0
        }

        // MARK: - Finding Nodes

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

        // MARK: - Finding Nodes: Children

        /// Finds the lowest block-level elements spanning the specified range.
        ///
        //// - Parameters:
        ///     - startingElement: the head node of the subtree for the search.
        ///     - range: the range that must be contained by the element.
        ///     - blockLevelOnly: flag to specify if the requested element has to be a block-level
        ///             element.
        ///
        /// - Returns: a pair containing the matching element (or `startingElement`, if no better
        ///         match is found) and the input location relative in the returned element's
        ///         coordinates.
        ///
        func findChildren(
            of element: ElementNode,
            spanning range: NSRange) -> [NodeAndIntersection] {

            assert(element.range().contains(range))

            guard element.children.count > 0 else {
                return [(element, range)]
            }

            var elementsAndRanges = [NodeAndIntersection]()
            var offset = 0

            for child in element.children {

                defer {
                    offset = offset + child.length()
                }

                let childRangeInParent = child.range().offset(offset)

                guard let intersectionInParent = range.intersect(withRange: childRangeInParent) else {
                    continue
                }

                elementsAndRanges.append((child, intersectionInParent.offset(-offset)))
            }
            
            return elementsAndRanges
        }

        /// Finds the leftmost child intersecting the specified location.
        ///
        //// - Parameters:
        ///     - element: the element to find the child of.
        ///     - location: the location the child node should intersect
        ///
        /// - Returns: The leftmost child intersecting the specified location, or
        ///         `nil` if no intersection is found.
        ///
        func findLeftmostChild(
            of element: ElementNode,
            intersecting offset: Int) -> NodeAndOffset? {

            guard element.children.count > 0 else {
                return nil
            }

            var childOffset = 0

            for child in element.children {

                let childRangeInParent = child.range().offset(childOffset)

                if childRangeInParent.contains(offset: offset) {
                    return (node: child, offset: offset - childOffset)
                }

                childOffset = childOffset + child.length()
            }
            
            return nil
        }

        // MARK: - Finding Nodes: Descendants

        /// Finds the leftmost and lowest element intersecting the specified location.
        ///
        func findLeftmostLowestDescendantElement(intersecting location: Int) -> ElementAndOffset {
            return findLeftmostLowestDescendantElement(of: rootNode, intersecting: location)
        }

        /// Finds the lowest block-level elements spanning the specified range.
        ///
        //// - Parameters:
        ///     - startingElement: the head node of the subtree for the search.
        ///     - range: the range that must be contained by the element.
        ///     - blockLevelOnly: flag to specify if the requested element has to be a block-level
        ///             element.
        ///
        /// - Returns: a pair containing the matching element (or `startingElement`, if no better
        ///         match is found) and the input location relative in the returned element's
        ///         coordinates.
        ///
        func findLowestBlockElementDescendants(
            of element: ElementNode,
            spanning range: NSRange,
            bailCheck: (Node) -> Bool = { _ in return false }) -> [ElementAndIntersection] {

            assert(element.range().contains(range))

            guard element.children.count > 0 else {
                return [(element, range)]
            }

            var elementsAndRanges = [ElementAndIntersection]()
            var offset = 0

            for child in element.children {

                defer {
                    offset = offset + child.length()
                }

                guard !bailCheck(child) else {
                    continue
                }

                let childRangeInParent = child.range().offset(offset)
                
                guard let intersection = range.intersect(withRange: childRangeInParent) else {
                    continue
                }

                guard let childElement = child as? ElementNode,
                    childElement.isBlockLevelElement() else {
                        elementsAndRanges.append((element, intersection))
                        continue
                }

                let childElementsAndRanges = findLowestBlockElementDescendants(of: childElement, spanning: intersection.offset(-offset))

                for (matchElement, matchIntersection) in childElementsAndRanges {
                    elementsAndRanges.append((matchElement, matchIntersection))
                }
            }

            return elementsAndRanges
        }

        /// Finds the leftmost, lowest descendant element of the refrence element, intersecting a
        /// reference location.
        ///
        //// - Parameters:
        ///     - startingElement: the head node of the subtree for the search.
        ///     - location: the reference location for the search logic.
        ///     - blockLevel: flag to specify if the requested element should be a block-level element.
        ///
        /// - Returns: a pair containing the matching element (or `startingElement`, if no better
        ///         match is found) and the input location relative in the returned element's
        ///         coordinates.
        ///
        func findLeftmostLowestDescendantElement(
            of startingElement: ElementNode,
            intersecting location: Int,
            blockLevel: Bool = false) -> ElementAndOffset {

            var result = (startingElement, location)

            navigateDescendants(of: startingElement) { (node, startLocation, endLocation) -> NextStep in

                guard startLocation <= location else {
                    return .stop
                }

                guard location <= endLocation && !isEmptyTextNode(node),
                    let element = node as? ElementNode,
                    blockLevel || element.isBlockLevelElement() else {

                        return .continueWithSiblings
                }

                let relativeLocation = location - startLocation

                // The current element matches our search.  It may be necessary to go through the
                // child nodes, but for the time being its our best candidate.
                //
                result = (element, relativeLocation)

                if element.children.count > 0 {
                    return .continueWithChildren(element: element)
                } else {
                    return .stop
                }
            }

            return result
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

            return firstDescendant(of: startingElement, matching: { (node, startLocation, endLocation) -> MatchType in
                // Ignore empty nodes
                //
                guard startLocation != endLocation else {
                    return .noMatch
                }

                if endLocation == location {
                    return .match
                } else if startLocation < location && location < endLocation,
                    let element = node as? ElementNode {

                    return .descendant(element: element)
                }

                return .noMatch
            })
        }

        func find(_ text: String, in node: Node) -> [NSRange] {
            if let element = node as? ElementNode {
                return find(text, in: element)
            } else if let textNode = node as? TextNode {
                return find(text, in: textNode)
            } else if node is CommentNode {
                return []
            } else {
                assertionFailure("Unsupported node type.")
                return []
            }
        }

        func find(_ text: String, in element: ElementNode) -> [NSRange] {

            var childOffset = 0
            var ranges = [NSRange]()

            for child in element.children {
                let rangesInChildCoordinates = find(text, in: child)

                let childRanges = rangesInChildCoordinates.map({ range -> NSRange in
                    return range.offset(childOffset)
                })

                ranges.append(contentsOf: childRanges)

                childOffset += child.length()
            }

            return ranges
        }

        func find(_ text: String, in textNode: TextNode) -> [NSRange] {
            var ranges = [NSRange]()
            let nodeText = textNode.text()

            var currentRange = nodeText.startIndex ..< nodeText.endIndex

            while let range = nodeText.range(of: text, options: [], range: currentRange, locale: nil) {

                currentRange = range.upperBound ..< currentRange.upperBound

                let location = nodeText.distance(from: nodeText.startIndex, to: range.lowerBound)
                let length = nodeText.distance(from: range.lowerBound, to: range.upperBound)
                let range = NSRange(location: location, length: length)

                ranges.append(range)
            }

            return ranges
        }

        // MARK: - Finding Nodes: Siblings

        /// Finds all the left siblings of the specified node.
        ///
        /// - Parameters:
        ///     - node: the reference node.
        ///     - includeReferenceNode: whether the reference node must be included in the results.
        ///
        /// - Returns: the left siblings of the reference node.
        ///
        func findLeftSiblings(of node: Node, includingReferenceNode includeReferenceNode: Bool = false) -> [Node] {

            let parent = self.parent(of: node)
            let referenceIndex = parent.indexOf(childNode: node)

            if includeReferenceNode {
                return [Node](parent.children.prefix(through: referenceIndex))
            } else {
                return [Node](parent.children.prefix(upTo: referenceIndex))
            }
        }

        /// Finds all the right siblings of the specified node.
        ///
        /// - Parameters:
        ///     - node: the reference node.
        ///     - includeReferenceNode: whether the reference node must be included in the results.
        ///
        /// - Returns: the right siblings of the reference node.
        ///
        func findRightSiblings(of node: Node, includingReferenceNode includeReferenceNode: Bool = false) -> [Node] {

            let parent = self.parent(of: node)
            let referenceIndex = parent.indexOf(childNode: node)

            if includeReferenceNode {
                return [Node](parent.children.suffix(from: referenceIndex))
            } else {
                return [Node](parent.children.suffix(from: referenceIndex + 1))
            }
        }

        // MARK: - Finding Nodes: Core Methods

        /// Navigates the descendants of a provided element.
        ///
        /// - Parameters:
        ///     - startingElement: the reference element for the enumeration.  The enumeration step
        ///             is not executed for this node.
        ///     - step: the enumeration step, returning an indication of how the enumeration will
        ///             continue, or if it needs to be interrupted.
        ///
        private func navigateDescendants(of startingElement: ElementNode, withStep step: EnumerationStep) {

            var childStartLocation = 0

            for child in startingElement.children {

                let childEndLocation = childStartLocation + child.length()

                let nextStep = step(child, childStartLocation, childEndLocation)

                switch nextStep {
                case .stop:
                    return
                case let .continueWithChildren(element):
                    navigateDescendants(of: element, withStep: { (descendant, descendantChildStartLocation, descendantChildEndLocation) in
                        let absoluteStartLocation = descendantChildStartLocation + childStartLocation
                        let absoluteEndLocation = descendantChildEndLocation + childStartLocation

                        return step(descendant, absoluteStartLocation, absoluteEndLocation)
                    })
                case .continueWithSiblings:
                    childStartLocation = childEndLocation
                }
            }
        }

        /// Finds the first descendant of the specified element, matching the provided test.
        ///
        /// - Note: search order is left-to-right, top-to-bottom.
        ///
        /// - Parameters:
        ///     - startingElement: the reference element for the lookup.  Excluded from the search.
        ///     - test: the search test condition.
        ///
        /// - Returns: the requested descendant.
        ///
        private func firstDescendant(of startingElement: ElementNode, matching test: MatchTest) -> Node? {

            var childStartLocation = 0

            for child in startingElement.children {

                let childEndLocation = childStartLocation + child.length()

                let matchType = test(child, childStartLocation, childEndLocation)

                switch matchType {
                case .match:
                    return child
                case let .descendant(element):
                    return firstDescendant(of: element, matching: { (descendant, grandChildStartLocation, grandChildEndLocation) -> MatchType in
                        let absoluteStartLocation = grandChildStartLocation + childStartLocation
                        let absoluteEndLocation = grandChildEndLocation + childStartLocation

                        return test(descendant, absoluteStartLocation, absoluteEndLocation)
                    })
                default:
                    childStartLocation = childEndLocation
                }
            }
            
            return nil
        }

        // MARK: - Range Mapping to Children

        /// Maps the specified range to the child nodes.
        ///
        func mapToChildren(range: NSRange, of element: ElementNode) -> NSRange {

            assert(range.length > 0)

            guard element.isBlockLevelElement() && range.location + range.length == element.length() else {
                return range
            }

            // Whenever the last child element is also block-level, it'll take care of mapping the
            // range on its own.
            //
            if let lastChild = element.children.last as? ElementNode {
                guard !lastChild.isBlockLevelElement() else {
                    return range
                }
            }

            return NSRange(location: range.location, length: range.length - 1)
        }
    }
}
