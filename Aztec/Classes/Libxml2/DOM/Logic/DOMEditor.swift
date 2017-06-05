import Foundation
import libxml2


extension Libxml2 {

    /// Groups all the DOM editing logic.
    ///
    class DOMEditor {

        typealias NodeMatchTest = (_ node: Node) -> Bool

        let inspector: DOMInspector
        
        let rootNode: RootNode
        let undoManager: UndoManager

        init(with rootNode: RootNode, using inspector: DOMInspector = DOMInspector(), undoManager: UndoManager = UndoManager()) {
            self.inspector = inspector
            self.undoManager = undoManager
            self.rootNode = rootNode
        }
        
        // MARK: - Appending Nodes

        private func appendChild(_ node: Node, to element: ElementNode) {
            insertChild(node, in: element, at: element.children.count)
        }

        private func appendChildren(_ nodes: [Node], to element: ElementNode) {
            for node in nodes {
                appendChild(node, to: element)
            }
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

            let (matchElement, matchLocation) = inspector.findLeftmostLowestDescendantElement(of: element, intersecting: location, blockLevel: true)

            if inspector.isBlockLevelElement(matchElement) {
                let paragraphs = string.components(separatedBy: String(.paragraphSeparator))
                insert(paragraphs: paragraphs, into: matchElement, atLocation: matchLocation)
            } else {
                insert(rawString: string, into: matchElement, atLocation: matchLocation)
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
            
            let nodesToInsert = createNodes(representing: string)

            let insertionIndex: Int

            if location == 0 {
                insertionIndex = 0
            } else if location == inspector.length(of: element) {
                insertionIndex = element.children.count
            } else {
                let (childrenBefore, _) = splitChildren(of: element, at: location)

                insertionIndex = childrenBefore.count
            }

            insertChildren(nodesToInsert, in: element, at: insertionIndex)
            defragChildren(of: element)
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
            assert(inspector.isBlockLevelElement(blockLevelElement))

            insert(rawString: paragraph, into: blockLevelElement, atLocation: location)
            split(blockLevelElement, at: location + paragraph.characters.count)
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
            assert(inspector.isBlockLevelElement(blockLevelElement))

            if location > 0 && location < inspector.length(of: blockLevelElement) {
                splitChildren(of: blockLevelElement, at: location)
            }

            var currentElement = blockLevelElement
            var currentLocation = location

            for (index, paragraph) in paragraphs.enumerated() {

                guard index != paragraphs.count - 1 else {
                    insert(rawString: paragraph, into: currentElement, atLocation: currentLocation)
                    continue
                }

                insert(paragraph: paragraph, into: currentElement, atLocation: currentLocation)

                let (_, nextBlockLevelElement) = split(blockLevelElement, at: location + paragraph.characters.count)

                currentElement = nextBlockLevelElement
                currentLocation = 0
            }
        }

        // MARK: - Inserting Characters with Style.

        func insert(_ attrString: NSAttributedString, atLocation location: Int) {
            insert(attrString, into: rootNode, atLocation: location)
        }

        func insert(_ attrString: NSAttributedString, into element: ElementNode, atLocation location: Int) {

            assert(attrString.length > 0)

            attrString.enumerateParagraphRanges(spanning: attrString.rangeOfEntireString, reverseOrder: true) { (paragraphRange, enclosingRange) in
                let separatorRange = enclosingRange.shortenedLeft(by: paragraphRange.length)
                let separator = attrString.attributedSubstring(from: separatorRange)
                let paragraph = attrString.attributedSubstring(from: paragraphRange)

                insert(paragraph: paragraph, separator: separator, into: element, atLocation: location)
            }
        }

        // MARK: - Inserting Paragraphs with Style.

        func insert(paragraph: NSAttributedString, separator: NSAttributedString, into element: ElementNode, atLocation location: Int) {

            let converter = NSAttributedStringToNodes()
            let nodes = converter.createNodes(fromParagraph: paragraph)
            var nodesToInsert = [Node]()

            if nodes.count > 0 {
                nodesToInsert.append(contentsOf: nodes)
            }

            if separator.length > 0 {
                if converter.hasParagraphStyles(separator) {
                    splitChildren(of: element, at: location)
                } else {
                    nodesToInsert.append(ElementNode(type: .br))
                }
            }

            if nodesToInsert.count > 0 {
                insertChildren(nodesToInsert, in: element, atOffset: location)
            }
        }


        // MARK: - Inserting Children

        private func insertChild(_ node: Node, in element: ElementNode, at index: Int) {

            if let parent = node.parent {
                remove(child: node, from: parent)
            }

            element.children.insert(node, at: index)
            node.parent = element
        }

        private func insertChild(_ node: Node, in element: ElementNode, atOffset offset: Int) {

            assert(inspector.range(of: element).contains(offset: offset))

            let insertionIndex: Int

            if offset == 0 {
                insertionIndex = 0
            } else if offset == inspector.length(of: element) {
                insertionIndex = element.children.count
            } else {
                let (childrenBefore, _) = splitChildren(of: element, at: offset)

                insertionIndex = childrenBefore.count
            }

            insertChild(node, in: element, at: insertionIndex)
        }

        private func insertChild(_ node: Node, in element: ElementNode, after referenceNode: Node) {
            let referenceIndex = element.indexOf(childNode: referenceNode)
            let insertionIndex = referenceIndex + 1

            insertChild(node, in: element, at: insertionIndex)
        }

        private func insertChild(_ node: Node, in element: ElementNode, before referenceNode: Node) {
            let insertionIndex = element.indexOf(childNode: referenceNode)

            insertChild(node, in: element, at: insertionIndex)
        }

        private func insertChildren(_ nodes: [Node], in element: ElementNode, at index: Int) {
            for node in nodes.reversed() {
                insertChild(node, in: element, at: index)
            }
        }

        private func insertChildren(_ nodes: [Node], in element: ElementNode, atOffset offset: Int) {

            assert(nodes.count > 0)

            let insertionIndex: Int

            if offset == 0 {
                insertionIndex = 0
            } else if offset == inspector.length(of: element) {
                insertionIndex = element.children.count
            } else {
                let (childrenBefore, _) = splitChildren(of: element, at: offset)

                insertionIndex = childrenBefore.count
            }

            insertChildren(nodes, in: element, at: insertionIndex)
        }

        // MARK: - Deleting Characters

        /// Deletes the characters in `rootNode` spanning the specified range.
        ///
        /// - Parameters:
        ///     - range: the range of text to delete.
        ///
        private func deleteCharacters(spanning range: NSRange) {
            deleteCharacters(in: rootNode, spanning: range)
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
            } else {
                assertionFailure("Node type not supported.")
            }
        }

