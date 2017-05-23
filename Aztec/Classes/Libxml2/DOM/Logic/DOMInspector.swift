import Foundation

extension Libxml2 {
    /// Groups all the DOM inspection & node lookup logic.
    ///
    class DOMInspector {

        let knownElements: [StandardElementType] = [.a, .b, .br, .blockquote, .del, .div, .em, .h1,
                                                    .h2, .h3, .h4, .h5, .h6, .hr, .i, .img, .li,
                                                    .ol, .p, .pre, .s, .span, .strike, .strong, .u,
                                                    .ul, .video]

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
        func leftSibling(of node: Node, ignoreEmptyTextNodes: Bool = false) -> Node? {

            let parent = self.parent(of: node)
            let previousIndex = parent.indexOf(childNode: node) - 1

            guard previousIndex > 0 else {
                return nil
            }

            let previousNode = parent.children[previousIndex]

            guard !ignoreEmptyTextNodes || !(previousNode is TextNode) || length(of: previousNode) > 0 else {
                return leftSibling(of: previousNode, ignoreEmptyTextNodes: ignoreEmptyTextNodes)
            }

            return previousNode
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
        func rightSibling(of node: Node, ignoreEmptyTextNodes: Bool = false) -> Node? {

            let parent = self.parent(of: node)
            let nextIndex = parent.indexOf(childNode: node) + 1

            guard parent.children.count > nextIndex else {
                return nil
            }

            let nextNode = parent.children[nextIndex]

            guard !ignoreEmptyTextNodes || !(nextNode is TextNode) || length(of: nextNode) > 0 else {
                return rightSibling(of: nextNode, ignoreEmptyTextNodes: ignoreEmptyTextNodes)
            }

            return nextNode
        }

        /// Retrieves the left-side sibling of the child at the specified index.
        ///
        /// - Parameters:
        ///     - index: the index of the child to get the sibling of.
        ///
        /// - Returns: the requested sibling, or `nil` if there's none.
        ///
        func sibling<T: Node>(leftOf childIndex: Int, in element: ElementNode) -> T? {

            guard childIndex >= 0 && childIndex < element.children.count else {
                fatalError("Out of bounds!")
            }

            guard childIndex > 0 else {
                return nil
            }

            let siblingNode = element.children[childIndex - 1]

            // Ignore empty text nodes.
            //
            if let textSibling = siblingNode as? TextNode, length(of: textSibling) == 0 {
                return sibling(leftOf: childIndex - 1, in: element)
            }

            return siblingNode as? T
        }

        /// Retrieves the right-side sibling of the child at the specified index.
        ///
        /// - Parameters:
        ///     - index: the index of the child to get the sibling of.
        ///
        /// - Returns: the requested sibling, or `nil` if there's none.
        ///
        func sibling<T: Node>(rightOf childIndex: Int, in element: ElementNode) -> T? {

            guard childIndex >= 0 && childIndex <= element.children.count - 1 else {
                fatalError("Out of bounds!")
            }

            guard childIndex < element.children.count - 1 else {
                return nil
            }

            let siblingNode = element.children[childIndex + 1]

            // Ignore empty text nodes.
            //
            if let textSibling = siblingNode as? TextNode, length(of: textSibling) == 0 {
                return sibling(rightOf: childIndex + 1, in: element)
            }
            
            return siblingNode as? T
        }

        // MARK: - Node Introspection

        /// Find out if this is a block-level element.
        ///
        /// - Returns: `true` if this is a block-level element.  `false` otherwise.
        ///
        func isBlockLevelElement(_ element: ElementNode) -> Bool {

            guard let standardName = element.standardName else {
                // For now we're treating all non-standard element names as non-block-level
                // elements.
                //
                return false
            }

            return standardName.isBlockLevelNodeName()
        }

        func isEmptyTextNode(_ node: Node) -> Bool {
            return node is TextNode && length(of: node) == 0
        }

        /// Checks if the receiver is the last node in a block-level ancestor.
        ///
        /// - Note: The verification excludes all child nodes, since this method only cares about
        ///     siblings and parents in the tree.
        ///
        func isLastInBlockLevelAncestor(_ node: Node) -> Bool {

            guard let parent = node.parent else {
                return false
            }

            return isLastInParent(node) &&
                (isBlockLevelElement(parent) || isLastInBlockLevelAncestor(parent))
        }


        /// Checks if the receiver is the last node in its parent.
        /// Empty text nodes are filtered to avoid false positives.
        ///
        func isLastInParent(_ node: Node) -> Bool {

            guard let parent = node.parent else {
                return true
            }

            // We are filtering empty text nodes from being considered the last node in our
            // parent node.
            //
            let lastMatchingChildInParent = parent.lastChild(matching: { node -> Bool in
                guard let textNode = node as? TextNode,
                    length(of: textNode) == 0 else {
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
        func isLastInTree(_ node: Node) -> Bool {

            guard let parent = node.parent else {
                return true
            }

            return isLastInParent(node) && isLastInTree(parent)
        }

        func isSupportedByEditor(_ element: ElementNode) -> Bool {

            guard let standardName = element.standardName else {
                return false
            }

            return knownElements.contains(standardName)
        }

        func needsClosingParagraphSeparator(_ node: Node) -> Bool {

            if let element = node as? ElementNode {
                guard element.children.count == 0 && element.standardName != .br else {
                    return false
                }
            } else if let textNode = node as? TextNode {
                guard length(of: textNode) > 0 else {
                    return false
                }
            }

            if let rightSiblingElement = rightSibling(of: node, ignoreEmptyTextNodes: true) as? ElementNode,
                isBlockLevelElement(rightSiblingElement) {

                return true
            }

            return !isLastInTree(node) && isLastInBlockLevelAncestor(node)
        }

        // MARK: - Text

        func text(for node: Node) -> String {
            if node is CommentNode {
                return String(.objectReplacement)
            } else if let element = node as? ElementNode {
                return text(for: element)
            } else if let textNode = node as? TextNode {
                return text(for: textNode)
            } else {
                assertionFailure("Unsupported node type.")
                return String(.objectReplacement)
            }
        }

        func text(for element: ElementNode) -> String {

            guard isSupportedByEditor(element) else {
                return String(.objectReplacement)
            }

            if let nodeType = element.standardName,
                let implicitRepresentation = nodeType.implicitRepresentation() {

                return implicitRepresentation.string
            }

            var text = ""

            for child in element.children {
                text = text + self.text(for: child)
            }

            if needsClosingParagraphSeparator(element) {
                text.append(String(.paragraphSeparator))
            }
            
            return text
        }

        func text(for textNode: TextNode) -> String {
            return textNode.contents
        }

        func length(of node: Node) -> Int {
            return text(for: node).characters.count
        }

        func range(of node: Node) -> NSRange {
            return NSRange(location: 0, length: length(of: node))
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

            assert(self.range(of: element).contains(range))

            guard element.children.count > 0 else {
                return [(element, range)]
            }

            var elementsAndRanges = [NodeAndIntersection]()
            var offset = 0

            for child in element.children {

                defer {
                    offset = offset + length(of: child)
                }

                let childRangeInParent = self.range(of: child).offset(offset)

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

                let childRangeInParent = range(of: child).offset(childOffset)

                if childRangeInParent.contains(offset: offset) {
                    return (node: child, offset: offset - childOffset)
                }

                childOffset = childOffset + length(of: child)
            }
            
            return nil
        }

        // MARK: - Finding Nodes: Descendants

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

            assert(self.range(of: element).contains(range))

            guard element.children.count > 0 else {
                return [(element, range)]
            }

            var elementsAndRanges = [ElementAndIntersection]()
            var offset = 0

            for child in element.children {

                defer {
                    offset = offset + length(of: child)
                }

                guard !bailCheck(child) else {
                    continue
                }

                let childRangeInParent = self.range(of: child).offset(offset)
                
                guard let intersection = range.intersect(withRange: childRangeInParent) else {
                    continue
                }

                guard let childElement = child as? ElementNode,
                    isBlockLevelElement(childElement) else {
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
                    blockLevel || isBlockLevelElement(element) else {

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
        func findDescendant(of startingElement: ElementNode, endingAt location: Int) -> Node? {

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

                childOffset += length(of: child)
            }

            return ranges
        }

        func find(_ string: String, in textNode: TextNode) -> [NSRange] {
            var ranges = [NSRange]()
            let nodeText = text(for: textNode)

            var currentRange = nodeText.startIndex ..< nodeText.endIndex

            while let range = nodeText.range(of: string, options: [], range: currentRange, locale: nil) {

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

                let childEndLocation = childStartLocation + length(of: child)

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

                let childEndLocation = childStartLocation + length(of: child)

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
    }
}
