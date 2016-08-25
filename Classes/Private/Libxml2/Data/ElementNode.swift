import Foundation

extension Libxml2 {

    /// Element node.  Everything but text basically.
    ///
    class ElementNode: Node {

        /// This enum provides a list of HTML5 standard element names.  The reason why this isn't
        /// used as the `name` property of `ElementNode` is that element nodes could theoretically
        /// have non-standard names.
        ///
        enum StandardName: String {
            case A = "a"
            case Address = "address"
            case B = "b"
            case Blockquote = "blockquote"
            case Dd = "dd"
            case Del = "del"
            case Div = "div"
            case Dl = "dl"
            case Dt = "dt"
            case Em = "em"
            case Fieldset = "fieldset"
            case Form = "form"
            case H1 = "h1"
            case H2 = "h2"
            case H3 = "h3"
            case H4 = "h4"
            case H5 = "h5"
            case H6 = "h6"
            case Hr = "hr"
            case I = "i"
            case Li = "li"
            case Noscript = "noscript"
            case Ol = "ol"
            case P = "p"
            case Pre = "pre"
            case S = "s"
            case Strike = "strike"
            case Strong = "strong"
            case Table = "table"
            case Tbody = "tbody"
            case Td = "td"
            case Tfoot = "tfoot"
            case Th = "th"
            case Thead = "thead"
            case Tr = "tr"
            case U = "u"
            case Ul = "ul"

            /// Returns an array with all block-level elements.
            ///
            static func blockLevelNodeNames() -> [StandardName] {
                return [.Address, .Blockquote, .Div, .Dl, .Fieldset, .Form, .H1, .H2, .H3, .H4, .H5, .H6, .Hr, .Noscript, .Ol, .P, .Pre, .Table, .Ul]
            }
        }

        private(set) var attributes = [Attribute]()
        private(set) var children: [Node]

        private var standardName: StandardName? {
            get {
                return StandardName(rawValue: name)
            }
        }

        init(name: String, attributes: [Attribute], children: [Node]) {
            self.children = children
            self.attributes.appendContentsOf(attributes)

            super.init(name: name)

            for child in children {
                child.parent = self
            }
        }

        override func customMirror() -> Mirror {
            return Mirror(self, children: ["type": "element", "name": name, "parent": parent.debugDescription, "attributes": attributes, "children": children], ancestorRepresentation: .Suppressed)
        }

        // MARK: - Node Queries

        /// Node length.  Calculated by adding the length of all child nodes.
        ///
        override func length() -> Int {

            var length = 0

            for child in children {
                length += child.length()
            }

            return length
        }

        /// Find out if this is a block-level element.
        ///
        /// - Returns: `true` if this is a block-level element.  `false` otherwise.
        ///
        func isBlockLevelElement() -> Bool {

            guard let standardName = standardName else {
                // For now we're treating all non-standard element names as non-block-level
                // elements.
                //
                return false
            }

            return StandardName.blockLevelNodeNames().contains(standardName)
        }

        // MARK: - DOM Queries

        /// Get a list of child nodes intersecting the specified range.
        ///
        /// - Parameters:
        ///     - targetRange: the range we're intersecting the child nodes with.  The range is in
        ///             this node's coordinates (the parent node's coordinates, from the children
        ///             PoV).
        ///
        /// - Returns: an array of pairs of child nodes and their ranges in child coordinates.
        ///
        func childNodes(intersectingRange targetRange: NSRange) -> [(child: Node, intersection: NSRange)] {
            var results = [(child: Node, intersection: NSRange)]()

            enumerateChildNodes(intersectingRange: targetRange) { (child, intersection) in
                results.append((child, intersection))
            }

            return results
        }

        /// Enumerate the child nodes intersecting the specified range.
        ///
        /// - Parameters:
        ///     - targetRange: the range we're intersecting the child nodes with.  The range is in
        ///             this node's coordinates (the parent node's coordinates, from the children
        ///             PoV).
        ///     - matchFound: the closure to execute for each child node intersecting
        ///             `targetRange`.
        ///
        /// - Returns: an array of child nodes and their intersection.  The intersection range is in
        ///         child coordinates.
        ///
        func enumerateChildNodes(intersectingRange targetRange: NSRange, onMatchFound matchFound: (child: Node, intersection: NSRange) -> Void ) {

            var offset = Int(0)

            for child in children {

                let childLength = child.length()
                let childRange = NSRange(location: offset, length: childLength)
                let intersectionRange = NSIntersectionRange(childRange, targetRange)
                let childRangeInterceptsTargetRange = (intersectionRange.length > 0)

                if childRangeInterceptsTargetRange {

                    let intersectionRangeInChildCoordinates = NSRange(location: intersectionRange.location - offset, length: intersectionRange.length)

                    matchFound(child: child, intersection: intersectionRangeInChildCoordinates)
                }

                offset += childLength
            }
        }

