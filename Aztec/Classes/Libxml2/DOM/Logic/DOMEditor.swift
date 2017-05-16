import Foundation

extension Libxml2 {
    
    /// Groups all the DOM editing logic.
    ///
    class DOMEditor: DOMLogic {

        typealias NodeMatchTest = (_ node: Node) -> Bool

        private let inspector: DOMInspector
        let knownElements: [StandardElementType] = [.a, .b, .br, .blockquote, .del, .div, .em, .h1,
                                                    .h2, .h3, .h4, .h5, .h6, .hr, .i, .img, .li,
                                                    .ol, .p, .pre, .s, .span, .strike, .strong, .u,
                                                    .ul, .video]
        let undoManager: UndoManager

        convenience init(with rootNode: RootNode, undoManager: UndoManager) {
            self.init(with: rootNode, using: DOMInspector(with: rootNode), undoManager: undoManager)
        }

        init(with rootNode: RootNode, using inspector: DOMInspector, undoManager: UndoManager) {
            self.inspector = inspector
            self.undoManager = undoManager

            super.init(with: rootNode)
        }

        // MARK: - Inserting Characters

        /// Inserts the specified string at the specified location.
        ///
        /// - Parameters:
        ///     - string: the string to insert.
        ///     - location: the location the string will be inserted at.
        ///
        func insert(_ string: String, atLocation location: Int) {
            insert(string, into: rootNode, atLocation: location)
        }

        /// Inserts the specified string into the specified element, at the specified location.
        ///
        /// - NOTE: this method processes paragraph separators found, in order to break block-level
        ///         elements if necessary.  To insert raw strings without processing newlines, call
        ///         `insert(rawString:into:atLocation:)` instead.
        ///
        /// - Parameters:
        ///     - string: the string to insert.
        ///     - element: the element the string will be inserted into.
        ///     - location: the location the string will be inserted at.
        ///
        private func insert(_ string: String, into element: ElementNode, atLocation location: Int) {

            let (insertionElement, insertionLocation)
                = inspector.findLeftmostLowestDescendantElement(of: element, intersecting: location, blockLevel: true)

            if insertionElement.isBlockLevelElement() {
                let paragraphs = string.components(separatedBy: String(.paragraphSeparator))

                insert(paragraphs: paragraphs, into: insertionElement, atLocation: insertionLocation)
            } else {
                insert(rawString: string, into: insertionElement, atLocation: insertionLocation)
            }
        }

        /// Inserts the specified raw string (without processing it for the different newline types)
        /// into the specified element, at the specified location.
        ///
        /// - Parameters:
        ///     - string: the string to insert.
        ///     - element: the element the string will be inserted into.
        ///     - location: the location the string will be inserted at.
        ///
        private func insert(rawString string: String, into element: ElementNode, atLocation location: Int) {

            guard string.characters.count > 0 else {
                return
            }

            let childrenBefore = element.splitChildren(before: location)

            let nodesToInsert = nodes(for: string)

            element.insert(nodesToInsert, at: childrenBefore.count)
            element.fixChildrenTextNodes()
        }

        // MARK: - Inserting Paragraphs

        /// Inserts the specified paragraph into the specified block-level element, at the
        /// specified location, interrupting the element at the end of the paragraph.
        ///
        /// - Parameters:
        ///     - paragraph: the paragraph to insert.
        ///     - blockLevelElement: the block-level element the paragraph will be inserted into.
        ///     - location: the location the paragraph will be inserted at.
        ///
        ///
        private func insert(paragraph: String, into blockLevelElement: ElementNode, atLocation location: Int) {
            assert(blockLevelElement.isBlockLevelElement())

            insert(rawString: paragraph, into: blockLevelElement, atLocation: location)
            blockLevelElement.split(atLocation: location + paragraph.characters.count)
        }

