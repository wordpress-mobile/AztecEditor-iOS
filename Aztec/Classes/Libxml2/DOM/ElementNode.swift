import Foundation
import UIKit

extension Libxml2 {

    /// Element node.  Everything but text basically.
    ///
    class ElementNode: Node, EditableNode {

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

        internal var standardName: StandardElementType? {
            get {
                return StandardElementType(rawValue: name)
            }
        }

        init(name: String, attributes: [Attribute], children: [Node]) {
            self.attributes.appendContentsOf(attributes)
            self.children = children

            super.init(name: name)

            for child in children {

                if let parent = child.parent {
                    parent.remove(child)
                }

                child.parent = self
            }
        }
        
        convenience init(descriptor: ElementNodeDescriptor, children: [Node] = []) {
            self.init(name: descriptor.name, attributes: descriptor.attributes, children: children)
        }

        override func customMirror() -> Mirror {
            return Mirror(self, children: ["type": "element", "name": name, "parent": parent.debugDescription, "attributes": attributes, "children": children], ancestorRepresentation: .Suppressed)
        }
        
        // MARK: - Node Overrides
        
        /// Node length.  Calculated by adding the length of all child nodes.
        ///
        override func length() -> Int {
            return text().characters.count
        }

        // MARK: - Node Queries

        func valueForStringAttribute(named attributeName: String) -> String? {

            for attribute in attributes {
                if let attribute = attribute as? StringAttribute where attribute.name == attributeName {
                    return attribute.value
                }
            }

            return nil
        }

        /// Updates or adds an attribute with the specificed name with the corresponding value
        ///
        /// - parameter attributeName: the name of the attribute
        /// - parameter value:         the value to mark the attribute
        ///
        func updateAttribute(named attributeName:String, value: String) {
            for attribute in attributes {
                if let attribute = attribute as? StringAttribute where attribute.name == attributeName {
                    attribute.value = value
                    return
                }
            }
            attributes.append(StringAttribute(name: attributeName, value: value))
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
        
        /// Returns the index of the child node intersecting the specified location.
        ///
        /// - Parameters:
        ///     - location: the text location that the child node must intersect.
        ///
        /// - Returns: The index of the child node intersecting the specified text location.  If the text location is
        ///         exactly between two nodes, the left hand node will always be returned.  The only exception to this
        ///         rule is for text location zero, which will always result in index zero being returned.
        ///
        func indexOfChildNode(intersecting location: Int) -> (index: Int, intersection: Int)  {
            
            guard children.count > 0 else {
                fatalError("An element node without children should never happen.")
            }
            
            guard location != 0 else {
                return (0, 0)
            }
            
            var adjustedLocation = location
            
            for (index, child) in children.enumerate() {
                
                if (adjustedLocation <= child.length()) {
                    return (index, adjustedLocation)
                }
                
                adjustedLocation = adjustedLocation - child.length()
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
                    let preferLeftNode = preferLeftNode || (index == children.count - 1 && targetLocation == offset + childLength)
                    let preferRightNode = !preferLeftNode || (index == 0 && targetLocation == 0)

                    childRangeInterceptsTargetRange =
                        (preferRightNode && targetLocation == offset)
                        || (preferLeftNode && targetLocation == offset + childLength)
                        || (targetLocation > offset && targetLocation < offset + childLength)

                    intersectionRange = NSRange(location: targetLocation, length: 0)
                }

                if childRangeInterceptsTargetRange {

                    let intersectionRangeInChildCoordinates = NSRange(location: intersectionRange.location - offset, length: intersectionRange.length)

                    matchFound(child: child, intersection: intersectionRangeInChildCoordinates)
                }

                offset += childLength
            }
        }

        /// Returns the lowest block-level child elements intersecting the specified range.
        ///
        /// - Parameters:
        ///     - targetRange: the range we're intersecting the child nodes with.  The range is in
        ///             this node's coordinates (the parent node's coordinates, from the children
        ///             PoV).
        ///
        /// - Returns: An array of child nodes and their intersection.  The intersection range is in
        ///         child coordinates.
        ///         Whenever a range doesn't intersect a block-level node, `self` (the receiver) is returned
        ///         as the owner of that range.
        ///
        func lowestBlockLevelElements(intersectingRange targetRange: NSRange) -> [(element: ElementNode, intersection: NSRange)] {
            var results = [(element: ElementNode, intersection: NSRange)]()

            enumerateLowestBlockLevelElements(intersectingRange: targetRange) { result in
                results.append(result)
            }

            return results
        }