        func lowestBlockLevelElements(intersectingRange targetRange: NSRange) -> [(element: ElementNode, intersection: NSRange)] {
            var results = [(element: ElementNode, intersection: NSRange)]()

            enumerateLowestBlockLevelElements(intersectingRange: targetRange) { result in
                results.append(result)
            }

            return results
        }

        /// Enumerate the lowest block-level child elements intersecting the specified range.
        /// Whenever a range doesn't intersect a block-level node, `self` (the receiver) is returned
        /// as the owner of that range.
        ///
        /// - Parameters:
        ///     - targetRange: the range we're intersecting the child nodes with.  The range is in
        ///             this node's coordinates (the parent node's coordinates, from the children
        ///             PoV).
        ///     - matchFound: the closure to execute for each child element intersecting
        ///             `targetRange`.
        ///
        /// - Returns: an array of child nodes and their intersection.  The intersection range is in
        ///         child coordinates.
        ///
        func enumerateLowestBlockLevelElements(intersectingRange targetRange: NSRange, onMatchFound matchFound: (element: ElementNode, intersection: NSRange) -> Void ) {

            enumerateLowestBlockLevelElements(
                intersectingRange: targetRange,
                onMatchNotFound: { (range) in
                    matchFound(element: self, intersection: range)
                },
                onMatchFound: matchFound)
        }

        /// Enumerate the child elements intersecting the specified range.
        ///
        /// - Parameters:
        ///     - targetRange: the range we're intersecting the child nodes with.  The range is in
        ///             this node's coordinates (the parent node's coordinates, from the children
        ///             PoV).
        ///     - matchNotFound: the closure to execute for any subrange of `targetRange` that
        ///             doesn't have a block-level node intersecting it.
        ///     - matchFound: the closure to execute for each child element intersecting
        ///             `targetRange`.
        ///
        /// - Returns: an array of child nodes and their intersection.  The intersection range is in
        ///         child coordinates.
        ///
        private func enumerateLowestBlockLevelElements(intersectingRange targetRange: NSRange, onMatchNotFound matchNotFound: (range: NSRange) -> Void, onMatchFound matchFound: (element: ElementNode, intersection: NSRange) -> Void ) {

            var rangeWithoutMatch: NSRange?
            var offset = Int(0)

            for child in children {

                let childLength = child.length()
                let childRange = NSRange(location: offset, length: childLength)
                let intersectionRange = NSIntersectionRange(childRange, targetRange)
                let childIntercectsTargetRange = (intersectionRange.length > 0)

                if childIntercectsTargetRange {

                    let intersectionRangeInChildCoordinates = NSRange(location: intersectionRange.location - offset, length: intersectionRange.length)

                    if let childElement = child as? ElementNode {
                        childElement.enumerateLowestBlockLevelElements(
                            intersectingRange: intersectionRangeInChildCoordinates,
                            onMatchNotFound: { (range) in

                                if let previousRangeWithoutMatch = rangeWithoutMatch {
                                    rangeWithoutMatch = NSRange(location: previousRangeWithoutMatch.location, length: previousRangeWithoutMatch.length + range.length)
                                } else {
                                    rangeWithoutMatch = range
                                }
                            },
                            onMatchFound: { [weak self] (child, intersection) in

                                guard let strongSelf = self else {
                                    return
                                }

                                if let previousRangeWithoutMatch = rangeWithoutMatch {
                                    if strongSelf.isBlockLevelElement() {
                                        matchFound(element: strongSelf, intersection: previousRangeWithoutMatch)
                                        rangeWithoutMatch = nil
                                    } else {
                                        matchNotFound(range: previousRangeWithoutMatch)
                                    }
                                }

                                matchFound(element: child, intersection: intersection)
                        })
                    } else {
                        if let previousRangeWithoutMatch = rangeWithoutMatch {
                            rangeWithoutMatch = NSRange(location: previousRangeWithoutMatch.location, length: previousRangeWithoutMatch.length + intersectionRangeInChildCoordinates.length)
                        } else {
                            rangeWithoutMatch = intersectionRange

                        }
                    }
                }

                offset += childLength
            }

            if let previousRangeWithoutMatch = rangeWithoutMatch {
                if isBlockLevelElement() {
                    matchFound(element: self, intersection: previousRangeWithoutMatch)
                    rangeWithoutMatch = nil
                } else {
                    matchNotFound(range: previousRangeWithoutMatch)
                }
            }
        }