        /// Inserts the specified paragraphs into the specified block-level element, at the
        /// specified location.  Paragraphs will break the lowest block-level element they can find.
        ///
        /// - Parameters:
        ///     - paragraphs: the paragraphs to insert.  The last element in this array will NOT
        ///             close a paragraph.  If that's necessary, the caller should add an empty
        ///             paragraph as the last element.  This method was designed to work directly
        ///             with the results of calling `string.components(separatedBy: String(.paragraphSeparator))`
        ///     - blockLevelElement: the block-level element the paragraphs will be inserted into.
        ///     - location: the location the paragraphs will be inserted at.
        ///
        private func insert(paragraphs: [String], into blockLevelElement: ElementNode, atLocation location: Int) {
            assert(blockLevelElement.isBlockLevelElement())

            let (insertionElement, insertionLocation)
                = inspector.findLeftmostLowestDescendantElement(of: blockLevelElement, intersecting: location, blockLevel: true)

            var currentElement = insertionElement
            var currentLocation = insertionLocation

            for (index, paragraph) in paragraphs.enumerated() {

                guard index != paragraphs.count else {
                    insert(rawString: paragraph, into: currentElement, atLocation: currentLocation)
                    continue
                }

                insert(paragraph: paragraph, into: currentElement, atLocation: currentLocation)

                currentElement = inspector.rightSibling(of: insertionElement) as! ElementNode
                currentLocation = currentLocation + 1
            }
        }

        // MARK: - Deleting Characters

        /// Deletes the characters in `rootNode` spanning the specified range.
        ///
        /// - Parameters:
        ///     - range: the range of text to delete.
        ///
        private func deleteCharacters(spanning range: NSRange) {
            let childrenAndIntersections = rootNode.childNodes(intersectingRange: range)

            for (child, intersection) in childrenAndIntersections {
                deleteCharacters(in: child, spanning: intersection)
            }
        }

        /// Deletes the characters in the specified node spanning the specified range.
        ///
        /// - Note: this method should not be called on a `RootNode`.  Call
        ///     `deleteCharacters(inRange:)` instead.
        ///
        /// - Parameters:
        ///     - node: the node containing the character-range so delete.
        ///     - range: the range of text to delete.
        ///
        private func deleteCharacters(in node: Node, spanning range: NSRange) {
            assert(!(node is RootNode))

            if let commentNode = node as? CommentNode {
                deleteCharacters(in: commentNode, spanning: range)
            } else if let element = node as? ElementNode {
                deleteCharacters(in: element, spanning: range)
            } else if let textNode = node as? TextNode {
                deleteCharacters(in: textNode, spanning: range)
            }
        }

        /// Deletes the characters in the specified `CommentNode` spanning the specified range.
        ///
        /// - Parameters:
        ///     - commentNode: the `CommentNode` containing the character-range so delete.
        ///     - range: the range of text to delete.
        ///
        private func deleteCharacters(in commentNode: CommentNode, spanning range: NSRange) {
            guard range.location == 0 && range.length == commentNode.length() else {
                return
            }

            commentNode.removeFromParent()
        }

        /// Deletes the characters in the specified `ElementNode` spanning the specified range.
        ///
        /// - Note: this method should not be called on a `RootNode`.  Call
        ///     `deleteCharacters(inRange:)` instead.
        ///
        /// - Parameters:
        ///     - element: the `ElementNode` containing the character-range so delete.
        ///     - range: the range of text to delete.
        ///
        private func deleteCharacters(in element: ElementNode, spanning range: NSRange) {

            assert(!(element is RootNode))
            assert(range.length > 0)

            if range.location == 0 && range.length == element.length() {
                element.removeFromParent()
            } else {
                let rangeForChildren = mapToChildren(range: range, of: element)
                let childrenAndIntersections = element.childNodes(intersectingRange: rangeForChildren)

                for (child, intersection) in childrenAndIntersections {
                    deleteCharacters(in: child, spanning: intersection)
                }

                if rangeForChildren.length != range.length {
                    mergeRight(element)
                }
            }
        }

        /// Deletes the characters in the specified `TextNode` spanning the specified range.
        ///
        /// - Parameters:
        ///     - element: the `ElementNode` containing the character-range so delete.
        ///     - range: the range of text to delete.
        ///
        private func deleteCharacters(in textNode: TextNode, spanning range: NSRange) {
            textNode.deleteCharacters(inRange: range)
        }

        // MARK: - Replacing Characters

        /// Replaces the characters in the specified range with the specified string.
        ///
        /// - Parameters:
        ///     - range: the range of the characters to replace.
        ///     - string: the string to replace the range with.
        ///
        func replaceCharacters(in range: NSRange, with string: String) {
            if range.length > 0 {
                deleteCharacters(spanning: range)
            }

            if string.characters.count > 0 {
                insert(string, atLocation: range.location)
            }
        }

        // MARK: - String to Nodes