        /// Enumerate the lowest block-level child elements intersecting the specified range.
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
                bailIf: { (element) -> Bool in
                    return !element.isBlockLevelElement()
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
        ///     - bailCondition: a condition that makes the search bail from a specific tree search 
        ///             branch.
        ///     - matchNotFound: the closure to execute for any subrange of `targetRange` that
        ///             doesn't have a block-level node intersecting it.
        ///     - matchFound: the closure to execute for each child element intersecting
        ///             `targetRange`.
        ///
        /// - Returns: an array of child nodes and their intersection.  The intersection range is in
        ///         child coordinates.
        ///
        private func enumerateLowestElements(intersectingRange targetRange: NSRange, bailIf bailCondition: (element: ElementNode) -> Bool, onMatchNotFound matchNotFound: (range: NSRange) -> Void, onMatchFound matchFound: (element: ElementNode, intersection: NSRange) -> Void ) {
            
            var rangeWithoutMatch: NSRange?
            var offset = Int(0)

            for child in children {

                let childLength = child.length()
                let childRange = NSRange(location: offset, length: childLength)

                if let intersection = targetRange.intersect(withRange: childRange) {
                    
                    let intersectionInChildCoordinates = NSRange(location: intersection.location - offset, length: intersection.length)

                    if let childElement = child as? ElementNode
                        where !bailCondition(element: childElement) {
                        
                        childElement.enumerateLowestElements(
                            intersectingRange: intersectionInChildCoordinates,
                            bailIf: bailCondition,
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
                                    if !bailCondition(element: strongSelf) {
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
                            rangeWithoutMatch = NSRange(location: previousRangeWithoutMatch.location, length: previousRangeWithoutMatch.length + intersectionInChildCoordinates.length)
                        } else {
                            rangeWithoutMatch = intersection

                        }
                    }
                }

                offset += childLength
            }

            if let previousRangeWithoutMatch = rangeWithoutMatch {
                if !bailCondition(element: self) {
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

        /// Returns the lowest-level text node in this node's hierarchy that wraps the specified
        /// range.  If no child text node wraps the specified range, this method returns nil.
        ///
        /// - Parameters:
        ///     - range: the range we want to find the wrapping node of.
        ///
        /// - Returns: the lowest-level text node wrapping the specified range, or nil if
        ///         no child node fulfills the condition.
        ///
        func lowestTextNodeWrapping(range: NSRange) -> TextNode? {

            var offset = 0

            for child in children {
                let length = child.length()
                let nodeRange = NSRange(location: offset, length: length)
                let nodeWrapsRange = (NSUnionRange(nodeRange, range).length == nodeRange.length)

                if nodeWrapsRange {
                    if let textNode = child as? TextNode {
                        return textNode
                    } else if let elementNode = child as? ElementNode {

                        let childRange = NSRange(location: range.location - offset, length: range.length)

                        return elementNode.lowestTextNodeWrapping(childRange)
                    } else {
                        return nil
                    }
                }

                offset = offset + length
            }
            
            return nil
        }

        /// Calls this method to obtain all the leaf nodes containing a specified range.
        ///
        /// - Parameters:
        ///     - range: the range that the text nodes must cover.
        ///
        /// - Returns: an array of leaf nodes and a range specifying how much of the node contents
        ///         makes part of the input range.  The returned range's location is an offset
        ///         from the node's location.
        ///         The array of leaf nodes is ordered by order of appearance (0 being the first).
        ///
        func leafNodesWrapping(range: NSRange) -> [(node: LeafNode, range: NSRange)] {

            var results = [(node: LeafNode, range: NSRange)]()
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
                    } else if let commentNode = child as? CommentNode {
                        var intersection = NSIntersectionRange(range, childRange)
                        intersection.location = intersection.location - offset
                        
                        results.append((node: commentNode, range: intersection))
                    } else if let elementNode = child as? ElementNode {
                        let offsetRange = NSRange(location: range.location - offset, length: range.length)

                        results.appendContentsOf(elementNode.leafNodesWrapping(offsetRange))
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
        
        /// Retrieves the left-side sibling of the child at the specified index.
        ///
        /// - Parameters:
        ///     - index: the index of the child to get the sibling of.
        ///
        /// - Returns: the requested sibling, or `nil` if there's none.
        ///
        @warn_unused_result
        func sibling<T: Node>(leftOf childIndex: Int) -> T? {
            
            guard childIndex >= 0 && childIndex < children.count else {
                fatalError("Out of bounds!")
            }
            
            guard childIndex > 0,
                let sibling = children[childIndex - 1] as? T else {
                    return nil
            }
            
            return sibling
        }
        
        /// Retrieves the right-side sibling of the child at the specified index.
        ///
        /// - Parameters:
        ///     - index: the index of the child to get the sibling of.
        ///
        /// - Returns: the requested sibling, or `nil` if there's none.
        ///
        @warn_unused_result
        func sibling<T: Node>(rightOf childIndex: Int) -> T? {
            
            guard childIndex >= 0 && childIndex < children.count else {
                fatalError("Out of bounds!")
            }
            
            guard childIndex < children.count - 1,
                let sibling = children[childIndex + 1] as? T else {
                    return nil
            }
            
            return sibling
        }
        
        /// Finds any left-side descendant with any of the specified names.
        ///
        /// - Parameters:
        ///     - evaluate: the closure to evaluate the candidate.  `true` means we have a good
        ///             candidate.
        ///     - bail: the closure that will be used to evaluate if the descendant search must
        ///             bail.
        ///
        /// - Returns: the matching element, if any was found, or `nil`.
        ///
        @warn_unused_result
        private func find<T: Node>(leftSideDescendantEvaluatedBy evaluate: (T -> Bool), bailIf bail: (T -> Bool) = { _ in return false }) -> T? {
            
            guard children.count > 0 else {
                return nil
            }
            
            let child = children[0]
            
            if let match = child as? T where !bail(match) && evaluate(match) {
                return match
            } else if let element = child as? ElementNode {
                return element.find(leftSideDescendantEvaluatedBy: evaluate, bailIf: bail)
            } else {
                return nil
            }
        }
        
        /// Finds any right-side descendant with any of the specified names.
        ///
        /// - Parameters:
        ///     - evaluate: the closure to evaluate the candidate.  `true` means we have a good
        ///             candidate.
        ///     - bail: the closure that will be used to evaluate if the descendant search must
        ///             bail.
        ///
        /// - Returns: the matching element, if any was found, or `nil`.
        ///
        @warn_unused_result
        private func find<T: Node>(rightSideDescendantEvaluatedBy evaluate: (T -> Bool), bailIf bail: (T -> Bool) = { _ in return false }) -> T? {
            
            guard children.count > 0 else {
                return nil
            }
            
            let child = children[children.count - 1]
            
            if let match = child as? T where !bail(match) && evaluate(match) {
                return match
            } else if let element = child as? ElementNode {
                return element.find(rightSideDescendantEvaluatedBy: evaluate, bailIf: bail)
            } else {
                return nil
            }
        }
        
        override func text() -> String {

            var text = ""
            for child in children {
                text = text + child.text()
            }

            text = implicitRepresentation(forNode:self, childContent: text)

            return text
        }

        private func implicitRepresentation(forNode node: ElementNode, childContent: String) -> String {

            guard let nodeType = node.standardName else {
                return childContent
            }

            var resultString = childContent
            switch nodeType {
            case .img:
                return String(UnicodeScalar(NSAttachmentCharacter))
            case .br:
                return "\n"
            case .p:
                resultString = resultString + "\n"
            case .li:
                resultString = resultString + "\n"
            default:
                return resultString
            }
            return resultString
        }

        
        /// Returns the plain visible text for a specified range.
        ///
        /// - Parameters:
        ///     - range: the range of the text inside this node that we want to retrieve.
        ///
        func text(forRange range: NSRange) -> String {
            let textNodesAndRanges = leafNodesWrapping(range)
            var text = ""
            
            for textNodeAndRange in textNodesAndRanges {
                let nodeText = textNodeAndRange.node.text()
                let range = nodeText.rangeFromNSRange(textNodeAndRange.range)!
                
                text = text + nodeText.substringWithRange(range)
            }
            
            return text
        }

        // MARK: - DOM modification

        /// Appends a node to the list of children for this element.
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
        
        /// Appends a node to the list of children for this element.
        ///
        /// - Parameters:
        ///     - child: the node to append.
        ///
        func append(children: [Node]) {
            
            for child in children {
                append(child)
            }
        }
        
        /// Prepends a node to the list of children for this element.
        ///
        /// - Parameters:
        ///     - child: the node to prepend.
        ///
        func prepend(child: Node) {
            
            if let parent = child.parent {
                parent.remove([child])
            }
            
            children.insert(child, atIndex: 0)
            child.parent = self
        }

        /// Prepends children to the list of children for this element.
        ///
        /// - Parameters:
        ///     - children: the nodes to prepend.
        ///
        func prepend(children: [Node]) {
            
            for index in (children.count - 1).stride(through: 0, by: -1) {
                prepend(children[index])
            }
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
                } else if let childEditableNode = child as? EditableNode where splitEdge && childEndPosition > location {

                    let splitRange = NSRange(location: location - offset, length: childEndPosition - location)
                    childEditableNode.split(forRange: splitRange)

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
                } else if let childEditableNode = child as? EditableNode where splitEdge && offset < location {

                    let splitRange = NSRange(location: offset, length: location - offset)
                    childEditableNode.split(forRange: splitRange)

                    result.append(child)
                    break
                } else {
                    break
                }

                offset = offset + child.length()
            }

            return result
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
        private func pushUp<T: Node>(siblingOrDescendantAtLeftSideOf childIndex: Int, evaluatedBy evaluation: (T -> Bool), bailIf bail: (T -> Bool) = { _ in return false }) -> T? {
            
            guard let theSibling: T = sibling(leftOf: childIndex)
                where !bail(theSibling) else {
                return nil
            }
            
            guard !evaluation(theSibling) else {
                return theSibling
            }
            
            return pushUp(rightSideDescendantEvaluatedBy: evaluation, bailIf: bail)
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
        func pushUp<T: Node>(leftSideDescendantEvaluatedBy evaluationClosure: (T -> Bool), bailIf bail: (T -> Bool) = { _ in return false }) -> T? {
            
            guard let node = find(leftSideDescendantEvaluatedBy: evaluationClosure, bailIf: bail) else {
                return nil
            }
            
            while let parent = node.parent,
                let grandParent = parent.parent {
                    
                    let lastSwap = parent == self
                    
                    if let element = node as? ElementNode {
                        
                        let parentDescriptor = ElementNodeDescriptor(name: parent.name, attributes: parent.attributes)
                        element.wrap(children: element.children, inElement: parentDescriptor)
                    }
                    
                    guard let parentIndex = grandParent.children.indexOf(parent) else {
                        fatalError("The grandparent element should contain the parent element.")
                    }
                    
                    grandParent.insert(node, at: parentIndex)
                    
                    if lastSwap {
                        break
                    }
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
        private func pushUp<T: Node>(siblingOrDescendantAtRightSideOf childIndex: Int, evaluatedBy evaluation: (T -> Bool), bailIf bail: (T -> Bool) = { _ in return false }) -> T? {
            
            guard let theSibling: T = sibling(rightOf: childIndex)
                where !bail(theSibling) else {
                    return nil
            }
            
            guard !evaluation(theSibling) else {
                return theSibling
            }
            
            return pushUp(leftSideDescendantEvaluatedBy: evaluation, bailIf: bail)
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
        func pushUp<T: Node>(rightSideDescendantEvaluatedBy evaluationClosure: (T -> Bool), bailIf bail: (T -> Bool) = { _ in return false }) -> T? {
            
            guard let node = find(rightSideDescendantEvaluatedBy: evaluationClosure, bailIf: bail) else {
                return nil
            }
            
            while let parent = node.parent,
                let grandParent = parent.parent {
                
                    let lastSwap = parent == self
                    
                    if let element = node as? ElementNode {
                        
                        let parentDescriptor = ElementNodeDescriptor(name: parent.name, attributes: parent.attributes)
                        element.wrap(children: element.children, inElement: parentDescriptor)
                    }
                    
                    guard let parentIndex = grandParent.children.indexOf(parent) else {
                        fatalError("The grandparent element should contain the parent element.")
                    }
                    
                    grandParent.insert(node, at: parentIndex + 1)
                    
                    if lastSwap {
                        break
                    }
            }
            
            return node
        }

        // MARK: - EditableNode

        func deleteCharacters(inRange range: NSRange) {
            if range.location == 0 && range.length == length() {
                removeFromParent()
            } else {
                let childrenAndIntersections = childNodes(intersectingRange: range)

                for (child, intersection) in childrenAndIntersections {

                    if let childEditableNode = child as? EditableNode {
                        childEditableNode.deleteCharacters(inRange: intersection)
                    } else {
                        remove(child)
                    }
                }
            }
        }
        
        /// Inserts the specified text in a new `TextNode` at the specified index.  If any of the siblings are
        /// of class `TextNode`, this method will append or prepend the text to them instead.
        ///
        /// Outside classes should call `insert(string:, atLocation:)` instead.
        ///
        /// This method is just a handler for some specific scenarios handled by that method.
        ///
        /// - Parameters:
        ///     - string: the string to insert in a new `TextNode`.
        ///     - index: the index where the next `TextNode` will be inserted.
        ///
        func insert(string: String, at index: Int) {

            guard index <= children.count else {
                fatalError("The specified index is outside the range of possible indexes for insertion.")
            }
            
            let previousIndex = index - 1
            
            if previousIndex >= 0, let previousTextNode = children[previousIndex] as? TextNode {
                previousTextNode.append(string)
            } else if index < children.count, let nextTextNode = children[index] as? TextNode {
                nextTextNode.prepend(string)
            } else {
                insert(TextNode(text: string), at: index)
            }
        }

        /// Inserts the specified string at the specified location.
        ///
        func insert(string: String, atLocation location: Int) {
            let blockLevelElementsAndIntersections = lowestBlockLevelElements(intersectingRange: NSRange(location: location, length: 0))
            
            guard blockLevelElementsAndIntersections.count > 0 else {
                fatalError("We should have exactly one block-level element here.")
            }

            let element = blockLevelElementsAndIntersections[0].element
            let intersection = blockLevelElementsAndIntersections[0].intersection
            
            let indexAndIntersection = element.indexOfChildNode(intersecting: intersection.location)
            
            let childIndex = indexAndIntersection.index
            let childIntersection = indexAndIntersection.intersection
            
            let child = element.children[childIndex]
            var insertionIndex: Int
            
            if childIntersection == 0 {
                insertionIndex = childIndex
            } else {
                
                if childIntersection < child.length() {
                    
                    guard let editableNode = child as? EditableNode else {
                        fatalError("We should never have a non-editable node with a representation that can be split.")
                    }
                    
                    editableNode.split(atLocation: childIntersection)
                }
                
                insertionIndex = childIndex + 1
            }
            
            element.insert(string, at: insertionIndex)
        }

        func replaceCharacters(inRange range: NSRange, withString string: String, inheritStyle: Bool) {
            
            // When inheriting the style, we can just replace the text from the first child node with our new text.
            //
            let replaceTextFromFirstChild = inheritStyle && string.characters.count > 0
            let childrenAndIntersections = childNodes(intersectingRange: range)
            
            for (index, childAndIntersection) in childrenAndIntersections.enumerate() {
                
                let child = childAndIntersection.child
                let intersection = childAndIntersection.intersection
                
                if let childEditableNode = child as? EditableNode {
                    if index == 0 && replaceTextFromFirstChild {
                        childEditableNode.replaceCharacters(inRange: intersection, withString: string, inheritStyle: inheritStyle)
                    } else {
                        childEditableNode.deleteCharacters(inRange: intersection)
                    }
                } else {
                    remove(child)
                }
            }
            
            if !inheritStyle && string.characters.count > 0 {
                insert(string, atLocation: range.location)
            }
        }

        /// Replace characters in targetRange by a node with the name in nodeName and attributes
        ///
        /// - parameter targetRange:        The range to replace
        /// - parameter elementDescriptor:  The descriptor for the element to replace the text with.
        ///
        func replaceCharacters(inRange targetRange: NSRange, withElement elementDescriptor: ElementNodeDescriptor) {
            
            guard let textNode = lowestTextNodeWrapping(targetRange) else {
                return
            }
            
            let absoluteLocation = textNode.absoluteLocation()
            let localRange = NSRange(location: targetRange.location - absoluteLocation, length: targetRange.length)
            textNode.split(forRange: localRange)
            
            let imgNode = ElementNode(descriptor: elementDescriptor)
            
            guard let index = textNode.parent?.children.indexOf(textNode) else {
                assertionFailure("Can't remove a node that's not a child.")
                return
            }
            
            guard let textNodeParent = textNode.parent else {
                return
            }
            
            textNodeParent.insert(imgNode, at: index)
            textNodeParent.remove(textNode)
        }

        func split(atLocation location: Int) {
            
            guard location != 0 && location != length() - 1 else {
                // Nothing to split, move along...
                return
            }
            
            guard location > 0 && location < length() - 1 else {
                assertionFailure("Specified range is out-of-bounds.")
                return
            }
            
            guard let parent = parent,
                let nodeIndex = parent.children.indexOf(self) else {
                    assertionFailure("Can't split a node without a parent.")
                    return
            }
            
            let postNodes = children(after: location, splitEdge: true)
            
            if postNodes.count > 0 {
                let newElement = ElementNode(name: name, attributes: attributes, children: postNodes)
                
                parent.insert(newElement, at: nodeIndex + 1)
                remove(postNodes, updateParent: false)
            }
        }


        /// Splits this node according to the specified range.
        ///
        /// - Parameters:
        ///     - range: the range to use for splitting this node.  All nodes before and after the specified range will
        ///         be inserted in clones of this node.  All child nodes inside the range will be kept inside this node.
        ///
        func split(forRange range: NSRange) {

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

        /// Wraps the specified range inside a node with the specified properties.
        ///
        /// - Parameters:
        ///     - targetRange: the range that must be wrapped.
        ///     - elementDescriptor: the descriptor for the element to wrap the range in.
        ///
        func wrap(range targetRange: NSRange, inElement elementDescriptor: Libxml2.ElementNodeDescriptor) {

            let mustFindLowestBlockLevelElements = !elementDescriptor.isBlockLevel()

            if mustFindLowestBlockLevelElements {
                let elementsAndIntersections = lowestBlockLevelElements(intersectingRange: targetRange)

                for elementAndIntersection in elementsAndIntersections {

                    let element = elementAndIntersection.element
                    let intersection = elementAndIntersection.intersection
                    
                    element.forceWrapChildren(intersectingRange: intersection, inElement: elementDescriptor)
                }
            } else {
                forceWrap(range: targetRange, inElement: elementDescriptor)
            }
        }

        // MARK: - Wrapping

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
                
                let elementDescriptor = ElementNodeDescriptor(name: name, attributes: attributes)

                if range.location > 0 {
                    let preRange = NSRange(location: 0, length: range.location)
                    wrap(range: preRange, inElement: elementDescriptor)
                }

                if rangeEndLocation < myLength {
                    let postRange = NSRange(location: rangeEndLocation, length: myLength - rangeEndLocation)
                    wrap(range: postRange, inElement: elementDescriptor)
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

        /// Wraps child nodes intersecting the specified range inside new elements with the
        /// specified properties.
        ///
        /// - Parameters:
        ///     - targetRange: the range that must be wrapped.
        ///     - elementDescriptor: the descriptor for the element to wrap the range in.
        ///
        func wrapChildren(intersectingRange targetRange: NSRange, inElement elementDescriptor: ElementNodeDescriptor) {
            
            // Before wrapping a range in a new node, we make sure equivalent element nodes wrapping that range are
            // removed.
            //
            var elementNamesToRemove = elementDescriptor.matchingNames
            
            if !elementNamesToRemove.contains(elementDescriptor.name) {
                elementNamesToRemove.append(elementDescriptor.name)
            }
            
            unwrap(range: targetRange, fromElementsNamed: elementNamesToRemove)

            let mustFindLowestBlockLevelElements = !elementDescriptor.isBlockLevel()

            if mustFindLowestBlockLevelElements {
                let elementsAndIntersections = lowestBlockLevelElements(intersectingRange: targetRange)

                for (element, intersection) in elementsAndIntersections {
                    element.forceWrapChildren(intersectingRange: intersection, inElement: elementDescriptor)
                }
            } else {
                forceWrapChildren(intersectingRange: targetRange, inElement: elementDescriptor)
            }
        }

        /// Force-wraps the specified range inside a node with the specified properties.
        ///
        /// - Important: When the target range matches the receiver's full range we can just wrap the receiver in the
        ///         new node.  We do need to check, however, that either:
        /// - The new node is block-level, or
        /// - The receiver isn't a block-level node either.
        ///
        /// - Parameters:
        ///     - targetRange: the range that must be wrapped.
        ///     - elementDescriptor: the descriptor for the element to wrap the range in.
        ///
        func forceWrap(range targetRange: NSRange, inElement elementDescriptor: ElementNodeDescriptor) {
            
            if NSEqualRanges(targetRange, range()) {
                
                let receiverIsBlockLevel = isBlockLevelElement()
                let newNodeIsBlockLevel = elementDescriptor.isBlockLevel()
                
                let canWrapReceiverInNewNode = newNodeIsBlockLevel || !receiverIsBlockLevel
                
                if canWrapReceiverInNewNode {
                    wrap(inElement: elementDescriptor)
                    return
                }
            }

            forceWrapChildren(intersectingRange: targetRange, inElement: elementDescriptor)
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
        private func forceWrapChildren(intersectingRange targetRange: NSRange, inElement elementDescriptor: ElementNodeDescriptor) {
                
            let childNodesAndRanges = childNodes(intersectingRange: targetRange)
            assert(childNodesAndRanges.count > 0)
            
            let firstChild = childNodesAndRanges[0].child
            let firstChildIntersection = childNodesAndRanges[0].intersection
            
            if let firstEditableChild = firstChild as? EditableNode where !NSEqualRanges(firstChild.range(), firstChildIntersection) {
                firstEditableChild.split(forRange: firstChildIntersection)
            }
            
            if childNodesAndRanges.count > 1 {
                let lastChild = childNodesAndRanges[childNodesAndRanges.count - 1].child
                let lastChildIntersection = childNodesAndRanges[childNodesAndRanges.count - 1].intersection
                
                if let lastEditableChild = lastChild as? EditableNode where !NSEqualRanges(lastChild.range(), lastChildIntersection) {
                    lastEditableChild.split(forRange: lastChildIntersection)
                }
            }
            
            let children = childNodesAndRanges.map({ (child: Node, intersection: NSRange) -> Node in
                return child
            })
            
            wrap(children: children, inElement: elementDescriptor)
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
        func wrap(children newChildren: [Node], inElement elementDescriptor: ElementNodeDescriptor) -> ElementNode {

            guard newChildren.count > 0 else {
                assertionFailure("Avoid calling this method with no nodes.")
                return ElementNode(descriptor: elementDescriptor)
            }

            guard let firstNodeIndex = children.indexOf(newChildren[0]) else {
                fatalError("A node's parent should contain the node. Review the child/parent updating logic.")
            }
            
            guard let lastNodeIndex = children.indexOf(newChildren[newChildren.count - 1]) else {
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
            let rightSibling = pushUp(siblingOrDescendantAtRightSideOf: lastNodeIndex, evaluatedBy: evaluation, bailIf: bailEvaluation)
            let leftSibling = pushUp(siblingOrDescendantAtLeftSideOf: firstNodeIndex, evaluatedBy: evaluation, bailIf: bailEvaluation)

            var childrenToWrap = newChildren
            var result: ElementNode?
            
            if let sibling = rightSibling {
                sibling.prepend(childrenToWrap)
                childrenToWrap = sibling.children
                
                result = sibling
            }
            
            if let sibling = leftSibling {
                sibling.append(childrenToWrap)
                childrenToWrap = sibling.children
                
                result = sibling
                
                if let rightSibling = rightSibling where rightSibling.children.count == 0 {
                    rightSibling.removeFromParent()
                }
            }
            
            if let result = result {
                return result
            } else {
                let newNode = ElementNode(descriptor: elementDescriptor, children: childrenToWrap)
                
                children.insert(newNode, atIndex: firstNodeIndex)
                newNode.parent = self
                
                remove(newChildren, updateParent: false)
                return newNode
            }
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