        /// Returns the lowest-level element node in this node's hierarchy that wraps the specified
        /// range.  If no child element node wraps the specified range, this method returns this
        /// node.
        ///
        /// - Parameters:
        ///     - range: the range we want to find the wrapping node of.
        ///
        /// - Returns: the lowest-level element node wrapping the specified range, or this node if
        ///         no child node fulfills the condition.
        ///
        func lowestElementNodeWrapping(range: NSRange) -> ElementNode {

            var offset = 0

            for child in children {
                let length = child.length()
                let nodeRange = NSRange(location: offset, length: length)
                let nodeWrapsRange = (NSUnionRange(nodeRange, range).length == nodeRange.length)

                if nodeWrapsRange {
                    if let elementNode = child as? ElementNode {

                        let childRange = NSRange(location: range.location - offset, length: range.length)

                        return elementNode.lowestElementNodeWrapping(childRange)
                    } else {
                        return self
                    }
                }

                offset = offset + length
            }

            return self
        }

        /// Calls this method to obtain all the text nodes containing a specified range.
        ///
        /// - Parameters:
        ///     - range: the range that the text nodes must cover.
        ///
        /// - Returns: an array of text nodes and a range specifying how much of the text node
        ///         makes part of the input range.  The returned range's location is an offset
        ///         from the node's location.
        ///         The array of text nodes is ordered by order of appearance (0 being the first).
        ///
        func textNodesWrapping(range: NSRange) -> [(node: TextNode, range: NSRange)] {

            var results = [(node: TextNode, range: NSRange)]()
            var offset = 0

            for child in children {

                let childRange = NSRange(location: offset, length: child.length())
                let childInterceptsRange =
                    (range.length == 0 && NSLocationInRange(range.location, childRange))
                    || NSIntersectionRange(range, childRange).length != 0

                if childInterceptsRange {
                    if let textNode = child as? TextNode {

                        var intersection = NSIntersectionRange(range, childRange)
                        intersection.location = intersection.location - offset

                        results.append((node: textNode, range: intersection))
                    } else if let elementNode = child as? ElementNode {
                        let offsetRange = NSRange(location: range.location - offset, length: range.length)

                        results.appendContentsOf(elementNode.textNodesWrapping(offsetRange))
                    } else {
                        assertionFailure("This case should not be possible. Review the logic triggering this.")
                    }

                    let fullRangeCovered = range.location + range.length <= childRange.location + childRange.length

                    if fullRangeCovered {
                        break
                    }
                }

                offset = offset + child.length()
            }

            return results
        }

        // MARK: - DOM modification

        /// Inserts a node into the list of children for this element.
        ///
        /// - Parameters:
        ///     - child: the node to insert.
        ///     - index: the position where to insert the node.
        ///
        func insert(child: Node, at index: Int) {
            children.insert(child, atIndex: index)
            child.parent = self
        }

        /// Replaces the specified node with several new nodes.
        ///
        /// - Parameters:
        ///     - child: the node to remove.
        ///     - newChildren: the new child nodes to insert.
        ///
        func replace(child child: Node, with newChildren: [Node]) {
            guard let childIndex = children.indexOf(child) else {
                fatalError("This case should not be possible. Review the logic triggering this.")
            }

            for newNode in newChildren {
                newNode.parent = self
            }

            children.removeAtIndex(childIndex)
            children.insertContentsOf(newChildren, at: childIndex)
        }

        /// Removes the specified child nodes.  Only updates their parents if specified.
        ///
        /// - Parameters:
        ///     - children: the child nodes to remove.
        ///     - updateParent: whether the children node's parent must be update to `nil` or not.
        ///             If not specified, the parent is updated.
        ///
        func remove(children: [Node], updateParent: Bool = true) {
            self.children = self.children.filter({ child -> Bool in

                let removeChild = children.contains(child)

                if removeChild && updateParent {
                    child.parent = nil
                }

                return !removeChild
            })
        }

