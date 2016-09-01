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

            static func isBlockLevelNodeName(name: String) -> Bool {
                return StandardName(rawValue: name)?.isBlockLevelNodeName() ?? false
            }

            func isBlockLevelNodeName() -> Bool {
                return self.dynamicType.blockLevelNodeNames().contains(self)
            }
        }

        class Equivalence {
            let elementName1: String
            let elementName2: String

            init(ofElementNamed elementName1: String, andElementNamed elementName2: String) {
                self.elementName1 = elementName1
                self.elementName2 = elementName2
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

                if let parent = child.parent {
                    parent.remove(child)
                }

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

            return standardName.isBlockLevelNodeName()
        }

        // MARK: - DOM Queries

        /// Returns the child node at the specified location.
        ///
        func childNode(atLocation location: Int, defaultToLeftNode: Bool = true) -> Node {

            let defaultToRightNode = !defaultToLeftNode
            let offset = Int(0)

            for (index, child) in children.enumerate() {

                // On the last element, we need to force-default to the left node.
                //
                let bypassedDefaultToLeftNode = (defaultToLeftNode || index == children.count)

                let finalLocation = offset + child.length()
                let returnThisNode =
                    (location == offset && defaultToRightNode)
                    || location < finalLocation
                    || (location == offset + child.length() && bypassedDefaultToLeftNode)

                if returnThisNode {
                    return child
                }
            }

            fatalError("The specified location is out of bounds.")
        }

        /// Get a list of child nodes intersecting the specified range.
        ///
        /// - Parameters:
        ///     - targetRange: the range we're intersecting the child nodes with.  The range is in
        ///             this node's coordinates (the parent node's coordinates, from the children
        ///             PoV).
        ///     - preferLeftNode: for zero-length target ranges, this parameter is used to
        ///             disambiguate if we're referring to the last position in a node, or to the
        ///             first position in the following node (since both positions have the same
        ///             offset).  By default this is true.
        ///
        /// - Returns: an array of pairs of child nodes and their ranges in child coordinates.
        ///
        func childNodes(intersectingRange targetRange: NSRange, preferLeftNode: Bool = true) -> [(child: Node, intersection: NSRange)] {
            var results = [(child: Node, intersection: NSRange)]()

            enumerateChildNodes(intersectingRange: targetRange, preferLeftNode: preferLeftNode) { (child, intersection) in
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
        ///     - preferLeftNode: for zero-length target ranges, this parameter is used to
        ///             disambiguate if we're referring to the last position in a node, or to the
        ///             first position in the following node (since both positions have the same
        ///             offset).
        ///     - matchFound: the closure to execute for each child node intersecting
        ///             `targetRange`.
        ///
        /// - Returns: an array of child nodes and their intersection.  The intersection range is in
        ///         child coordinates.
        ///
        func enumerateChildNodes(intersectingRange targetRange: NSRange, preferLeftNode: Bool = true, onMatchFound matchFound: (child: Node, intersection: NSRange) -> Void ) {

            var offset = Int(0)

            for (index, child) in children.enumerate() {

                let childLength = child.length()
                let childRange = NSRange(location: offset, length: childLength)
                let intersectionRange: NSRange
                let childRangeInterceptsTargetRange: Bool

                if targetRange.length > 0 {

                    intersectionRange = NSIntersectionRange(childRange, targetRange)

                    childRangeInterceptsTargetRange =
                        (intersectionRange.location > 0 && intersectionRange.length < childLength)
                        || intersectionRange.length > 0
                } else {
                    let targetLocation = targetRange.location
                    let preferLeftNode = preferLeftNode || (index == children.count - 1)
                    let preferRightNode = !preferLeftNode || (index == 0)

                    childRangeInterceptsTargetRange =
                        (preferRightNode && targetLocation == offset)
                        || (preferLeftNode && targetLocation == offset + childLength)
                        || (targetLocation > offset && targetLocation < offset + childLength)

                    intersectionRange = NSRange(location: targetLocation - offset, length: 0)
                }

                if childRangeInterceptsTargetRange {

                    let intersectionRangeInChildCoordinates = NSRange(location: intersectionRange.location - offset, length: intersectionRange.length)

                    matchFound(child: child, intersection: intersectionRangeInChildCoordinates)
                }

                offset += childLength
            }
        }

        /// Returns the lowest block-level child elements intersecting the specified range.
        /// Whenever a range doesn't intersect a block-level node, `self` (the receiver) is returned
        /// as the owner of that range.
        ///
        /// - Parameters:
        ///     - targetRange: the range we're intersecting the child nodes with.  The range is in
        ///             this node's coordinates (the parent node's coordinates, from the children
        ///             PoV).
        ///
        /// - Returns: an array of child nodes and their intersection.  The intersection range is in
        ///         child coordinates.
        ///
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

        /// Enumerate the child block-level elements intersecting the specified range.
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

            enumerateLowestElements(
                intersectingRange: targetRange,
                fulfillingCondition: { (element) -> Bool in
                    return element.isBlockLevelElement()
                },
                onMatchNotFound: matchNotFound,
                onMatchFound: matchFound)
        }

        /// Enumerate the child elements intersecting the specified range and fulfilling a specified
        /// condition.
        ///
        /// - Parameters:
        ///     - targetRange: the range we're intersecting the child nodes with.  The range is in
        ///             this node's coordinates (the parent node's coordinates, from the children
        ///             PoV).
        ///     - condition: a condition that blocks must fulfill to be considered valid results.
        ///     - matchNotFound: the closure to execute for any subrange of `targetRange` that
        ///             doesn't have a block-level node intersecting it.
        ///     - matchFound: the closure to execute for each child element intersecting
        ///             `targetRange`.
        ///
        /// - Returns: an array of child nodes and their intersection.  The intersection range is in
        ///         child coordinates.
        ///
        private func enumerateLowestElements(intersectingRange targetRange: NSRange, fulfillingCondition checkCondition: (element: ElementNode) -> Bool, onMatchNotFound matchNotFound: (range: NSRange) -> Void, onMatchFound matchFound: (element: ElementNode, intersection: NSRange) -> Void ) {

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
                                    rangeWithoutMatch = NSRange(location: offset + range.location, length: range.length)
                                }
                            },
                            onMatchFound: { [weak self] (child, intersection) in

                                guard let strongSelf = self else {
                                    return
                                }

                                if let previousRangeWithoutMatch = rangeWithoutMatch {
                                    if checkCondition(element: strongSelf) {
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
                if checkCondition(element: self) {
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

        /// Appends a node into the list of children for this element.
        ///
        /// - Parameters:
        ///     - child: the node to append.
        ///
        func append(child: Node) {

            if let parent = child.parent {
                parent.remove([child])
            }

            children.append(child)
            child.parent = self
        }

        /// Inserts a node into the list of children for this element.
        ///
        /// - Parameters:
        ///     - child: the node to insert.
        ///     - index: the position where to insert the node.
        ///
        func insert(child: Node, at index: Int) {

            if let parent = child.parent {
                parent.remove([child])
            }

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

        /// Removes the receiver from its parent.
        ///
        func removeFromParent() {
            guard let parent = parent else {
                assertionFailure("It doesn't make sense to call this method without a parent")
                return
            }

            parent.remove(self)
        }


        /// Removes the specified child node.  Only updates its parent if specified.
        ///
        /// - Parameters:
        ///     - child: the child node to remove.
        ///     - updateParent: whether the children node's parent must be update to `nil` or not.
        ///             If not specified, the parent is updated.
        ///
        func remove(child: Node, updateParent: Bool = true) {

            guard let index = children.indexOf(child) else {
                assertionFailure("Can't remove a node that's not a child.")
                return
            }

            children.removeAtIndex(index)

            if updateParent {
                child.parent = nil
            }
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

        override func deleteCharacters(inRange range: NSRange) {
            if range.location == 0 && range.length == length() {
                removeFromParent()
            } else {
                let childrenAndIntersections = childNodes(intersectingRange: range)

                for (child, intersection) in childrenAndIntersections {
                    child.deleteCharacters(inRange: intersection)
                }
            }
        }

        override func replaceCharacters(inRange range: NSRange, withString string: String) {

            let childrenAndIntersections = childNodes(intersectingRange: range)

            for (index, childAndIntersection) in childrenAndIntersections.enumerate() {

                let child = childAndIntersection.child
                let intersection = childAndIntersection.intersection

                if index == 0 && string.characters.count > 0 {
                    child.replaceCharacters(inRange: intersection, withString: string)
                } else {
                    child.deleteCharacters(inRange: intersection)
                }
            }
        }

        /// Splits this node following the specified range.
        ///
        override func split(forRange range: NSRange) {

            guard range.location >= 0 && range.location + range.length <= length() else {
                assertionFailure("Specified range is out-of-bounds.")
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

        func unwrap(fromElementsNamed elementNames: [String]) {
            unwrap(range: range(), fromElementsNamed: elementNames)
        }

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
        func unwrap(range range: NSRange, fromElementsNamed elementNames: [String]) {

            unwrapChildren(intersectingRange: range, fromElementsNamed: elementNames)

            if elementNames.contains(name) {

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

                unwrapChildren()
            }
        }

        /// Unwraps the receiver's children from the receiver.
        ///
        func unwrapChildren() {
            if let parent = parent {
                parent.replace(child: self, with: self.children)
            } else {
                for child in children {
                    child.parent = nil
                }

                children.removeAll()
            }
        }

        func unwrapChildren(children: [Node], fromElementsNamed elementNames: [String]) {

            for child in children {

                guard let childElement = child as? ElementNode else {
                    continue
                }

                childElement.unwrap(fromElementsNamed: elementNames)
            }
        }

        /// Unwraps all child nodes from elements with the specified names.
        ///
        /// - Parameters:
        ///     - range: the range we want to unwrap.
        ///     - elementNames: the name of the elements we want to unwrap the nodes from.
        ///
        func unwrapChildren(intersectingRange range: NSRange, fromElementsNamed elementNames: [String]) {

            let childNodesAndRanges = childNodes(intersectingRange: range)
            assert(childNodesAndRanges.count > 0)

            for (child, range) in childNodesAndRanges {
                guard let childElement = child as? ElementNode else {
                    continue
                }

                childElement.unwrap(range: range, fromElementsNamed: elementNames)
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

            let mustFindLowestBlockLevelElements = !StandardName.isBlockLevelNodeName(nodeName)

            if mustFindLowestBlockLevelElements {
                let elementsAndIntersections = lowestBlockLevelElements(intersectingRange: targetRange)

                for elementAndIntersection in elementsAndIntersections {

                    let element = elementAndIntersection.element
                    let intersection = elementAndIntersection.intersection

                    element.forceWrapChildren(
                        intersectingRange: intersection,
                        inNodeNamed: nodeName,
                        withAttributes: attributes)
                }
            } else {
                forceWrap(range: targetRange, inNodeNamed: nodeName, withAttributes: attributes)
            }
        }

        /// Wraps child nodes intersecting the specified range inside new elements with the
        /// specified properties.
        ///
        /// - Important: this method doesn't check if the child nodes are block-level elements or
        ///         not.  If you need to check for block level elements, you must obtain them
        ///         before calling this method.
        ///
        /// - Parameters:
        ///     - targetRange: the range that must be wrapped.
        ///     - nodeName: the name of the node to wrap the range in.
        ///     - attributes: the attributes the wrapping node will have when created.
        ///     - checkBlockLevel: if `true`, this method will check if its necessary to find the
        ///             lowest block-level element nodes before doing the wrapping.
        ///
        func wrapChildren(intersectingRange targetRange: NSRange, inNodeNamed nodeName: String, withAttributes attributes: [Attribute], equivalentElementNames: [String]) {

            // Before wrapping a range in a node, we remove all equivalent nodes from the range.
            //
            if equivalentElementNames.count > 0 {
                unwrap(range: targetRange, fromElementsNamed: equivalentElementNames)
            }

            let mustFindLowestBlockLevelElements = !StandardName.isBlockLevelNodeName(nodeName)

            if mustFindLowestBlockLevelElements {
                let elementsAndIntersections = lowestBlockLevelElements(intersectingRange: targetRange)

                for (element, intersection) in elementsAndIntersections {

                    element.forceWrapChildren(
                        intersectingRange: intersection,
                        inNodeNamed: nodeName,
                        withAttributes: attributes)
                }
            } else {
                forceWrapChildren(intersectingRange: targetRange, inNodeNamed: nodeName, withAttributes: attributes)
            }
        }

        /// Force-wraps the specified range inside a node with the specified properties.
        ///
        /// - Parameters:
        ///     - targetRange: the range that must be wrapped.
        ///     - nodeName: the name of the node to wrap the range in.
        ///     - attributes: the attributes the wrapping node will have when created.
        ///
        func forceWrap(range targetRange: NSRange, inNodeNamed nodeName: String, withAttributes attributes: [Attribute]) {

            guard !NSEqualRanges(targetRange, range()) else {
                wrap(inNodeNamed: nodeName, withAttributes: attributes)
                return
            }

            forceWrapChildren(intersectingRange: targetRange, inNodeNamed: nodeName, withAttributes: attributes)
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
        ///     - nodeName: the name of the node to wrap the range in.
        ///     - attributes: the attributes the wrapping node will have when created.
        ///
        private func forceWrapChildren(intersectingRange targetRange: NSRange, inNodeNamed nodeName: String, withAttributes attributes: [Attribute]) {

            let childNodesAndRanges = childNodes(intersectingRange: targetRange)
            assert(childNodesAndRanges.count > 0)

            if childNodesAndRanges.count == 1 {
                let childData = childNodesAndRanges[0]
                let childNode = childData.child
                let intersection = childData.intersection

                if let childElement = childNode as? ElementNode {
                    childElement.forceWrap(range: intersection, inNodeNamed: nodeName, withAttributes: attributes)
                } else {
                    childNode.wrap(range: intersection, inNodeNamed: nodeName, withAttributes: attributes)
                }
            } else if childNodesAndRanges.count > 1 {

                let firstChild = childNodesAndRanges[0].child
                let firstChildIntersection = childNodesAndRanges[0].intersection

                if !NSEqualRanges(firstChild.range(), firstChildIntersection) {
                    firstChild.split(forRange: firstChildIntersection)
                }

                let lastChild = childNodesAndRanges[childNodesAndRanges.count - 1].child
                let lastChildIntersection = childNodesAndRanges[childNodesAndRanges.count - 1].intersection

                if !NSEqualRanges(lastChild.range(), lastChildIntersection) {
                    lastChild.split(forRange: lastChildIntersection)
                }

                let children = childNodesAndRanges.map({ (child: Node, intersection: NSRange) -> Node in
                    return child
                })

                wrap(children, inNodeNamed: nodeName, withAttributes: attributes)
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

            self.children.insert(newNode, atIndex: insertionIndexOfNewNode)
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
