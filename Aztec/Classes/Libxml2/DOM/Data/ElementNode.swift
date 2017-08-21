import Foundation
import UIKit


/// Element node.  Everything but text basically.
///
class ElementNode: Node {

    var attributes = [Attribute]()
    var children: [Node] {
        didSet {
            for child in children where child.parent !== self {
                child.parent?.remove(child)
                child.parent = self
            }
        }
    }

    private static let headerLevels: [StandardElementType] = [.h1, .h2, .h3, .h4, .h5, .h6]

    class func elementTypeForHeaderLevel(_ headerLevel: Int) -> StandardElementType? {
        if headerLevel < 1 || headerLevel > headerLevels.count {
            return nil
        }
        return headerLevels[headerLevel - 1]
    }

    private static let knownElements: [StandardElementType] = [.a, .b, .br, .blockquote, .del, .div, .em, .h1, .h2, .h3, .h4, .h5, .h6, .hr, .i, .img, .li, .ol, .p, .pre, .s, .span, .strike, .strong, .u, .ul, .video]
    private static let mergeableBlocklevelElements: [StandardElementType] = [.p, .h1, .h2, .h3, .h4, .h5, .h6, .hr, .ol, .ul, .li, .blockquote, .div]
    private static let mergeableStyleElements: [StandardElementType] = [.i, .em, .b, .strong, .strike, .u]

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

    // MARK: - Hashable

    override public var hashValue: Int {
        var hash = name.hashValue

        for attribute in attributes {
            hash ^= attribute.hashValue
        }

        for child in children {
            hash ^= child.hashValue
        }

        return hash
    }


    // MARK: - ElementNode Equatable

    override public func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? ElementNode else {
            return false
        }

        return name == rhs.name && attributes == rhs.attributes && children == rhs.children
    }


    // MARK: - Initializers

    init(name: String, attributes: [Attribute], children: [Node]) {
        self.attributes.append(contentsOf: attributes)
        self.children = children

        super.init(name: name)
    }

    convenience init(type: StandardElementType, attributes: [Attribute] = [], children: [Node] = []) {
        self.init(name: type.rawValue, attributes: attributes, children: children)
    }


    // MARK: - Node Constructors
    
    static func `break`() -> ElementNode {
        return ElementNode(name: StandardElementType.br.rawValue, attributes: [], children: [])
    }
    
    // MARK: - Node Overrides

    /// Checks if the specified node requires a closing paragraph separator.
    ///
    func needsClosingParagraphSeparator() -> Bool {

        guard children.count == 0 else {
            return false
        }

        guard !hasRightBlockLevelSibling() else {
            return true
        }

        return !isLastInTree() && isLastInAncestorEndingInBlockLevelSeparation()
    }

    // MARK: - Node Queries

    func stringValueForAttribute(named attributeName: String) -> String? {

        for attribute in attributes {
            if attribute.name == attributeName {
                return attribute.value.toString()
            }
        }

        return nil
    }

    /// Updates or adds an attribute with the specificed name with the corresponding value
    ///
    /// - Parameters:
    ///     - attributeName: the name of the attribute
    ///     - value: the value for the attribute
    ///
    func updateAttribute(named targetAttributeName: String, value: Attribute.Value) {

        for attribute in attributes {
            if attribute.name == targetAttributeName {
                attribute.value = value
                return
            }
        }

        let attribute = Attribute(name: targetAttributeName, value: value)
        
        attributes.append(attribute)
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


    /// Indicates whether the children of the specified node can be merged in, or not.
    ///
    /// - Parameters:
    ///     - node: Target node for which we'll determine Merge-ability status.
    ///
    /// - Returns: true if both nodes can be merged, or not.
    ///
    func canMergeChildren(of node: ElementNode, blocklevelEnforced: Bool) -> Bool {
        guard name == node.name && Set(attributes) == Set(node.attributes) else {
            return false
        }

        guard let standardName = self.standardName else {
            return false
        }

        guard blocklevelEnforced else {
            return ElementNode.mergeableStyleElements.contains(standardName)
        }

        return ElementNode.mergeableBlocklevelElements.contains(standardName)
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

    typealias NodeMatchTest = (_ node: Node) -> Bool
    typealias NodeIntersectionReport = (_ node: Node, _ intersection: NSRange) -> Void
    typealias RangeReport = (_ range: NSRange) -> Void
    
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
        
        guard childIndex < children.count - 1 else {
            return nil
        }

        let siblingNode = children[childIndex + 1]

        // Ignore empty text nodes.
        //
        if let textSibling = siblingNode as? TextNode, textSibling.length() == 0 {
            return sibling(rightOf: childIndex + 1)
        }

        return siblingNode as? T
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


    // MARK: - Editing behavior

    func isSupportedByEditor() -> Bool {

        guard let standardName = standardName else {
            return false
        }

        return ElementNode.knownElements.contains(standardName)
    }
}


// MARK: - RootNode

class RootNode: ElementNode {

    static let name = "aztec.htmltag.rootnode"

    override var parent: ElementNode? {
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

    // MARK: - Overriden Methods

    override func isSupportedByEditor() -> Bool {
        return true
    }
}
