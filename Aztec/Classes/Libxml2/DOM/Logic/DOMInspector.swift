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

            guard previousIndex >= 0 else {
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

            guard let parent = node.parent else {
                return nil
            }

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

        /// This method is used to verify if an offset is valid for a block-level element.
        /// This method assumes the caller already knows the offset is inside the range of the
        /// block-level element.
        ///
        /// - Parameters:
        ///     - offset: the insertion offset.
        ///     - blockElement: the reference block element.
        ///
        /// - Returns: `true` if the offset is valid for inserting into the reference
        ///         block-level element.  `false` otherwise.
        ///
        private func isValid(offset: Int, for blockElement: ElementNode) -> Bool {
            assert(isBlockLevelElement(blockElement))
            assert(range(of: blockElement).contains(offset: offset))

            return !needsClosingParagraphSeparator(blockElement) || offset != length(of: blockElement)
        }

        func isSupportedByEditor(_ element: ElementNode) -> Bool {

            guard let standardName = element.standardName else {
                return false
            }

            return knownElements.contains(standardName)
        }

        // MARK: - Node Position Relative to Ancestors

        /// Checks if the receiver is the last node in its parent.
        /// Empty text nodes are filtered to avoid false positives.
        ///
        func isFirstInParent(_ node: Node) -> Bool {

            guard let parent = node.parent else {
                return true
            }

            // We are filtering empty text nodes from being considered.
            //
            let match = findFirstChild(of: parent, where: { node -> Bool in
                guard let textNode = node as? TextNode,
                    textNode.contents.characters.count == 0 else {
                        return true
                }

                return false
            })

            return node === match
        }

        /// Checks if the receiver is the first node in the tree.
        ///
        /// - Note: The verification excludes all child nodes, since this method only cares about
        ///     siblings and parents in the tree.
        ///
        func isFirstInTree(_ node: Node) -> Bool {

            guard let parent = node.parent else {
                return true
            }
            
            return isFirstInParent(node) && isFirstInTree(parent)
        }

        /// Checks if the receiver is the last node in its parent.
        /// Empty text nodes are filtered to avoid false positives.
        ///
        func isLastInParent(_ node: Node) -> Bool {

            guard let parent = node.parent else {
                return true
            }

            // We are filtering empty text nodes from being considered.
            //
            let match = findLastChild(of: parent, where: { node -> Bool in
                guard let textNode = node as? TextNode,
                    textNode.contents.characters.count == 0 else {
                        return true
                }

                return false
            })

            return node === match
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

        // MARK: - Paragraph Separator

        func needsClosingParagraphSeparator(_ element: ElementNode) -> Bool {
            guard isBlockLevelElement(element),
                !isLastInTree(element) else {
                    return false
            }

            if let rightmostChild = findRightmostChild(of: element) as? ElementNode {
                return !isBlockLevelElement(rightmostChild)
            } else {
                return true
            }
        }

        func needsOpeningParagraphSeparator(_ element: ElementNode) -> Bool {
            guard isBlockLevelElement(element),
                !isFirstInTree(element) else {
                    return false
            }

            // The opening paragraph separator is not needed if this element comes immediately
            // after other block-level elements.
            //
            if let nodeBefore = findFirstNodeBefore(element) as? ElementNode {
                guard !isBlockLevelElement(nodeBefore) else {
                    return false
                }
            }

            if let leftmostChild = findLeftmostChild(of: element) as? ElementNode {
                return !isBlockLevelElement(leftmostChild)
            } else {
                return true
            }
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

            guard element is RootNode || isSupportedByEditor(element) else {
                return String(.objectReplacement)
            }

            if let nodeType = element.standardName,
                let implicitRepresentation = nodeType.implicitRepresentation() {

                return implicitRepresentation.string
            }

            var text = ""

            if needsOpeningParagraphSeparator(element) {
                text.append(String(.paragraphSeparator))
            }

            for child in element.children {
                text.append(self.text(for: child))
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


        // MARK: - Comparison

        func canMerge(left: Node, right: Node) -> Bool {
            if left is CommentNode || right is CommentNode {
                return false
            }

            if left is TextNode && right is TextNode {
                return true
            }

            guard let leftElement = left as? ElementNode, let rightElement = right as? ElementNode else {
                return false
            }

            let matchingName = leftElement.name == rightElement.name

            let leftAttributes = Set(leftElement.attributes)
            let rightAttributes = Set(rightElement.attributes)
            let matchingAttributes = leftAttributes == rightAttributes

            return matchingName && matchingAttributes
        }


        // MARK: - Ranges

        /// The range of an element's content, without the block-level separators.
        ///
        /// - Parameters:
        ///     - element: the element to get the length of.
        ///
        /// - Returns: the requested length.
        ///
        func contentRange(of element: ElementNode) -> NSRange {

            var range = self.range(of: element)

            if needsOpeningParagraphSeparator(element) {
                range.location = 1
                range.length = range.length - 1
            }

            if needsClosingParagraphSeparator(element) {
                range.length = range.length - 1
            }

            return range
        }

        /// The range of an node.  Equal to the sum of the length of all child nodes, plus
        /// any paragraph separators if the node has them.
        ///
        /// - Parameters:
        ///     - node: the node to get the length of.
        ///
        /// - Returns: the requested length.
        ///
        func range(of node: Node) -> NSRange {
            return NSRange(location: 0, length: length(of: node))
        }

        /// Returns the range of the closing paragraph separator for the specified node, only if the
        /// specified node has it.
        ///
        /// - Parameters:
        ///     - element: the reference element.
        ///
        /// - Returns: the range of the paragraph separator if it exists, or `nil`.
        ///
        func rangeOfClosingParagraphSeparator(for element: ElementNode) -> NSRange? {
            guard needsClosingParagraphSeparator(element) else {
                return nil
            }

            return NSRange(location: length(of: element) - 1, length: String(.paragraphSeparator).characters.count)
        }

        /// Returns the range of the opening paragraph separator for the specified node, only if the
        /// specified node has it.
        ///
        /// - Parameters:
        ///     - element: the reference element.
        ///
        /// - Returns: the range of the paragraph separator if it exists, or `nil`.
        ///
        func rangeOfOpeningParagraphSeparator(for element: ElementNode) -> NSRange? {
            guard needsOpeningParagraphSeparator(element) else {
                return nil
            }

            return NSRange(location: 0, length: String(.paragraphSeparator).characters.count)
        }

        // MARK: - Finding Nodes: Before and After

        func findFirstNodeAfter(_ node: Node) -> Node? {

            if let rightSibling = self.rightSibling(of: node) {
                return rightSibling
            } else {
                guard let parent = node.parent else {
                    return nil
                }

                return findFirstNodeAfter(parent)
            }
        }

        func findFirstNodeBefore(_ node: Node) -> Node? {

            if let leftSibling = self.leftSibling(of: node) {
                return leftSibling
            } else {
                guard let parent = node.parent else {
                    return nil
                }

                return findFirstNodeBefore(parent)
            }
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

                let childRangeInParent = self.range(of: child).offset(by: offset)

                guard let intersectionInParent = range.intersect(withRange: childRangeInParent) else {
                    continue
                }

                elementsAndRanges.append((child, intersectionInParent.offset(by: -offset)))
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

                let childRangeInParent: NSRange

                if let childElement = child as? ElementNode {
                    childRangeInParent = contentRange(of: childElement).offset(by: childOffset)
                } else {
                    childRangeInParent = range(of: child).offset(by: childOffset)
                }

                if childRangeInParent.contains(offset: offset) {
                    return (node: child, offset: offset - childOffset)
                }

                childOffset = childOffset + length(of: child)
            }
            
            return nil
        }

        /// Returns the leftmost child.  Optionally allows the caller to define if empty text nodes
        /// are valid results.  By default they're not.
        ///
        /// - Parameters:
        ///     - element: the reference element, to search the children of.
        ///     - ignoreEmptyTextNodes: optional parameter to specify if empty text nodes are
        ///             valid results or not.
        ///
        /// - Returns: the requested node.
        ///
        func findLeftmostChild(
            of element: ElementNode,
            ignoreEmptyTextNodes: Bool = true) -> Node? {

            return findLeftmostChild(of: element, where: { node -> Bool in
                guard let textNode = node as? TextNode,
                    text(for: textNode).characters.count == 0 else {
                        return true
                }

                return false
            })
        }

        /// Returns the leftmost child of an element satisfying a specified condition.
        ///
        /// - Parameters:
        ///     - element: the reference element, to search the children of.
        ///     - condition: the condition the child node must satisfy.
        ///
        /// - Returns: the requested node if found, or `nil`.
        ///
        func findLeftmostChild(
            of element: ElementNode,
            where condition: (Node) -> Bool) -> Node? {

            for child in element.children {
                if condition(child) {
                    return child
                }
            }
            
            return nil
        }

        /// Returns the right child.  Optionally allows the caller to define if empty text nodes
        /// are valid results.  By default they're not.
        ///
        /// - Parameters:
        ///     - element: the reference element, to search the children of.
        ///     - ignoreEmptyTextNodes: optional parameter to specify if empty text nodes are
        ///             valid results or not.
        ///
        /// - Returns: the requested node.
        ///
        func findRightmostChild(
            of element: ElementNode,
            ignoreEmptyTextNodes: Bool = true) -> Node? {

            return findRightmostChild(of: element, where: { node -> Bool in
                guard let textNode = node as? TextNode,
                    text(for: textNode).characters.count == 0 else {
                        return true
                }

                return false
            })
        }

        /// Returns the rightmost child of an element satisfying a specified condition.
        ///
        /// - Parameters:
        ///     - element: the reference element, to search the children of.
        ///     - condition: the condition the child node must satisfy.
        ///
        /// - Returns: the requested node if found, or `nil`.
        ///
        func findRightmostChild(
            of element: ElementNode,
            where condition: (Node) -> Bool) -> Node? {

            for child in element.children.reversed() {
                if condition(child) {
                    return child
                }
            }

            return nil
        }

        /// Retrieves the first child matching a specific filtering closure.
        ///
        /// - Parameters:
        ///     - condition: the condition for a node to match the search.
        ///
        /// - Returns: the requested node, or `nil` if there are no nodes matching the request.
        ///
        func findFirstChild(of element: ElementNode, where condition: (Node) -> Bool) -> Node? {
            return element.children.first(where: condition)
        }

        /// Retrieves the last child matching a specific filtering closure.
        ///
        /// - Parameters:
        ///     - condition: the condition for a node to match the search.
        ///
        /// - Returns: the requested node, or `nil` if there are no nodes matching the request.
        ///
        func findLastChild(of element: ElementNode, where condition: (Node) -> Bool) -> Node? {
            return element.children.reversed().first(where: condition)
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
                if bailCheck(element) {
                    return []
                } else {
                    return [(element, range)]
                }
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

                let childRangeInParent = self.range(of: child).offset(by: offset)
                
                guard let intersection = range.intersect(withRange: childRangeInParent) else {
                    continue
                }

                guard let childElement = child as? ElementNode,
                    isBlockLevelElement(childElement) else {
                        elementsAndRanges.append((element, intersection))
                        continue
                }

                let childElementsAndRanges = findLowestBlockElementDescendants(of: childElement, spanning: intersection.offset(by: -offset), bailCheck: bailCheck)

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

                guard location <= endLocation,
                    let element = node as? ElementNode,
                    !blockLevel || (isBlockLevelElement(element) && isValid(offset: location, for: element)) else {

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
                    return range.offset(by: childOffset)
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

        /// Returns the lowest-level element node in this node's hierarchy that wraps the specified
        /// range. If no child element node wraps the specified range, this method returns this
        /// node.
        ///
        /// - Parameters:
        ///     - node: the node whose children must be checked.
        ///     - range: the range we want to find the wrapping node of.
        ///
        /// - Returns: the lowest-level element node wrapping the specified range, or the main node if
        ///         no child node fulfills the condition.
        ///
        func lowestChildElementNode(of node: ElementNode, spanning range: NSRange) -> ElementNode {

            var offset = 0

            for child in node.children {
                let nodeLength = length(of: child)
                let nodeRange = NSRange(location: offset, length: nodeLength)
                let nodeWrapsRange = (NSUnionRange(nodeRange, range).length == nodeRange.length)

                if nodeWrapsRange {
                    if let elementNode = child as? ElementNode {

                        let childRange = NSRange(location: range.location - offset, length: range.length)

                        return lowestChildElementNode(of: elementNode, spanning: childRange)
                    }

                    return node
                }

                offset = offset + nodeLength
            }
            
            return node
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