        /// Creates several nodes to represent a specified string.  This method currently splits a
        /// string by their newlines into components and returns an array of TextNodes and BR nodes.
        ///
        /// - Parameters:
        ///     - string: the string to represent using nodes.
        ///
        /// - Returns: an array of `TextNode`s and `BR` nodes.
        ///
        private func nodes(for string: String) -> [Node] {
            let separatorElement = ElementNodeDescriptor(elementType: .br)
            let components = string.components(separatedBy: String(.newline))
            var nodes = [Node]()

            for (index, component) in components.enumerated() {
                nodes.append(TextNode(text: component))

                if index != components.count - 1 {
                    nodes.append(ElementNode(descriptor: separatorElement, children: []))
                }
            }

            return nodes
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

        // MARK: - Wrapping: Ranges

        func wrap(_ range: NSRange, in elementDescriptor: ElementNodeDescriptor) {
            wrap(range, of: rootNode, in: elementDescriptor)
        }

        func wrap(_ range: NSRange, of element: ElementNode, in elementDescriptor: ElementNodeDescriptor) {

            let elementsAndRanges = inspector.findLowestBlockElementDescendants(
                of: element,
                spanning: range,
                bailCheck: { node in
                    return elementDescriptor.matchingNames.contains(node.name)
            })

            for (matchElement, matchRange) in elementsAndRanges {

                // We don't allow wrapping empty ranges.
                //
                guard matchRange.length > 0 else {
                    continue
                }

                guard matchElement.range() != matchRange
                    || matchElement is RootNode
                    || matchElement.isBlockLevelElement() else {

                        wrap(matchElement, in: elementDescriptor)
                        return
                }

                wrapChildren(of: matchElement, spanning: matchRange, in: elementDescriptor)
            }
        }

        // MARK: - Wrapping: Nodes

        private func wrap(_ node: Node, in elementDescriptor: ElementNodeDescriptor) {

            let parent = node.parent!
            let index = parent.children.index(of: node)!

            let element = ElementNode(descriptor: elementDescriptor, children: [node])

            parent.insert(element, at: index)
        }

        private func wrapChildren(of element: ElementNode, spanning range: NSRange, in elementDescriptor: ElementNodeDescriptor) {

            assert(range.length > 0)
            assert(!elementDescriptor.isBlockLevel()
                || element is RootNode
                || element.isBlockLevelElement())

            let (_, centerNodes, _) = splitChildren(of: element, for: range)

            wrapChildren(centerNodes, of: element, inElement: elementDescriptor)
        }

        /// Wraps the specified children nodes in a newly created element with the specified name.
        /// The newly created node will be inserted at the position of `children[0]`.
        ///
        /// - Parameters:
        ///     - children: the children nodes to wrap in a new node.
        ///     - elementDescriptor: the descriptor for the element to wrap the children in.
        ///
        /// - Returns: the newly created `ElementNode`.
        ///
        @discardableResult
        func wrapChildren(_ selectedChildren: [Node], of element: ElementNode, inElement elementDescriptor: ElementNodeDescriptor) -> ElementNode {

            var childrenToWrap = selectedChildren

            guard selectedChildren.count > 0 else {
                assertionFailure("Avoid calling this method with no nodes.")
                return ElementNode(descriptor: elementDescriptor)
            }

            guard let firstNodeIndex = element.children.index(of: childrenToWrap[0]) else {
                fatalError("A node's parent should contain the node. Review the child/parent updating logic.")
            }

            guard let lastNodeIndex = element.children.index(of: childrenToWrap[childrenToWrap.count - 1]) else {
                fatalError("A node's parent should contain the node. Review the child/parent updating logic.")
            }

            let evaluation = { (node: ElementNode) -> Bool in
                return node.name == elementDescriptor.name
            }

            let bailEvaluation = { (node: ElementNode) -> Bool in
                return node.isBlockLevelElement()
            }

            // First get the right sibling because if we do it the other round, lastNodeIndex will
            // be modified before we access it.
            //
            let rightSibling = elementDescriptor.canMergeRight ? element.pushUp(siblingOrDescendantAtRightSideOf: lastNodeIndex, evaluatedBy: evaluation, bailIf: bailEvaluation) : nil
            let leftSibling = elementDescriptor.canMergeLeft ? element.pushUp(siblingOrDescendantAtLeftSideOf: firstNodeIndex, evaluatedBy: evaluation, bailIf: bailEvaluation) : nil

            var wrapperElement: ElementNode?

            if let sibling = rightSibling {
                sibling.prepend(childrenToWrap, tryToMergeWithSiblings: false)
                childrenToWrap = sibling.children

                wrapperElement = sibling
            }

            if let sibling = leftSibling {
                sibling.append(childrenToWrap, tryToMergeWithSiblings: false)
                childrenToWrap = sibling.children

                wrapperElement = sibling

                if let rightSibling = rightSibling, rightSibling.children.count == 0 {
                    rightSibling.removeFromParent()
                }
            }

            let finalWrapper = wrapperElement ?? { () -> ElementNode in
                let newNode = ElementNode(descriptor: elementDescriptor, children: childrenToWrap)

                element.children.insert(newNode, at: firstNodeIndex)
                newNode.parent = element

                return newNode
                }()

            if let childElementDescriptor = elementDescriptor.childDescriptor {
                wrapChildren(selectedChildren, of: element, inElement: childElementDescriptor)
            }

            if let elementType = StandardElementType(rawValue: elementDescriptor.name),
                ElementNode.elementsThatSpanASingleLine.contains(elementType) {
                
                finalWrapper.splitAtBreaks()
            }
            
            return finalWrapper
        }
/*
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

            //element.wrap(children: children, inElement: elementDescriptor)
            wrapChildren(children, of: element, inElement: elementDescriptor)
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
        */

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
        @discardableResult
        func unwrap(range: NSRange, fromElementsNamed elementNames: [String]) -> NSRange {
            return unwrap(rootNode, range: range, fromElementsNamed: elementNames)
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
        func unwrap(_ element: ElementNode, range: NSRange, fromElementsNamed elementNames: [String]) -> NSRange {

            guard element.children.count > 0 else {
                return range
            }

            var resultingRange = unwrapChildren(of: element, intersecting: range, fromElementsNamed: elementNames)

            if elementNames.contains(element.name) {

                let rangeEndLocation = range.location + range.length

                let myLength = element.length()
                assert(range.location >= 0 && rangeEndLocation <= myLength,
                       "The specified range is out of bounds.")

                let elementDescriptor = ElementNodeDescriptor(name: element.name, attributes: element.attributes)

                if range.location > 0 {
                    let preRange = NSRange(location: 0, length: range.location)
                    wrap(preRange, of: element, in: elementDescriptor)
                }

                if rangeEndLocation < myLength {
                    let postRange = NSRange(location: rangeEndLocation, length: myLength - rangeEndLocation)
                    wrap(postRange, of: element, in: elementDescriptor)
                }

                if element.needsClosingParagraphSeparator() {
                    let br = ElementNode(name: StandardElementType.br.rawValue, attributes: [], children: [])

                    element.append(br)

                    resultingRange = NSRange(location: resultingRange.location, length: resultingRange.length + br.length())
                }

                element.unwrapChildren()
            }

            return resultingRange
        }

        /// Unwraps all child nodes from elements with the specified names.
        ///
        /// - Parameters:
        ///     - element: the element containing the specified range.
        ///     - range: the range we want to unwrap.
        ///     - elementNames: the name of the elements we want to unwrap the nodes from.
        ///
        /// - Returns: the provided range after the unwrapping (since it may be modified by newlines
        ///     being added).
        ///
        func unwrapChildren(of element: ElementNode, intersecting range: NSRange, fromElementsNamed elementNames: [String]) -> NSRange {

            let childNodesAndRanges = element.childNodes(intersectingRange: range)
            assert(childNodesAndRanges.count > 0)

            var resultingRange = range

            for (child, childRange) in childNodesAndRanges {
                guard let childElement = child as? ElementNode else {
                    continue
                }

                let newRange = unwrap(childElement, range: childRange, fromElementsNamed: elementNames)

                if newRange.length != childRange.length {
                    let diff = childRange.length - newRange.length

                    resultingRange = NSRange(location: resultingRange.location, length: resultingRange.length - diff)
                }
            }

            return resultingRange
        }

        // MARK: - Splitting Nodes

        /// Splits the specified node at the specified offset.
        ///
        /// - IMPORTANT: after calling this method, assume the input node is no longer valid and
        ///         use the returned nodes instead.
        ///
        /// - Parameters:
        ///     - node: the node to split.
        ///     - offset: the offset to split the node at.  Should not be an edge offset.
        ///
        /// - Returns: the node at the left and right side of the split.
        ///
        func split(_ node: Node, at offset: Int) -> (left: Node, right: Node) {

            assert(offset != 0 && offset != node.length())

            if let textNode = node as? TextNode {
                return split(textNode, at: offset)
            } else if let element = node as? ElementNode {
                return split(element, at: offset)
            } else {
                fatalError("The node type is not supported by this method.")
            }
        }

        /// Splits the specified element node at the specified offset.
        ///
        /// - IMPORTANT: after calling this method, assume the input node is no longer valid.
        ///
        /// - Parameters:
        ///     - element: the element node to split.
        ///     - offset: the offset to split the node at.  Should not be an edge offset.
        ///
        /// - Returns: the nodes at the left and right side of the split.
        ///
        func split(_ element: ElementNode, at offset: Int) -> (left: Node, right: Node) {

            assert(offset != 0 && offset != element.length())

            let parent = inspector.parent(of: element)

            let (leftChildren, rightChildren) = splitChildren(of: element, at: offset)

            let leftElement = ElementNode.init(name: element.name, attributes: element.attributes, children: leftChildren)
            let rightElement = ElementNode.init(name: element.name, attributes: element.attributes, children: rightChildren)

            parent.replace(child: element, with: [leftElement, rightElement])

            return (leftElement, rightElement)
        }

        /// Splits the specified text node at the specified offset.
        ///
        /// - IMPORTANT: after calling this method, assume the input node is no longer valid.
        ///
        /// - Parameters:
        ///     - textNode: the node to split.
        ///     - offset: the offset to split the node at.  Should not be an edge offset.
        ///
        /// - Returns: the nodes at the left and right side of the split.
        ///
        func split(_ textNode: TextNode, at offset: Int) -> (left: Node?, right: Node?) {

            assert(offset != 0 && offset != textNode.length())

            let parent = inspector.parent(of: textNode)

            let text = textNode.text()

            let leftRange = NSRange(location: 0, length: offset)
            let rightRange = NSRange(location: offset, length: text.characters.count - offset)

            let leftSwiftRange = text.range(fromUTF16NSRange: leftRange)
            let rightSwiftRange = text.range(fromUTF16NSRange: rightRange)

            let leftNode = TextNode(text: textNode.text().substring(with: leftSwiftRange))
            let rightNode = TextNode(text: textNode.text().substring(with: rightSwiftRange))

            parent.replace(child: textNode, with: [leftNode, rightNode])

            return (leftNode, rightNode)
        }

        // MARK: - Splitting Nodes: Children

        /// Splits the child at the specified offset.
        ///
        /// - Parameters:
        ///     - element: the reference element.  This is the parent to the node that will be split.
        ///     - offset: the offset for the split.  Cannot be at the parent edge coordinates, but
        ///             can be at a child's edge coordinates.
        ///
        /// - Returns: the left and right nodes after the split.  If the offset falls at the
        ///         beginning of a child node, no split will occur and this method will return
        ///         `(nil, node)`.  If the offset falls at the end of a child node, no split will
        ///         occur and this method will return `(node, nil)`.
        ///
        func splitChild(of element: ElementNode, at offset: Int) -> (left: Node?, right: Node?) {

            assert(offset != 0 && offset != element.length())

            guard let (child, intersection) = inspector.findLeftmostChild(of: element, intersecting: offset) else {
                fatalError("Cannot split the children of an element that has no children.")
            }

            guard intersection != 0 else {
                return (nil, child)
            }

            guard intersection != child.length() else {
                return (child, nil)
            }

            let (leftNode, rightNode) = split(child, at: intersection)

            return (leftNode, rightNode)
        }

        /// Splits the children of the reference node, using a range as reference.
        ///
        ///
        func splitChildren(of element: ElementNode, for range: NSRange) -> (left: [Node], center: [Node], right: [Node]) {

            assert(range.length > 0)

            guard element.range().contains(range: range) else {
                fatalError("Specified range is out-of-bounds.")
            }

            let (leftNodeSplit1, rightNodeSplit1) = splitChild(of: element, at: range.location)
            let (leftNodeSplit2, rightNodeSplit2) = splitChild(of: element, at: range.location + range.length)

            let leftNodes: [Node]

            if let leftNodeSplit1 = leftNodeSplit1 {
                leftNodes = inspector.findLeftSiblings(of: leftNodeSplit1, includingReferenceNode: true)
            } else {
                leftNodes = []
            }

            let rightNodes: [Node]

            if let rightNodeSplit2 = rightNodeSplit2 {
                rightNodes = inspector.findRightSiblings(of: rightNodeSplit2, includingReferenceNode: true)
            } else {
                rightNodes = []
            }

            // Since the range can't be zero, and it must fall within the range of this node,
            // there MUST be nodes in the center.
            //
            let centerNodesStartIndex = element.indexOf(childNode: rightNodeSplit1!)
            let centerNodesEndIndex = element.indexOf(childNode: leftNodeSplit2!)

            let centerNodes = element.children.subArray(from: centerNodesStartIndex, through: centerNodesEndIndex)

            return (leftNodes, centerNodes, rightNodes)
        }

        /// Splits the children of the specified element at the specified offset (in the reference
        /// element's coordinates).
        ///
        /// - Parameters:
        ///     - element: the element to split the children of.
        ///     - offset: the offset where the split must take place.  Cannot be at the reference
        ///             element's edges, but it can fall within the edges of a child node.
        ///
        /// - Returns: the nodes at the left and right side of the split.
        ///
        func splitChildren(of element: ElementNode, at offset: Int) -> (left: [Node], right: [Node]) {

            assert(offset != 0 && offset != element.length())
            assert(element.range().contains(offset: offset))

            guard let (child, intersection) = inspector.findLeftmostChild(of: element, intersecting: offset) else {
                fatalError("This should not happen.  Review the logic.")
            }

            guard intersection != 0 || intersection != child.length() else {
                let includeInRightNodes = intersection == 0
                let includeInLeftNodes = !includeInRightNodes

                let leftNodes = inspector.findLeftSiblings(of: child, includingReferenceNode: includeInLeftNodes)
                let rightNodes = inspector.findRightSiblings(of: child, includingReferenceNode: includeInRightNodes)

                return (leftNodes, rightNodes)
            }

            let (leftNode, rightNode) = split(child, at: intersection)

            let leftNodes = inspector.findLeftSiblings(of: leftNode, includingReferenceNode: true)
            let rightNodes = inspector.findRightSiblings(of: rightNode, includingReferenceNode: true)

            return (leftNodes, rightNodes)
        }

/*
        /// Retrieves all child nodes positioned after a specified location.
        ///
        /// - Parameters:
        ///     - splitLocation: marks the split location.
        ///
        /// - Returns: the requested nodes.
        ///
        fileprivate func splitChildren(after splitLocation: Int) -> [Node] {

            var result = [Node]()
            var childStartLocation = Int(0)

            for child in children {
                let childLength = child.length()
                let childEndLocation = childStartLocation + childLength

                if childStartLocation >= splitLocation {
                    result.append(child)
                } else if childStartLocation < splitLocation && childEndLocation > splitLocation {

                    let splitLocationInChild = splitLocation - childStartLocation
                    let splitRange = NSRange(location: splitLocationInChild, length: childEndLocation - splitLocation)

                    child.split(forRange: splitRange)
                    result.append(child)
                }

                childStartLocation = childEndLocation
            }

            return result
        }

        /// Retrieves all child nodes positioned before a specified location.
        ///
        /// - Parameters:
        ///     - splitLocation: marks the split location.
        ///
        /// - Returns: the requested nodes.
        ///
        func splitChildren(before splitLocation: Int) -> [Node] {

            var result = [Node]()
            var childOffset = Int(0)

            for child in children {
                let childLength = child.length()
                let childEndLocation = childOffset + childLength

                if childEndLocation <= splitLocation {
                    result.append(child)
                } else if childOffset < splitLocation && childEndLocation > splitLocation {

                    let splitLocationInChild = splitLocation - childOffset
                    let splitRange = NSRange(location: 0, length: splitLocationInChild)

                    child.split(forRange: splitRange)
                    result.append(child)
                }

                childOffset = childOffset + childLength
            }

            return result
        }
 */

        // MARK: - Splitting Nodes: Block-level elements

        func splitLowestBlockLevelElement(at location: Int) {

            let range = NSRange(location: location, length: 0)
            let elementsAndIntersections = rootNode.lowestBlockLevelElements(intersectingRange: range)

            guard let elementAndIntersection = elementsAndIntersections.first else {
                // If there's no block-level element to break, we simply add a line separator
                //
                replaceCharacters(in: range, with: String(.lineSeparator))
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


        // MARK: - Range Mapping to Children

        /// Maps the specified range to the child nodes.
        ///
        private func mapToChildren(range: NSRange, of element: ElementNode) -> NSRange {

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