        /// Deletes the characters in the specified `CommentNode` spanning the specified range.
        ///
        /// - Parameters:
        ///     - commentNode: the `CommentNode` containing the character-range so delete.
        ///     - range: the range of text to delete.
        ///
        private func deleteCharacters(in commentNode: CommentNode, spanning range: NSRange) {
            guard range.location == 0 && range.length == inspector.length(of: commentNode) else {
                return
            }

            removeFromParent(commentNode)
        }

        /// Deletes the characters in the specified `ElementNode` spanning the specified range.
        ///
        /// - Parameters:
        ///     - element: the `ElementNode` containing the character-range so delete.
        ///     - range: the range of text to delete.
        ///
        private func deleteCharacters(in element: ElementNode, spanning range: NSRange) {

            assert(!(element is RootNode))
            assert(inspector.range(of: element).contains(range))
            assert(range.length > 0)

            if range.location == 0 && range.length == inspector.length(of: element) {
                element.removeFromParent()
            } else {

                let finalRange = ensureRemovalOfParagraphSeparators(for: element, ifFoundIn: range)

                guard finalRange.length > 0 else {
                    return
                }

                deleteCharactersFromChildren(of: element, spanning: finalRange)
            }
        }

        /// Deletes the characters in the specified `TextNode` spanning the specified range.
        ///
        /// - Parameters:
        ///     - element: the `ElementNode` containing the character-range so delete.
        ///     - range: the range of text to delete.
        ///
        private func deleteCharacters(in textNode: TextNode, spanning range: NSRange) {

            assert(inspector.range(of: textNode).contains(range))
            assert(range.length > 0)

            let originalString = textNode.contents
            
            let deleteStartIndex = originalString.index(originalString.startIndex, offsetBy: range.location)
            let deleteEndIndex = originalString.index(deleteStartIndex, offsetBy: range.length)

            let firstSubstring = originalString.substring(to: deleteStartIndex)
            let secondSubstring = originalString.substring(from: deleteEndIndex)

            textNode.contents = firstSubstring + secondSubstring
        }

        /// Deletes the characters in the specified `RootNode` spanning the specified range.
        ///
        /// - Parameters:
        ///     - rootNode: the `RootNode` containing the character-range to delete.
        ///     - range: the range of text to delete.
        ///
        private func deleteCharacters(in rootNode: RootNode, spanning range: NSRange) {

            assert(inspector.range(of: rootNode).contains(range))
            assert(range.length > 0)

            deleteCharactersFromChildren(of: rootNode, spanning: range)
        }

