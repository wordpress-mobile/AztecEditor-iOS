import Foundation
import libxml2


extension Libxml2 {

    /// Groups all the DOM editing logic.
    ///
    class DOMEditor: DOMLogic {

        enum ParagraphStyle {
            case blockquote
            case paragraph
            case orderedList
            case unorderedList
            case header1
            case header2
            case header3
            case header4
            case header5
            case header6
            case horizontalRule
            case preformatted

            func toNode(children: [Node]) -> ElementNode {
                switch self {
                case .blockquote:
                    return ElementNode(type: .blockquote, children: children)
                case .orderedList:
                    return ElementNode(type: .ol, children: children)
                case .paragraph:
                    return ElementNode(type: .p, children: children)
                case .unorderedList:
                    return ElementNode(type: .ul, children: children)
                case .header1:
                    return ElementNode(type: .h1, children: children)
                case .header2:
                    return ElementNode(type: .h2, children: children)
                case .header3:
                    return ElementNode(type: .h3, children: children)
                case .header4:
                    return ElementNode(type: .h4, children: children)
                case .header5:
                    return ElementNode(type: .h5, children: children)
                case .header6:
                    return ElementNode(type: .h6, children: children)
                case .horizontalRule:
                    return ElementNode(type: .hr, children: children)
                case .preformatted:
                    return ElementNode(type: .pre, children: children)
                }
            }
        }

        enum Style {
            case anchor(url: String)
            case bold
            case italics
            case image(url: String)
            case strike
            case underlined

            func toNode(children: [Node]) -> ElementNode {
                switch self {
                case .anchor(let url):
                    let source = StringAttribute(name: "src", value: url)
                    return ElementNode(type: .a, attributes: [source])
                case .bold:
                    return ElementNode(type: .b)
                case .italics:
                    return ElementNode(type: .i)
                case .image(let url):
                    let source = StringAttribute(name: "src", value: url)
                    return ElementNode(type: .img, attributes: [source])
                case .strike:
                    return ElementNode(type: .strike)
                case .underlined:
                    return ElementNode(type: .u)
                }
            }
        }

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

        ///
        ///
        func insert(
            _ string: String,
            at location: Int,
            paragraphStyles: [ParagraphStyle],
            styles: [Style],
            canMergeLeft: Bool,
            canMergeRight: Bool) {

            let textNode = TextNode(text: string)

            let stylesRoot = styles.reversed().reduce(textNode as Node) { (result, style) -> Node in
                return style.toNode(children: [result])
            }

            let paragraphStylesRoot = paragraphStyles.reversed().reduce(stylesRoot) { (result, style) in
                return style.toNode(children: [result])
            }

            let split = splitChild(of: rootNode, at: location)

            if let leftNode = split.left {
                insertChild(paragraphStylesRoot, in: rootNode, after: leftNode)
            } else if let rightNode = split.right {
                insertChild(paragraphStylesRoot, in: rootNode, before: rightNode)
            } else {
                fatalError("This should not be possible.  Review the logic!")
            }
        }


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

                guard index != paragraphs.count - 1 else {
                    insert(rawString: paragraph, into: currentElement, atLocation: currentLocation)
                    continue
                }

                insert(paragraph: paragraph, into: currentElement, atLocation: currentLocation)

                currentElement = inspector.rightSibling(of: insertionElement) as! ElementNode
                currentLocation = currentLocation + 1
            }
        }

        // MARK: - Inserting Nodes

        private func insertChild(_ node: Node, in element: ElementNode, at index: Int) {
            element.children.insert(node, at: index)
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
        /// - Parameters:
        ///     - element: the `ElementNode` containing the character-range so delete.
        ///     - range: the range of text to delete.
        ///
        private func deleteCharacters(in element: ElementNode, spanning range: NSRange) {

            assert(!(element is RootNode))
            assert(element.range().contains(range))
            assert(range.length > 0)

            if range.location == 0 && range.length == element.length() {
                element.removeFromParent()
            } else {
                let rangeForChildren = inspector.mapToChildren(range: range, of: element)
                let childrenAndIntersections = inspector.findChildren(of: element, spanning: rangeForChildren)

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

            assert(textNode.range().contains(range))
            assert(range.length > 0)

            textNode.deleteCharacters(inRange: range)
        }

        /// Deletes the characters in the specified `RootNode` spanning the specified range.
        ///
        /// - Parameters:
        ///     - rootNode: the `RootNode` containing the character-range so delete.
        ///     - range: the range of text to delete.
        ///
        private func deleteCharacters(in rootNode: RootNode, spanning range: NSRange) {

            assert(rootNode.range().contains(range))
            assert(range.length > 0)

            let childrenAndIntersections = inspector.findChildren(of: rootNode, spanning: range)

            for (child, intersection) in childrenAndIntersections {
                deleteCharacters(in: child, spanning: intersection)
            }
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

        /// Replaces
        ///
        func replaceCharacters(in range: NSRange,
                               with string: String,
                               paragraphStyles: [ParagraphStyle],
                               styles: [Style],
                               canMergeLeft: Bool,
                               canMergeRight: Bool) {
            if range.length > 0 {
                deleteCharacters(spanning: range)
            }

            if string.characters.count > 0 {
                insert(
                    string,
                    at: range.location,
                    paragraphStyles: paragraphStyles,
                    styles: styles,
                    canMergeLeft: canMergeLeft,
                    canMergeRight: canMergeRight)
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

            assert(element.range().contains(range))
            assert(range.length > 0)
            assert(!elementDescriptor.isBlockLevel()
                || element is RootNode
                || element.isBlockLevelElement())

            let nodesToWrap: [Node]

            if element.range() == range {
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

            if finalWrapper.isBlockLevelElement() {
                split(finalWrapper, at: String(.paragraphSeparator))
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

        // MARK: - Splitting Nodes: Ranges and Offsets

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
        func split(_ textNode: TextNode, at offset: Int) -> (left: Node, right: Node) {

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

        // MARK: - Splitting Nodes: Nodes

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

            assert(element.children.count > 0)
            assert(element.range().contains(range))
            assert(range.length > 0)

            let elementRange = element.range()
            let splitRangeEndLocation = range.location + range.length
            let elementRangeEndLocation = elementRange.location + elementRange.length

            var leftNodes = [Node]()
            var rightNodes = [Node]()

            var centerNodesStartIndex = 0
            var centerNodesEndIndex = element.children.count - 1

            if range.location != 0 {
                let (leftNode, rightNode) = splitChild(of: element, at: range.location)

                if let leftNode = leftNode {
                    leftNodes = inspector.findLeftSiblings(of: leftNode, includingReferenceNode: true)
                }

                // Since the split range can't be zero, the right node in split1 cannot be nil.
                //
                centerNodesStartIndex = element.indexOf(childNode: rightNode!)
            }

            if splitRangeEndLocation != elementRangeEndLocation {
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