        /// Retrieves all child nodes positioned after a specified location.
        ///
        /// - IMPORTANT: This method can also modify the DOM depending on the value of `splitEdge`.
        ///         Please refer to the parameter's documentation for more information.
        ///
        /// - Parameters:
        ///     - location: marks the position after which nodes must be positioned.
        ///     - splitEdge: if this is `true`, any node intersecting `location` will be split
        ///             so that the part of it after `location` will be returned as a new node.
        ///             If this is `false`, only nodes that are completely positioned after
        ///             `location` will be returned and the DOM will be left unmodified.
        ///
        /// - Returns: the requested nodes.
        ///
        private func children(after location: Int, splitEdge: Bool = false) -> [Node] {

            var result = [Node]()
            var offset = length()

            for index in (children.count - 1).stride(through: 0, by: -1) {

                let child = children[index]

                offset = offset - child.length()

                let childEndPosition = offset + child.length()

                if offset > location {
                    result.insert(child, atIndex: 0)
                } else if splitEdge && childEndPosition > location {

                    let splitRange = NSRange(location: location - offset, length: childEndPosition - location)
                    child.split(forRange: splitRange)

                    result.insert(child, atIndex: 0)
                    break
                } else {
                    break
                }
            }
            
            return result
        }

        /// Retrieves all child nodes positioned before a specified location.
        ///
        /// - IMPORTANT: This method can also modify the DOM depending on the value of `splitEdge`.
        ///         Please refer to the parameter's documentation for more information.
        ///
        /// - Parameters:
        ///     - location: marks the position before which nodes must be positioned.
        ///     - splitEdge: if this is `true`, any node intersecting `location` will be split
        ///             so that the part of it after `location` will be returned as a new node.
        ///             If this is `false`, only nodes that are completely positioned before
        ///             `location` will be returned and the DOM will be left unmodified.
        ///
        /// - Returns: the requested nodes.
        ///
        private func children(before location: Int, splitEdge: Bool = false) -> [Node] {

            var result = [Node]()
            var offset = Int(0)

            for child in children {
                if offset + child.length() < location {
                    result.append(child)
                } else if splitEdge && offset < location {

                    let splitRange = NSRange(location: offset, length: location - offset)
                    child.split(forRange: splitRange)

                    result.append(child)
                    break
                } else {
                    break
                }

                offset = offset + child.length()
            }

            return result
        }

        /// Splits this node following the specified range.
        ///
        override func split(forRange range: NSRange) {

            guard range.location > 0 || range.length < length() else {
                return
            }

            guard let parent = parent,
                let nodeIndex = parent.children.indexOf(self) else {
                    assertionFailure("Can't split a node without a parent.")
                    return
            }

            let postNodes = children(after: range.location + range.length, splitEdge: true)

            if postNodes.count > 0 {
                let newElement = ElementNode(name: name, attributes: attributes, children: postNodes)

                parent.insert(newElement, at: nodeIndex + 1)
                remove(postNodes, updateParent: false)
            }

            let preNodes = children(before: range.location, splitEdge: true)

            if preNodes.count > 0 {
                let newElement = ElementNode(name: name, attributes: attributes, children: preNodes)

                parent.insert(newElement, at: nodeIndex)
                remove(preNodes, updateParent: false)
            }
        }

        func unwrap() {
            guard let parent = parent else {
                assertionFailure("The root node in a hierarchy cannot be unwrapped using this method.")
                return
            }

            parent.replace(child: self, with: self.children)
        }

        /// Unwraps the specified range from nodes with the specified name.  If there are multiple
        /// nodes with the specified name, the range will be unwrapped from all of them.
        ///
        /// - Parameters:
        ///     - range: the range that must be unwrapped.
        ///     - nodeName: the name of the node the range must be unwrapped from.
        ///
        /// - Todo: this method works with node names only for now.  At some point we'll want to
        ///         modify this to be able to do more complex lookups.  For instance we'll want
        ///         to be able to unwrapp CSS attributes, not just nodes by name.
        ///
        func unwrap(range range: NSRange, fromNodeNamed nodeName: String) {

            if name == nodeName {

                let rangeEndLocation = range.location + range.length

                let myLength = length()
                assert(range.location >= 0 && rangeEndLocation <= myLength,
                       "The specified range is out of bounds.")

                if range.location > 0 {
                    let preRange = NSRange(location: 0, length: range.location)
                    let preNode = ElementNode(name: name, attributes: attributes, children: [])

                    wrap(range: preRange, inNodeNamed: name, withAttributes: attributes)
                }

                if rangeEndLocation < myLength {
                    let postRange = NSRange(location: rangeEndLocation, length: myLength - rangeEndLocation)
                    let postNode = ElementNode(name: name, attributes: attributes, children: [])

                    wrap(range: postRange, inNodeNamed: name, withAttributes: attributes)
                }

                unwrap()
            }
        }

