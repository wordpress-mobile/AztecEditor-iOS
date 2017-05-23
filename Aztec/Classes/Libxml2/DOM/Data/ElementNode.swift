import Foundation
import UIKit

extension Libxml2 {

    /// Element node.  Everything but text basically.
    ///
    class ElementNode: Node {

        fileprivate(set) var attributes = [Attribute]()
        var children: [Node]

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

        // MARK: - Constants

        fileprivate let defaultLengthForUnsupportedElements = 1

        // MARK: - Editing behavior configuration

        static let elementsThatSpanASingleLine: [StandardElementType] = [.li]
        
        // MARK: - Initializers

        init(name: String, attributes: [Attribute], children: [Node]) {
            self.attributes.append(contentsOf: attributes)
            self.children = children

            super.init(name: name)

            for child in children {

                if let parent = child.parent {
                    parent.remove(child)
                }

                child.parent = self
            }
        }

        convenience init(type: StandardElementType, attributes: [Attribute] = [], children: [Node] = []) {
            self.init(name: type.rawValue, attributes: attributes, children: children)
        }
        
        convenience init(descriptor: ElementNodeDescriptor, children: [Node] = []) {
            self.init(name: descriptor.name, attributes: descriptor.attributes, children: children)
        }
        
        // MARK: - Node Constructors
        
