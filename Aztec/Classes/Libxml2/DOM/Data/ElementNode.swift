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

        typealias NodeMatchTest = (_ node: Node) -> Bool
        typealias NodeIntersectionReport = (_ node: Node, _ intersection: NSRange) -> Void
        typealias RangeReport = (_ range: NSRange) -> Void

        
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
