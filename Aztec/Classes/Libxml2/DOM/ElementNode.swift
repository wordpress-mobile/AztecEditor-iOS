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

        fileprivate(set) var attributes = [Attribute]()
        fileprivate(set) var children: [Node]

        internal var standardName: StandardElementType? {
            get {
                return StandardElementType(rawValue: name)
            }
        }
        
        // MARK: - CustomReflectable
        
        override public var customMirror: Mirror {
            get {
                return Mirror(self, children: ["type": "element", "name": name, "parent": parent.debugDescription, "attributes": attributes, "children": children], ancestorRepresentation: .suppressed)
            }
        }
        
        // MARK: - Initializers

        init(name: String, attributes: [Attribute], children: [Node], editContext: EditContext? = nil) {
            self.attributes.append(contentsOf: attributes)
            self.children = children

            super.init(name: name, editContext: editContext)

            for child in children {

                if let parent = child.parent {
                    parent.remove(child)
                }

                child.parent = self
            }
        }
        
        convenience init(descriptor: ElementNodeDescriptor, children: [Node] = [], editContext: EditContext? = nil) {
            self.init(name: descriptor.name, attributes: descriptor.attributes, children: children, editContext: editContext)
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
                if let attribute = attribute as? StringAttribute, attribute.name == attributeName {
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
                if let attribute = attribute as? StringAttribute, attribute.name == attributeName {
                    attribute.value = value
                    return
                }
            }
            
            attributes.append(StringAttribute(name: attributeName, value: value))
        }

        /// Check if the last of this children element is a block level element
        ///
        /// - Returns: true if the last child of this element is a block level element, false otherwise
        ///
        func isLastChildBlockLevelElement() -> Bool {
            let childrenIgnoringEmptyTextNodes = children.filter { (node) -> Bool in
                if let textNode = node as? TextNode {
                    return !textNode.text().isEmpty
                }
                return true
            }
            if let lastChild = childrenIgnoringEmptyTextNodes.last as? ElementNode {
               return lastChild.isBlockLevelElement()
            }
            return false
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

        func isNodeType(_ type:StandardElementType) -> Bool {
            return type.equivalentNames.contains(name.lowercased())
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
            
            for (index, child) in children.enumerated() {
                
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
        func enumerateChildNodes(intersectingRange targetRange: NSRange, preferLeftNode: Bool = true, onMatchFound matchFound: (_ child: Node, _ intersection: NSRange) -> Void ) {

            var offset = Int(0)

            for (index, child) in children.enumerated() {

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

                    matchFound(child, intersectionRangeInChildCoordinates)
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
        func enumerateLowestBlockLevelElements(intersectingRange targetRange: NSRange, onMatchFound matchFound: @escaping (_ element: ElementNode, _ intersection: NSRange) -> Void ) {

            enumerateLowestBlockLevelElements(
                intersectingRange: targetRange,
                onMatchNotFound: { (range) in
                    matchFound(self, range)
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
        fileprivate func enumerateLowestBlockLevelElements(intersectingRange targetRange: NSRange, onMatchNotFound matchNotFound: @escaping (_ range: NSRange) -> Void, onMatchFound matchFound: @escaping (_ element: ElementNode, _ intersection: NSRange) -> Void ) {

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
        fileprivate func enumerateLowestElements(intersectingRange targetRange: NSRange, bailIf bailCondition: @escaping (_ element: ElementNode) -> Bool, onMatchNotFound matchNotFound: @escaping (_ range: NSRange) -> Void, onMatchFound matchFound: @escaping (_ element: ElementNode, _ intersection: NSRange) -> Void ) {
            
            var rangeWithoutMatch: NSRange?
            var offset = Int(0)

            for child in children {

                let childLength = child.length()
                let childRange = NSRange(location: offset, length: childLength)

                if let intersection = targetRange.intersect(withRange: childRange) {
                    
                    let intersectionInChildCoordinates = NSRange(location: intersection.location - offset, length: intersection.length)

                    if let childElement = child as? ElementNode, !bailCondition(childElement) {
                        
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
                                    if !bailCondition(strongSelf) {
                                        matchFound(strongSelf, previousRangeWithoutMatch)
                                        rangeWithoutMatch = nil
                                    } else {
                                        matchNotFound(previousRangeWithoutMatch)
                                    }
                                }

                                matchFound(child, intersection)
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
                if !bailCondition(self) {
                    matchFound(self, previousRangeWithoutMatch)
                    rangeWithoutMatch = nil
                } else {
                    matchNotFound(previousRangeWithoutMatch)
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
        func lowestElementNodeWrapping(_ range: NSRange) -> ElementNode {

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
        func lowestTextNodeWrapping(_ range: NSRange) -> TextNode? {

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
        func leafNodesWrapping(_ range: NSRange) -> [(node: LeafNode, range: NSRange)] {

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

                        results.append(contentsOf: elementNode.leafNodesWrapping(offsetRange))
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
        
        fileprivate func find<T: Node>(leftSideDescendantEvaluatedBy evaluate: ((T) -> Bool), bailIf bail: ((T) -> Bool) = { _ in return false }) -> T? {
            
            guard children.count > 0 else {
                return nil
            }
            
            let child = children[0]
            
            if let match = child as? T, !bail(match) && evaluate(match) {
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
        
        fileprivate func find<T: Node>(rightSideDescendantEvaluatedBy evaluate: ((T) -> Bool), bailIf bail: ((T) -> Bool) = { _ in return false }) -> T? {
            
            guard children.count > 0 else {
                return nil
            }
            
            let child = children[children.count - 1]
            
            if let match = child as? T, !bail(match) && evaluate(match) {
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

            if isBlockLevelElement() && !isLastChildBlockLevelElement() {
                text += "\n"
            }

            if let nodeType = standardName {
                text = nodeType.implicitRepresentation(forContent: text)
            }

            return text
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
                
                text = text + nodeText.substring(with: range)
            }

            return text
        }

        // MARK: - DOM modification

        /// Appends a node to the list of children for this element.
        ///
        /// - Parameters:
        ///     - child: the node to append.
        ///
        func append(_ child: Node) {
            child.removeFromParent()
            children.append(child)
            child.parent = self
        }
        
        /// Appends a node to the list of children for this element.
        ///
        /// - Parameters:
        ///     - child: the node to append.
        ///
        func append(_ children: [Node]) {
            for child in children {
                append(child)
            }
        }

        /// Prepends a node to the list of children for this element.
        ///
        /// - Parameters:
        ///     - child: the node to prepend.
        ///
        func prepend(_ child: Node) {
            insert(child, at: 0)
        }

        /// Prepends children to the list of children for this element.
        ///
        /// - Parameters:
        ///     - children: the nodes to prepend.
        ///
        func prepend(_ children: [Node]) {
            for index in stride(from: (children.count - 1), through: 0, by: -1) {
                prepend(children[index])
            }
        }
        
        /// Inserts a node into the list of children for this element.
        ///
        /// - Parameters:
        ///     - child: the node to insert.
        ///     - index: the position where to insert the node.
        ///
        func insert(_ child: Node, at index: Int) {
            child.removeFromParent()
            children.insert(child, at: index)
            child.parent = self
        }

        /// Replaces the specified node with several new nodes.
        ///
        /// - Parameters:
        ///     - child: the node to remove.
        ///     - newChildren: the new child nodes to insert.
        ///
        func replace(child: Node, with newChildren: [Node]) {
            guard let childIndex = children.index(of: child) else {
                fatalError("This case should not be possible. Review the logic triggering this.")
            }

            for newNode in newChildren {
                newNode.parent = self
            }

            children.remove(at: childIndex)
            children.insert(contentsOf: newChildren, at: childIndex)
        }

        /// Removes the receiver from its parent.
        ///
        func removeFromParent(undoManager: UndoManager? = nil) {
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
        func remove(_ child: Node, updateParent: Bool = true) {

            guard let index = children.index(of: child) else {
                assertionFailure("Can't remove a node that's not a child.")
                return
            }

            children.remove(at: index)

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
        func remove(_ children: [Node], updateParent: Bool = true) {

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
        /// - Parameters:
        ///     - splitLocation: marks the split location.
        ///
        /// - Returns: the requested nodes.
        ///
        fileprivate func splitChildren(after splitLocation: Int) -> [Node] {

            var result = [Node]()
            var childOffset = Int(0)

            for child in children {
                let childLength = child.length()
                let childEndLocation = childOffset + childLength
                
                if childOffset >= splitLocation {
                    result.append(child)
                } else if let childEditableNode = child as? EditableNode, childOffset < splitLocation && childEndLocation > splitLocation {
                    
                    let splitLocationInChild = splitLocation - childOffset
                    let splitRange = NSRange(location: splitLocationInChild, length: childEndLocation - splitLocationInChild)
                    
                    childEditableNode.split(forRange: splitRange)
                    result.append(child)
                }
                
                childOffset = childOffset + childLength
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
        fileprivate func splitChildren(before splitLocation: Int) -> [Node] {
            
            var result = [Node]()
            var childOffset = Int(0)
            
            for child in children {
                let childLength = child.length()
                let childEndLocation = childOffset + childLength
                
                if childEndLocation <= splitLocation {
                    result.append(child)
                } else if let childEditableNode = child as? EditableNode, childOffset < splitLocation && childEndLocation > splitLocation {
                    
                    let splitLocationInChild = splitLocation - childOffset
                    let splitRange = NSRange(location: 0, length: splitLocationInChild)
                    
                    childEditableNode.split(forRange: splitRange)
                    result.append(child)
                }
                
                childOffset = childOffset + childLength
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
        fileprivate func pushUp<T: Node>(siblingOrDescendantAtLeftSideOf childIndex: Int, evaluatedBy evaluation: ((T) -> Bool), bailIf bail: ((T) -> Bool) = { _ in return false }) -> T? {
            
            guard let theSibling: T = sibling(leftOf: childIndex), !bail(theSibling) else {
                return nil
            }
            
            if evaluation(theSibling) {
                return theSibling
            }
            
            guard let element = theSibling as? ElementNode else {
                return nil
            }
            
            return element.pushUp(rightSideDescendantEvaluatedBy: evaluation, bailIf: bail)
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
        func pushUp<T: Node>(leftSideDescendantEvaluatedBy evaluationClosure: ((T) -> Bool), bailIf bail: ((T) -> Bool) = { _ in return false }) -> T? {
            
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
                    
                    guard let parentIndex = grandParent.children.index(of: parent) else {
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
        fileprivate func pushUp<T: Node>(siblingOrDescendantAtRightSideOf childIndex: Int, evaluatedBy evaluation: ((T) -> Bool), bailIf bail: ((T) -> Bool) = { _ in return false }) -> T? {
            
            guard let theSibling: T = sibling(rightOf: childIndex), !bail(theSibling) else {
                    return nil
            }
            
            if evaluation(theSibling) {
                return theSibling
            }
            
            guard let element = theSibling as? ElementNode else {
                return nil
            }
            
            return element.pushUp(leftSideDescendantEvaluatedBy: evaluation, bailIf: bail)
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
        func pushUp<T: Node>(rightSideDescendantEvaluatedBy evaluationClosure: ((T) -> Bool), bailIf bail: ((T) -> Bool) = { _ in return false }) -> T? {
            
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
                    
                    guard let parentIndex = grandParent.children.index(of: parent) else {
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
        func insert(_ string: String, at index: Int) {

            guard index <= children.count else {
                fatalError("The specified index is outside the range of possible indexes for insertion.")
            }
            
            let previousIndex = index - 1
            
            if previousIndex >= 0, let previousTextNode = children[previousIndex] as? TextNode {
                previousTextNode.append(string)
            } else if index < children.count, let nextTextNode = children[index] as? TextNode {
                nextTextNode.prepend(string)
            } else {
                insert(TextNode(text: string, editContext: editContext), at: index)
            }
        }

        /// Inserts the specified string at the specified location.
        ///
        func insert(_ string: String, atLocation location: Int) {

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
            
            for (index, childAndIntersection) in childrenAndIntersections.enumerated() {
                
                let child = childAndIntersection.child
                let intersection = childAndIntersection.intersection
                
                if let childEditableNode = child as? EditableNode {
                    if index == 0 && replaceTextFromFirstChild {
                        childEditableNode.replaceCharacters(inRange: intersection, withString: string, inheritStyle: inheritStyle)
                    } else if intersection.length > 0 {
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
            
            let imgNode = ElementNode(descriptor: elementDescriptor, editContext: editContext)
            
            guard let index = textNode.parent?.children.index(of: textNode) else {
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
            var trueLength = length()
            if isBlockLevelElement() {
                trueLength -= 1
            }
            
            guard location != 0 && location != trueLength - 1 else {
                // Nothing to split, move along...
                return
            }
            
            guard location > 0 && location < trueLength - 1 else {
                assertionFailure("Specified range is out-of-bounds.")
                return
            }
            
            guard let parent = parent,
                let nodeIndex = parent.children.index(of: self) else {
                    assertionFailure("Can't split a node without a parent.")
                    return
            }
            
            let postNodes = splitChildren(after: location)
            
            if postNodes.count > 0 {
                let newElement = ElementNode(name: name, attributes: attributes, children: postNodes, editContext: editContext)
                
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
                let nodeIndex = parent.children.index(of: self) else {
                    assertionFailure("Can't split a node without a parent.")
                    return
            }

            let postNodes = splitChildren(after: range.location + range.length)

            if postNodes.count > 0 {
                let newElement = ElementNode(name: name, attributes: attributes, children: postNodes, editContext: editContext)

                parent.insert(newElement, at: nodeIndex + 1)
                remove(postNodes, updateParent: false)
            }

            let preNodes = splitChildren(before: range.location)

            if preNodes.count > 0 {
                let newElement = ElementNode(name: name, attributes: attributes, children: preNodes, editContext: editContext)

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
            if elementNames.contains(name) {
                unwrapChildren()
            }
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
        func unwrap(range: NSRange, fromElementsNamed elementNames: [String]) {
            
            guard children.count > 0 else {
                return
            }
            
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
        func unwrapChildren(undoManager: UndoManager? = nil) {
            if let parent = parent {
                parent.replace(child: self, with: self.children)
            } else {
                for child in children {
                    child.parent = nil
                }

                children.removeAll()
            }
        }

        func unwrapChildren(_ children: [Node], fromElementsNamed elementNames: [String]) {

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
            if isBlockLevelElement() && (range.location == self.length() - 1) {
                    return
            }

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
                    // 0-length intersections are possible, but they make no sense in the context
                    // of wrapping content inside new elements.  We should ignore zero-length
                    // intersections.
                    //
                    guard intersection.length > 0 else {
                        continue
                    }
                    
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
        fileprivate func forceWrapChildren(intersectingRange targetRange: NSRange, inElement elementDescriptor: ElementNodeDescriptor) {
            
            assert(range().contains(range: targetRange))
            
            let childNodesAndRanges = childNodes(intersectingRange: targetRange)
            
            guard childNodesAndRanges.count > 0 else {
                // It's possible the range may not intersect any child node, if this node is adding
                // any special characters for formatting purposes in visual mode.  For instance some
                // nodes add a `\n` character at their end.
                //
                return
            }
            
            let firstChild = childNodesAndRanges[0].child
            let firstChildIntersection = childNodesAndRanges[0].intersection
            
            if let firstEditableChild = firstChild as? EditableNode, !NSEqualRanges(firstChild.range(), firstChildIntersection) {
                firstEditableChild.split(forRange: firstChildIntersection)
            }
            
            if childNodesAndRanges.count > 1 {
                let lastChild = childNodesAndRanges[childNodesAndRanges.count - 1].child
                let lastChildIntersection = childNodesAndRanges[childNodesAndRanges.count - 1].intersection
                
                if let lastEditableChild = lastChild as? EditableNode, !NSEqualRanges(lastChild.range(), lastChildIntersection) {
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
        @discardableResult
        func wrap(children newChildren: [Node], inElement elementDescriptor: ElementNodeDescriptor) -> ElementNode {

            guard newChildren.count > 0 else {
                assertionFailure("Avoid calling this method with no nodes.")
                return ElementNode(descriptor: elementDescriptor, editContext: editContext)
            }

            guard let firstNodeIndex = children.index(of: newChildren[0]) else {
                fatalError("A node's parent should contain the node. Review the child/parent updating logic.")
            }
            
            guard let lastNodeIndex = children.index(of: newChildren[newChildren.count - 1]) else {
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
                
                if let rightSibling = rightSibling, rightSibling.children.count == 0 {
                    rightSibling.removeFromParent()
                }
            }

            if let result = result {
                return result
            } else {
                let newNode = ElementNode(descriptor: elementDescriptor, children: childrenToWrap, editContext: editContext)
                
                children.insert(newNode, at: firstNodeIndex)
                newNode.parent = self
                
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

        // MARK: - CustomReflectable
        
        override public var customMirror: Mirror {
            get {
                return Mirror(self, children: ["name": name, "children": children])
            }
        }
        
        // MARK: - Initializers

        init(children: [Node], editContext: EditContext? = nil) {
            super.init(name: type(of: self).name, attributes: [], children: children, editContext: editContext)
        }
    }
}