        /// Wraps the specified range inside a node with the specified properties.
        ///
        /// - Parameters:
        ///     - targetRange: the range that must be wrapped.
        ///     - nodeName: the name of the node to wrap the range in.
        ///     - attributes: the attributes the wrapping node will have when created.
        ///
        override func wrap(range targetRange: NSRange, inNodeNamed nodeName: String, withAttributes attributes: [Attribute]) {

            guard !NSEqualRanges(targetRange, range()) else {
                wrap(inNodeNamed: nodeName, withAttributes: attributes)
                return
            }

            let childNodesIntersectingRange = childNodes(intersectingRange: targetRange)
            assert(childNodesIntersectingRange.count > 0)

            if childNodesIntersectingRange.count == 1 {
                let childData = childNodesIntersectingRange[0]
                let childNode = childData.child
                let intersection = childData.intersection

                childNode.wrap(range: intersection, inNodeNamed: nodeName, withAttributes: attributes)
            } else if childNodesIntersectingRange.count > 1 {

                let firstChild = childNodesIntersectingRange[0].child
                let firstChildRange = childNodesIntersectingRange[0].intersection

                if !NSEqualRanges(firstChild.range(), firstChildRange) {

                }

                let lastChild = childNodesIntersectingRange[childNodesIntersectingRange.count - 1].child
                let lastChildRange = childNodesIntersectingRange[0].intersection

                if !NSEqualRanges(lastChild.range(), lastChildRange) {

                }

                wrap(children, inNodeNamed: nodeName, withAttributes: attributes)

                // Complex stuff happens here
                //
                // Break the first and last child nodes if not fully intercepted
                // Wrap all fully-intecepted child nodes
            }
        }

        /// Wraps the specified range inside a node with the specified name.
        ///
        /// - Parameters:
        ///     - newNodeRange: the range that must be wrapped.
        ///     - newNodeName: the name of the new node the range must be wrapped in.
        ///
        func wrap(range newNodeRange: NSRange, inNodeNamed newNodeName: String) {

            let textNodes = textNodesWrapping(newNodeRange)

            for (node, range) in textNodes {
                let nodeLength = node.length()

                if range.length != nodeLength {
                    node.split(forRange: range)
                }

                node.wrap(inNodeNamed: newNodeName)
            }
        }

        /// Wraps the specified children nodes in a newly created element with the specified name.
        /// The newly created node will be inserted at the position of `children[0]`.
        ///
        /// - Parameters:
        ///     - children: the children nodes to wrap in a new node.
        ///     - nodeName: the name of the new node.
        ///     - attributes: the attributes for the newly created node.
        ///
        /// - Returns: the newly created `ElementNode`.
        ///
        func wrap(children: [Node], inNodeNamed nodeName: String, withAttributes attributes: [Attribute]) -> ElementNode {

            guard children.count > 0 else {
                assertionFailure("Avoid calling this method with no nodes.")
                return ElementNode(name: nodeName, attributes: attributes, children: [])
            }

            guard let insertionIndexOfNewNode = self.children.indexOf(children[0]) else {
                fatalError("A node's parent should contain the node. Review the child/parent updating logic.")
            }

            let newNode = ElementNode(name: nodeName, attributes: attributes, children: children)

            self.children[insertionIndexOfNewNode] = newNode
            newNode.parent = self

            remove(children, updateParent: false)

            return newNode
        }
    }


    class RootNode: ElementNode {

        static let name = "aztec.htmltag.rootnode"

        override var parent: Libxml2.ElementNode? {
            get {
                return nil
            }

            set {
            }
        }

        override func customMirror() -> Mirror {
            return Mirror(self, children: ["name": name, "children": children])
        }

        init(children: [Node]) {
            super.init(name: self.dynamicType.name, attributes: [], children: children)
        }
    }
}