        /// Deletes the characters in the specified `ElementNode` spanning the specified range.
        ///
        /// - Parameters:
        ///     - element: the `ElementNode` containing the children the range will be deleted from.
        ///     - range: the range of text to delete.
        ///
        private func deleteCharactersFromChildren(of element: ElementNode, spanning range: NSRange) {
            assert(inspector.range(of: element).contains(range))
            assert(range.length > 0)

            let childrenAndIntersections = inspector.findChildren(of: element, spanning: range)

            for (child, intersection) in childrenAndIntersections {

                guard intersection.length > 0 else {
                    continue
                }

                deleteCharacters(in: child, spanning: intersection)
            }
        }

        // MARK: - Paragraph Separator Logic

        /// Ensures that the paragraph separators will be deleted if the specified element has them,
        /// and the specified range intersects it.
        ///
        /// - Parameters:
        ///     - range: the range for the deletion operation.
        ///     - element: the element node that owns the specified range.
        ///
        /// - Returns: the input range minus the characters that represent the implicit paragraph
        ///     separator.
        ///
        private func ensureRemovalOfClosingParagraphSeparators(for element: ElementNode, ifFoundIn range: NSRange) -> NSRange {

            // Since some elements have an implicit paragraph separator at their end, we need
            // to merge them right, whenever the separator is removed.
            //
            guard let separatorRange = inspector.rangeOfClosingParagraphSeparator(for: element),
                range.contains(separatorRange) else {
                    return range
            }

            mergeRight(element)

            // After merging the node right, we also need to shorten the range of characters
            // to delete, since the implicit paragraph separator has been removed
            // succesfully.
            //
            return range.shortenedRight(by: separatorRange.length)
        }


        /// Ensures that the paragraph separators will be deleted if the specified element has them,
        /// and the specified range intersects it.
        ///
        /// - Parameters:
        ///     - range: the range for the deletion operation.
        ///     - element: the element node that owns the specified range.
        ///
        /// - Returns: the input range minus the characters that represent the implicit paragraph
        ///     separator.
        ///
        private func ensureRemovalOfOpeningParagraphSeparators(for element: ElementNode, ifFoundIn range: NSRange) -> NSRange {

            // Since some elements have an implicit paragraph separator at their end, we need
            // to merge them right, whenever the separator is removed.
            //
            guard let separatorRange = inspector.rangeOfOpeningParagraphSeparator(for: element),
                range.contains(separatorRange) else {
                    return range
            }

            mergeLeft(element)

            // After merging the node right, we also need to shorten the range of characters
            // to delete, since the implicit paragraph separator has been removed
            // succesfully.
            //
            return range.shortenedLeft(by: separatorRange.length)
        }

        /// Ensures that the paragraph separators will be deleted if the specified element has them,
        /// and the specified range intersects it.
        ///
        /// - Parameters:
        ///     - range: the range for the deletion operation.
        ///     - element: the element node that owns the specified range.
        ///
        /// - Returns: the input range minus the characters that represent the implicit paragraph
        ///     separator.
        ///
        private func ensureRemovalOfParagraphSeparators(for element: ElementNode, ifFoundIn range: NSRange) -> NSRange {

            let updatedRange = ensureRemovalOfOpeningParagraphSeparators(for: element, ifFoundIn: range)

            return ensureRemovalOfClosingParagraphSeparators(for: element, ifFoundIn: updatedRange)
        }

        private func removeParagraphSeparators(from range: NSRange, in element: ElementNode) -> NSRange {
            var modifiedRange = range

            if let separatorRange = inspector.rangeOfOpeningParagraphSeparator(for: element),
                modifiedRange.contains(separatorRange) {

                modifiedRange = modifiedRange.shortenedLeft(by: separatorRange.length)
            }

            if let separatorRange = inspector.rangeOfClosingParagraphSeparator(for: element),
                modifiedRange.contains(separatorRange) {

                modifiedRange = modifiedRange.shortenedRight(by: separatorRange.length)
            }

            return modifiedRange
        }

        // MARK: - Replacing Characters

        /// Replaces the characters in the specified range with the specified string.
        ///
        /// - Parameters:
        ///     - range: the range of the characters to replace.
        ///     - string: the string to replace the range with.
        ///
        func replace(_ range: NSRange, with string: String) {
            if range.length > 0 {
                deleteCharacters(spanning: range)
            }

            if string.characters.count > 0 {
                insert(string, atLocation: range.location)
            }
        }