        static func `break`() -> ElementNode {
            return ElementNode(name: StandardElementType.br.rawValue, attributes: [], children: [])
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
        
        /// Check if the node is the first child in its parent node.
        ///
        /// - Returns: `true` if the node is the first child in it's parent.  `false` otherwise.
        ///
        func isFirstChildInParent() -> Bool {
            guard let parent = parent else {
                assertionFailure("This scenario should not be possible.  Review the logic.")
                return false
            }
            
            guard let first = parent.children.first else {
                return false
            }
            
            return first === self
        }
        
        /// Check if the node is the last child in its parent node.
        ///
        /// - Returns: `true` if the node is the last child in it's parent.  `false` otherwise.
        ///
        func isLastChildInParent() -> Bool {
            guard let parent = parent else {
                assertionFailure("This scenario should not be possible.  Review the logic.")
                return false
            }
            
            guard let last = parent.children.last else {
                return false
            }
            
            return last === self
        }

        func isNodeType(_ type: StandardElementType) -> Bool {
            return type.equivalentNames.contains(name.lowercased())
        }

        /// Retrieves the last child matching a specific filtering closure.
        ///
        /// - Parameters:
        ///     - filter: the filtering closure.
        ///
        /// - Returns: the requested node, or `nil` if there are no nodes matching the request.
        ///
        func lastChild(matching filter: (Node) -> Bool) -> Node? {
            return children.filter(filter).last
        }

        // MARK: - DOM Queries
        
        /// Returns the index of the specified child node.  This method should only be called when
        /// there's 100% certainty that this node should contain the specified child node, as it
        /// fails otherwise.
        ///
        /// Call `children.indexOf()` if you need to test the parent-child relationship instead.
        ///
        /// - Parameters:
        ///     - childNode: the child node to find the index of.
        ///
        /// - Returns: the index of the specified child node.
        ///
        func indexOf(childNode: Node) -> Int {
            guard let index = children.index(of: childNode) else {
                fatalError("Broken parent-child relationship found.")
            }
            
            return index
        }
        /*
        /// Returns the index of the child node intersecting the specified location.
        ///
        /// - Parameters:
        ///     - location: the text location that the child node must intersect.
        ///
        /// - Returns: The index of the child node intersecting the specified text location.  If the text location is
        ///         exactly between two nodes, the left hand node will always be returned.  The only exception to this
        ///         rule is for text location zero, which will always result in index zero being returned.
        ///
        func indexOf(childNodeIntersecting location: Int) -> (index: Int, intersection: Int)  {
            
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
 */
/*
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
        }*/
/*
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
*/
        typealias NodeMatchTest = (_ node: Node) -> Bool
        typealias NodeIntersectionReport = (_ node: Node, _ intersection: NSRange) -> Void
        typealias RangeReport = (_ range: NSRange) -> Void
/*
        /// Enumerates the descendants that match the specified condition, and intersection range
        /// between those descendants and the specified range constraint.
        ///
        /// - Important: the receiver is also tested.
        ///
        /// - Parameters:
        ///     - targetRange: the range we're intersecting the child nodes with.  The range is in
        ///             the receiver's coordinate system.
        ///     - isMatch: a closure that evaluates nodes for matches.
        ///     - matchFound: the closure to execute for each child element intersecting
        ///             `targetRange`.
        ///     - matchNotFound: the closure to execute for any subrange of `targetRange` that
        ///             doesn't have a block-level node intersecting it.
        ///
        func enumerateFirstDescendants(
            in targetRange: NSRange,
            matching isMatch: NodeMatchTest,
            onMatchFound matchFound: NodeIntersectionReport?,
            onMatchNotFound matchNotFound: RangeReport?) {

            assert(range().contains(targetRange))
            assert(matchFound != nil || matchNotFound != nil)

            guard !isMatch(self) else {
                matchFound?(self, targetRange)
                return
            }

            guard children.count > 0 else {
                matchNotFound?(targetRange)
                return
            }

            var rangeWithoutMatch: NSRange?
            var offset = Int(0)

            let ensureProcessingOfRangeWithoutMatch = { () in
                if let previousRangeWithoutMatch = rangeWithoutMatch {
                    matchNotFound?(previousRangeWithoutMatch)
                    rangeWithoutMatch = nil
                }
            }

            let processMatchFound = { (child: Node, intersection: NSRange) -> () in
                ensureProcessingOfRangeWithoutMatch()
                matchFound?(child, intersection)
            }

            let extendRangeWithoutMatch = { (range: NSRange) in
                if let previousRangeWithoutMatch = rangeWithoutMatch {
                    rangeWithoutMatch = NSRange(location: previousRangeWithoutMatch.location, length: previousRangeWithoutMatch.length + range.length)
                } else {
                    rangeWithoutMatch = range
                }
            }

            for child in children {

                let childLength = child.length()
                let childRange = NSRange(location: offset, length: childLength)

                if let intersection = targetRange.intersect(withRange: childRange) {
                    if isMatch(child) {
                        processMatchFound(child, intersection)
                    } else if let childElement = child as? ElementNode {
                        let intersectionInChildCoordinates = NSRange(location: intersection.location - offset, length: intersection.length)

                        childElement.enumerateFirstDescendants(
                            in: intersectionInChildCoordinates,
                            matching: isMatch,
                            onMatchFound: { (child, intersection) in
                                processMatchFound(child, intersection)
                            },
                            onMatchNotFound: { (range) in
                                let adjustedRange = NSRange(location: range.location + offset, length: range.length)
                                extendRangeWithoutMatch(adjustedRange)
                        })
                    } else {
                        extendRangeWithoutMatch(intersection)
                    }
                }

                offset += childLength
            }

            ensureProcessingOfRangeWithoutMatch()
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
 */
/*
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
 */
        
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
        func find<T: Node>(leftSideDescendantEvaluatedBy evaluate: ((T) -> Bool), bailIf bail: ((T) -> Bool) = { _ in return false }) -> T? {
            
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
        func find<T: Node>(rightSideDescendantEvaluatedBy evaluate: ((T) -> Bool), bailIf bail: ((T) -> Bool) = { _ in return false }) -> T? {
            
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
        /*
        override func text() -> String {

            guard isSupportedByEditor() else {
                return String(.objectReplacement)
            }

            if let nodeType = standardName,
                let implicitRepresentation = nodeType.implicitRepresentation() {
                
                return implicitRepresentation.string
            }

            var text = ""

            for child in children {
                text = text + child.text()
            }

            if needsClosingParagraphSeparator() {
                text.append(String(.paragraphSeparator))
            }

            return text
        }*/

        // MARK: - DOM modification

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

            registerUndoForRemove(child)
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
            for child in children {
                remove(child, updateParent: updateParent)
            }
        }

        // MARK: - EditableNode
        /*
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
        func insert(_ string: String, atNodeIndex index: Int) {

            guard index <= children.count else {
                fatalError("The specified index is outside the range of possible indexes for insertion.")
            }
            
            let previousIndex = index - 1
            
            if previousIndex >= 0, let previousTextNode = children[previousIndex] as? TextNode {
                previousTextNode.append(string)
            } else if index < children.count, let nextTextNode = children[index] as? TextNode {
                nextTextNode.prepend(string)
            } else {
                // It's not great having to set empty text and then append text to it.  The reason
                // we're doing it here is that if the text contains line-breaks, they will only
                // be processed as BR tags if the text is set after construction.
                //
                // This code can be improved but this "hack" will allow us to postpone the necessary
                // code restructuration.
                //
                let textNode = TextNode(text: "")
                insert(textNode, at: index)
                textNode.append(string)
            }
        }

        /// Replace characters in targetRange by a node with the name in nodeName and attributes
        ///
        /// - parameter targetRange: The range to replace
        /// - parameter descriptor:  The descriptor for the element to replace the text with.
        ///
        func replaceCharacters(in targetRange: NSRange, with descriptor: NodeDescriptor) {

            let node: Node
            if let descriptor = descriptor as? ElementNodeDescriptor {
                node = ElementNode(descriptor: descriptor)
            } else if let descriptor = descriptor as? CommentNodeDescriptor {
                node = CommentNode(text: descriptor.comment)
            } else {
                fatalError("Unsupported Node Descriptor")
            }

            replaceCharacters(in: targetRange, with: node)
        }

        /// Replace characters in targetRange by a node with the name in nodeName and attributes
        ///
        /// - parameter targetRange: The range to replace
        /// - parameter node:  The Element to replace the text with.
        ///
        func replaceCharacters(in targetRange: NSRange, with node: Node) {

            guard let textNode = lowestTextNodeWrapping(targetRange) else {
                return
            }

            let absoluteLocation = textNode.absoluteLocation()
            let localRange = NSRange(location: targetRange.location - absoluteLocation, length: targetRange.length)
            textNode.split(forRange: localRange)

            guard let index = textNode.parent?.children.index(of: textNode) else {
                assertionFailure("Can't remove a node that's not a child.")
                return
            }

            guard let textNodeParent = textNode.parent else {
                return
            }

            textNodeParent.insert(node, at: index)
            textNodeParent.remove(textNode)
        }
 */

        // MARK: - Unwrapping

        func unwrap(fromElementsNamed elementNames: [String]) {
            if elementNames.contains(name) {
                unwrapChildren()
            }
        }

        /// Unwraps the receiver's children from the receiver.
        ///
        @discardableResult
        func unwrapChildren(undoManager: UndoManager? = nil) -> [Node] {

            let result = children

            if let parent = parent {
                parent.replace(child: self, with: children)
            } else {
                for child in children {
                    child.parent = nil
                }

                children.removeAll()
            }

            return result
        }

        func unwrapChildren(_ children: [Node], fromElementsNamed elementNames: [String]) {

            for child in children {

                guard let childElement = child as? ElementNode else {
                    continue
                }

                childElement.unwrap(fromElementsNamed: elementNames)
            }
        }

        // MARK: - Editing behavior

        // MARK: - Undo Support

        private func registerUndoForRemove(_ child: Node) {
            /*
            guard let index = children.index(of: child) else {
                assertionFailure("The specified node is not one of this node's children.")
                return
            }
            
            SharedEditor.currentEditor.undoManager.registerUndo(withTarget: self) { [weak self] target in
                self?.children.insert(child, at: index)
            }
 */
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

        init(children: [Node]) {
            super.init(name: type(of: self).name, attributes: [], children: children)
        }
    }
}