        func replace(_ range: NSRange, with attributedString: NSAttributedString) {
            if range.length > 0 {
                deleteCharacters(spanning: range)
            }

            if attributedString.length > 0 {
                insert(attributedString, atLocation: range.location)
            }
        }

        func replace(_ range: NSRange, with node: Node) {
            if range.length > 0 {
                deleteCharacters(spanning: range)
            }

            let (element, intersection) = inspector.findLeftmostLowestDescendantElement(of: rootNode, intersecting: range.location)

            insertChild(node, in: element, atOffset: intersection)
        }


        // MARK: - Removing Nodes

        private func remove(child: Node, from parent: ElementNode) {

            let childIndex = parent.indexOf(childNode: child)

            parent.children.remove(at: childIndex)
            child.parent = nil
        }

        private func removeFromParent(_ node: Node) {
            let parent = inspector.parent(of: node)

            remove(child: node, from: parent)
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
        private func createNodes(representing string: String) -> [Node] {
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

            for (matchElement, matchRange) in elementsAndRanges.reversed() {

                // We don't allow wrapping empty ranges.
                //
                guard matchRange.length > 0 else {
                    continue
                }

                guard inspector.range(of: matchElement) != matchRange
                    || matchElement is RootNode
                    || inspector.isBlockLevelElement(matchElement) else {

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

            insertChild(element, in: parent, at: index)
        }

        private func wrapChildren(of element: ElementNode, spanning range: NSRange, in elementDescriptor: ElementNodeDescriptor) {

            assert(inspector.range(of: element).contains(range))
            assert(range.length > 0)
            assert(!elementDescriptor.isBlockLevel()
                || element is RootNode
                || inspector.isBlockLevelElement(element))

            let nodesToWrap: [Node]

            if inspector.range(of: element) == range {
                nodesToWrap = element.children
            } else {
                let (_, centerNodes, _) = splitChildren(of: element, for: range)

                nodesToWrap = centerNodes
            }

            wrapChildren(nodesToWrap, of: element, inElement: elementDescriptor)
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

            let bailEvaluation = { [unowned self] (node: ElementNode) -> Bool in
                return self.inspector.isBlockLevelElement(node)
            }

            // First get the right sibling because if we do it the other round, lastNodeIndex will
            // be modified before we access it.
            //
            let rightSibling = elementDescriptor.canMergeRight ? pushUp(siblingOrDescendantAtRightSideOf: lastNodeIndex, in: element, evaluatedBy: evaluation, bailIf: bailEvaluation) : nil
            let leftSibling = elementDescriptor.canMergeLeft ? pushUp(siblingOrDescendantAtLeftSideOf: firstNodeIndex, in: element, evaluatedBy: evaluation, bailIf: bailEvaluation) : nil

            var wrapperElement: ElementNode?

            if let sibling = rightSibling {
                insertChildren(childrenToWrap, in: sibling, at: 0)
                childrenToWrap = sibling.children

                wrapperElement = sibling
            }

            if let sibling = leftSibling {
                insertChildren(childrenToWrap, in: sibling, at: sibling.children.count)
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
                wrapChildren(selectedChildren, of: finalWrapper, inElement: childElementDescriptor)
            }
            
            return finalWrapper
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

            let initialRange = removeParagraphSeparators(from: range, in: element)
            var result = unwrapDescendants(of: element, spanning: initialRange, fromElementsNamed: elementNames)

            if elementNames.contains(element.name) {
                result = unwrapChildren(of: element, spanning: result)
            }

            return result
        }

        private func unwrapChildren(of element: ElementNode) -> NSRange {

            let parent = inspector.parent(of: element)
            let index = parent.indexOf(childNode: element)

            let children = element.children

            remove(child: element, from: parent)

            for child in children.reversed() {
                insertChild(child, in: parent, at: index)
            }

            var finalRange = NSRange.zero

            // It's important to calculate the new range only after ALL nodes have been repositioned
            // as the opening and closing paragraph separators can affect the node lengths.
            //
            for child in children {
                finalRange = finalRange.extendedRight(by: inspector.length(of: child))
            }

            return finalRange
        }

        private func unwrapChildren(of element: ElementNode, spanning range: NSRange) -> NSRange {

            // The input range should already have the paragraph separators removed.
            //
            assert(range == removeParagraphSeparators(from: range, in: element))

            // The following two guards' order is important.  Before checking if the range
            // is empty, we should still check if this node must be removed.
            //
            guard range != inspector.contentRange(of: element) else {
                return unwrapChildren(of: element)
            }

            guard range.length > 0 else {
                return range
            }

            let (_, center, _) = split(element, for: range)

            return unwrapChildren(of: center)
        }

        /// Unwraps all descendant nodes from elements with the specified names.
        ///
        /// - Parameters:
        ///     - element: the element containing the specified range.
        ///     - range: the range we want to unwrap.
        ///     - elementNames: the name of the elements we want to unwrap the nodes from.
        ///
        /// - Returns: the provided range after the unwrapping (since it may be modified by newlines
        ///     being added).
        ///
        func unwrapDescendants(of element: ElementNode, spanning range: NSRange, fromElementsNamed elementNames: [String]) -> NSRange {

            // The input range should already have the paragraph separators removed.
            //
            assert(range == removeParagraphSeparators(from: range, in: element))

            guard element.children.count > 0 else {
                return range
            }

            let childNodesAndRanges = inspector.findChildren(of: element, spanning: range)
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

        // MARK: - Splitting Nodes: At Offset

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
        @discardableResult
        func split(_ node: Node, at offset: Int) -> (left: Node, right: Node) {

            if let textNode = node as? TextNode {
                return split(textNode, at: offset)
            } else if let element = node as? ElementNode {
                let (left, right) = split(element, at: offset)
                return (left, right)
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
        @discardableResult
        func split(_ element: ElementNode, at offset: Int) -> (left: ElementNode, right: ElementNode) {

            let parent = inspector.parent(of: element)

            let (leftChildren, rightChildren) = splitChildren(of: element, at: offset)

            let leftElement = ElementNode(name: element.name, attributes: element.attributes, children: leftChildren)
            let rightElement = ElementNode(name: element.name, attributes: element.attributes, children: rightChildren)

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
        func split(_ textNode: TextNode, at offset: Int) -> (left: Node, right: Node) {

            let parent = inspector.parent(of: textNode)
            let text = inspector.text(for: textNode)

            let leftRange = NSRange(location: 0, length: offset)
            let rightRange = NSRange(location: offset, length: text.characters.count - offset)

            let leftSwiftRange = text.range(from: leftRange)
            let rightSwiftRange = text.range(from: rightRange)

            let leftNode = TextNode(text: text.substring(with: leftSwiftRange))
            let rightNode = TextNode(text: text.substring(with: rightSwiftRange))

            parent.replace(child: textNode, with: [leftNode, rightNode])

            return (leftNode, rightNode)
        }

        func split(_ element: ElementNode, for range: NSRange) -> (left: ElementNode?, center: ElementNode, right: ElementNode?) {

            assert(range.length > 0)
            assert(inspector.range(of: element).contains(range))

            let rangeEndLocation = range.location + range.length
            let elementLength = inspector.length(of: element)

            var left: ElementNode? = nil
            var center: ElementNode = element
            var right: ElementNode? = nil

            if range.location > 0  {
                let (splitLeft, splitRight) = split(element, at: range.location)

                left = splitLeft
                center = splitRight
            }

            if rangeEndLocation < elementLength {
                let (splitLeft, splitRight) = split(center, at: rangeEndLocation)

                center = splitLeft
                right = splitRight
            }

            return (left, center, right)
        }

        // MARK: - Splitting Nodes: Children

        func split(_ element: ElementNode, around child: Node) -> (left: ElementNode?, center: ElementNode, right: ElementNode?) {

            assert(element.children.count > 1)
            assert(element.children.contains(child))

            let parent = inspector.parent(of: element)
            let elementIndex = parent.indexOf(childNode: element)
            let childIndex = element.indexOf(childNode: child)

            let left: ElementNode?
            let right: ElementNode?

            if childIndex < element.children.count - 1 {
                let children = element.children.subArray(from: childIndex + 1, through: element.children.count - 1)

                let newElement = ElementNode(name: element.name, attributes: element.attributes, children: children)
                insertChild(newElement, in: parent, at: elementIndex + 1)

                right = newElement
            } else {
                right = nil
            }

            if childIndex > 0 {
                let children = element.children.subArray(from: 0, through: childIndex)

                let newElement = ElementNode(name: element.name, attributes: element.attributes, children: children)
                insertChild(newElement, in: parent, at: elementIndex)

                left = newElement
            } else {
                left = right
            }

            return (left, element, right)
        }

        /// Splits the child at the specified offset.
        ///
        /// - Parameters:
        ///     - element: the reference element.  This is the parent to the node that will be split.
        ///     - offset: the offset for the split.  Can be at a child's edge coordinates.
        ///
        /// - Returns: the left and right nodes after the split.  If the offset falls at the
        ///         beginning of a child node, no split will occur and this method will return
        ///         `(inspector.leftSibling(of: node), node)`.  If the offset falls at the end of a
        ///         child node, no split will occur and this method will return
        ///         `(node, inspector.rightSibling(of: node))`.
        ///
        func splitChild(of element: ElementNode, at offset: Int) -> (left: Node?, right: Node?) {

            guard let (child, intersection) = inspector.findLeftmostChild(of: element, intersecting: offset) else {
                fatalError("Cannot split the children of an element that has no children.")
            }

            guard intersection != 0 else {
                return (inspector.leftSibling(of: child), child)
            }

            guard intersection != inspector.length(of: child) else {
                return (child, inspector.rightSibling(of: child))
            }

            let (leftNode, rightNode) = split(child, at: intersection)

            return (leftNode, rightNode)
        }

        /// Splits the children of the reference node, using a range as reference.
        ///
        ///
        func splitChildren(of element: ElementNode, for range: NSRange) -> (left: [Node], center: [Node], right: [Node]) {

            assert(element.children.count > 0)
            assert(inspector.range(of: element).contains(range))
            assert(range.length > 0)

            let elementRange = inspector.range(of: element)
            let splitRangeEndLocation = range.location + range.length
            let elementRangeEndLocation = elementRange.location + elementRange.length

            var leftNodes = [Node]()
            var rightNodes = [Node]()

            let centerNodesStartIndex: Int
            let centerNodesEndIndex: Int

            if range.location == 0 {
                centerNodesStartIndex = 0
            } else {
                let (leftNode, rightNode) = splitChild(of: element, at: range.location)

                if let leftNode = leftNode {
                    leftNodes = inspector.findLeftSiblings(of: leftNode, includingReferenceNode: true)
                }

                // Since the split range can't be zero, the right node in split1 cannot be nil.
                //
                centerNodesStartIndex = element.indexOf(childNode: rightNode!)
            }

            if splitRangeEndLocation == elementRangeEndLocation {
                centerNodesEndIndex = element.children.count - 1
            } else {
                let (leftNode, rightNode) = splitChild(of: element, at: splitRangeEndLocation)

                if let rightNode = rightNode {
                    rightNodes = inspector.findRightSiblings(of: rightNode, includingReferenceNode: true)
                }

                // Since the split range can't be zero, the right node in split1 cannot be nil.
                //
                centerNodesEndIndex = element.indexOf(childNode: leftNode!)
            }

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
        @discardableResult
        func splitChildren(of element: ElementNode, at offset: Int) -> (left: [Node], right: [Node]) {

            assert(inspector.range(of: element).contains(offset: offset))

            guard let (child, intersection) = inspector.findLeftmostChild(of: element, intersecting: offset) else {
                fatalError("This should not happen.  Review the logic.")
            }

            guard canSplit(child, atOffset: intersection) else {
                return siblingsForAvoidedSplit(of: child, atOffset: intersection)
            }

            let (leftNode, rightNode) = split(child, at: intersection)

            let leftNodes = inspector.findLeftSiblings(of: leftNode, includingReferenceNode: true)
            let rightNodes = inspector.findRightSiblings(of: rightNode, includingReferenceNode: true)

            return (leftNodes, rightNodes)
        }

        // MARK: - Splitting Nodes: Using Characters

        /// Splits the reference node at each instance of the specified string.
        ///
        /// - Parameters:
        ///     - node: the reference node.
        ///     - string: the string that will be used to split the reference node.  Each occurrence
        ///             of this string will be removed as part of the split operation.
        ///
        func split(_ node: Node, at string: String) {

            let ranges = inspector.find(string, in: node)

            for range in ranges.reversed() {
                deleteCharacters(in: node, spanning: range)
                split(node, at: range.location)
            }
        }

        // MARK: - Splitting Support Methods

        private func canSplit(_ node: Node, atOffset offset: Int) -> Bool {
            if let childElement = node as? ElementNode,
                inspector.isBlockLevelElement(childElement) {

                let contentRange = inspector.contentRange(of: childElement)

                return offset >= contentRange.location && offset < contentRange.location + contentRange.length
            } else {
                return offset > 0 && offset < inspector.length(of: node)
            }
        }

        private func siblingsForAvoidedSplit(of node: Node, atOffset offset: Int) -> (left: [Node], right: [Node]) {

            let includeInRightGroup = offset == 0

            let leftNodes = inspector.findLeftSiblings(of: node, includingReferenceNode: !includeInRightGroup)
            let rightNodes = inspector.findRightSiblings(of: node, includingReferenceNode: includeInRightGroup)

            return (leftNodes, rightNodes)
        }

        // MARK: - Pusing Up Nodes

        /// Pushes the receiver up in the DOM structure, by wrapping an exact copy of the parent
        /// node, inserting all the receiver's children to it, and adding the receiver to its
        /// grandparent node.
        ///
        /// The result is that the order of the receiver and its parent node will be inverted.
        ///
        private func swapWithParent(_ element: ElementNode) {

            let initialParent = inspector.parent(of: element)
            let grandParent = inspector.parent(of: initialParent)

            let parent: ElementNode

            if initialParent.children.count > 1 {
                let (_, center, _) = split(initialParent, around: element)

                parent = center
            } else {
                parent = initialParent
            }

            let elementIndex = parent.indexOf(childNode: element)
            let parentIndex = grandParent.indexOf(childNode: parent)

            insertChildren(element.children, in: parent, at: elementIndex)
            insertChild(element, in: grandParent, at: parentIndex)
            insertChild(parent, in: element, at: 0)
        }

        /// Evaluates the left sibling for a certain condition.  If the condition is met, the
        /// sibling is returned.  Otherwise this method looks amongst the sibling's right-side
        /// descendants for any node returning `true` at the evaluation closure.
        ///
        /// The search bails if the bail closure returns `true` for either the sibling or its
        /// descendants before a matching node is found.
        ///
        /// When a match is found, it's pushed up to the level of the receiver.
        ///
        /// - Parameters:
        ///     - childIndex: the index of the child to find the sibling of.
        ///     - evaluation: the closure that will evaluate the nodes for a matching result.
        ///     - bail: the closure to evaluate if the search must bail.
        ///
        /// - Returns: The requested node, if one is found, or `nil`.
        ///
        func pushUp<T: Node>(siblingOrDescendantAtLeftSideOf childIndex: Int, in element: ElementNode, evaluatedBy evaluation: ((T) -> Bool), bailIf bail: ((T) -> Bool) = { _ in return false }) -> T? {

            guard let theSibling: T = inspector.sibling(leftOf: childIndex, in: element) else {
                return nil
            }

            if evaluation(theSibling) {
                return theSibling
            }

            guard !bail(theSibling),
                let childElement = theSibling as? ElementNode else {
                    return nil
            }

            return pushUp(in: childElement, rightSideDescendantEvaluatedBy: evaluation, bailIf: bail)
        }

        /// Pushes up to the level of the receiver any left-side descendant that evaluates
        /// to `true`.
        ///
        /// - Parameters:
        ///     - evaluationClosure: the closure that will be used to evaluate all descendants.
        ///     - bail: the closure that will be used to evaluate if the descendant search must
        ///             bail.
        ///
        /// - Returns: if any matching descendant is found, this method will return the requested
        ///         node after being pushed all the way up, or `nil` if no matching descendant is
        ///         found.
        ///
        func pushUp<T: Node>(in element: ElementNode, leftSideDescendantEvaluatedBy evaluationClosure: ((T) -> Bool), bailIf bail: ((T) -> Bool) = { _ in return false }) -> T? {

            guard let node = element.find(leftSideDescendantEvaluatedBy: evaluationClosure, bailIf: bail),
                let childElement = node as? ElementNode else {
                    return nil
            }

            let finalParent = inspector.parent(of: element)

            while childElement.parent != nil && childElement.parent != finalParent {
                swapWithParent(childElement)
            }

            return node
        }

        /// Evaluates the right sibling for a certain condition.  If the condition is met, the
        /// sibling is returned.  Otherwise this method looks amongst the sibling's left-side
        /// descendants for any node returning `true` at the evaluation closure.
        ///
        /// The search bails if the bail closure returns `true` for either the sibling or its
        /// descendants before a matching node is found.
        ///
        /// When a match is found, it's pushed up to the level of the receiver.
        ///
        /// - Parameters:
        ///     - childIndex: the index of the child to find the sibling of.
        ///     - evaluation: the closure that will evaluate the nodes for a matching result.
        ///     - bail: the closure to evaluate if the search must bail.
        ///
        /// - Returns: The requested node, if one is found, or `nil`.
        ///
        func pushUp<T: Node>(siblingOrDescendantAtRightSideOf childIndex: Int, in element: ElementNode, evaluatedBy evaluation: ((T) -> Bool), bailIf bail: ((T) -> Bool) = { _ in return false }) -> T? {

            guard let theSibling: T = inspector.sibling(rightOf: childIndex, in: element) else {
                return nil
            }

            if evaluation(theSibling) {
                return theSibling
            }

            guard !bail(theSibling),
                let childElement = theSibling as? ElementNode else {
                    return nil
            }

            return pushUp(in: childElement, leftSideDescendantEvaluatedBy: evaluation, bailIf: bail)
        }

        /// Pushes up to the level of the receiver any right-side descendant that evaluates
        /// to `true`.
        ///
        /// - Parameters:
        ///     - evaluationClosure: the closure that will be used to evaluate all descendants.
        ///     - bail: the closure that will be used to evaluate if the descendant search must
        ///             bail.
        ///
        /// - Returns: if any matching descendant is found, this method will return the requested
        ///         node after being pushed all the way up, or `nil` if no matching descendant is
        ///         found.
        ///
        func pushUp<T: Node>(in element: ElementNode, rightSideDescendantEvaluatedBy evaluationClosure: ((T) -> Bool), bailIf bail: ((T) -> Bool) = { _ in return false }) -> T? {

            guard let node = element.find(rightSideDescendantEvaluatedBy: evaluationClosure, bailIf: bail),
                let childElement = node as? ElementNode else {
                    return nil
            }

            let finalParent = inspector.parent(of: element)
            
            while childElement.parent != nil && childElement.parent != finalParent {
                swapWithParent(childElement)
            }
            
            return node
        }

        // MARK: - Merging Nodes

        /// Merges the specified block-level element with the sibling(s) to its right.
        ///
        /// - Note: Block-level elements are rendered on their own line, meaning a newline is added
        ///         even though it's not part of the contents of any node.  This method implements
        ///         the logic that's executed when such visual-only newline is removed.
        ///
        /// - Parameters:
        ///     - node: the node we're merging to the right.
        ///
        private func mergeLeft(_ node: Node) {

            guard let leftNode = inspector.findFirstNodeBefore(node) else {
                return
            }

            mergeRight(leftNode)
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

            if let element = node as? ElementNode {
                defragChildren(of: element)
            }
        }

        private func merge(_ node: Node, withRightNodes rightNodes: [Node]) {

            guard let element = node as? ElementNode else {
                guard let parent = node.parent else {
                    fatalError("This method should not be called for a node without a parent set.")
                }

                let insertionIndex = parent.indexOf(childNode: node) + 1

                for (index, child) in rightNodes.enumerated() {
                    insertChild(child, in: parent, at: insertionIndex + index)
                }

                return
            }

            if element.children.count > 0,
                let lastChildElement = element.children[element.children.count - 1] as? ElementNode,
                inspector.isBlockLevelElement(lastChildElement) {

                merge(lastChildElement, withRightNodes: rightNodes)
                return
            }

            if element.standardName == .ul || element.standardName == .ol {
                let newListItem = ElementNode(name: StandardElementType.li.rawValue, attributes: [], children: rightNodes)
                appendChild(newListItem, to: element)
                return
            }

            appendChildren(rightNodes, to: element)
        }

        private func extractRightNodesForMerging(after node: Node) -> [Node] {

            guard let firstNode = inspector.findFirstNodeAfter(node) else {
                return []
            }

            let parent = inspector.parent(of: firstNode)
            let index = parent.indexOf(childNode: firstNode)

            return extractNodesForMerging(from: parent, startingAt: index)
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
                    if inspector.isBlockLevelElement(element) {
                        if nodes.count == 0 {
                            nodes = extractNodesForMerging(from: element, startingAt: 0)
                        }

                        break
                    } else if element.standardName == .br  {
                        element.removeFromParent()
                        break
                    }
                }

                remove(child: currentNode, from: parent)
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

        // MARK: - Node Fragmentation

        /// At this time this method only defragments children-text nodes, and is not recursive.
        /// This behaviour may change.
        ///
        /// - Parameters:
        ///     - element: the reference element that will be defragmented.
        ///
        func defragChildren(of element: ElementNode) {
            for child in element.children {
                let index = element.indexOf(childNode: child)
                let nextIndex = index + 1

                if nextIndex < element.children.count,
                    let currentTextNode = child as? TextNode,
                    let nextTextNode = element.children[nextIndex] as? TextNode {

                    nextTextNode.contents = currentTextNode.contents + nextTextNode.contents
                    remove(child: currentTextNode, from: element)
                }
            }
        }
    }
}
