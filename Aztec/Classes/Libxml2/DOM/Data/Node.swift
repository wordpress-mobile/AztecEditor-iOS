import Foundation


/// Base class for all node types.
///
public class Node: Equatable, CustomReflectable, Hashable {
    
    public let name: String
    
    // MARK: - Properties: Parent reference
    
    /// A weak reference to the parent of this node.
    ///
    public weak var parent: ElementNode?

    // MARK: - Properties: Editing traits

    var canEditTextRepresentation: Bool = true
    
    // MARK: - CustomReflectable
    
    public var customMirror: Mirror {
        get {
            return Mirror(self, children: ["name": name, "parent": parent as Any])
        }
    }

    // MARK - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    // MARK: - Initializers

    init(name: String) {
        self.name = name
    }

    // MARK: - DOM Queries
    
    func hasAncestor(ofType type: Element) -> Bool {
        var ancestor: ElementNode? = parent
        
        while let currentAncestor = ancestor {
            if currentAncestor.isNodeType(type) {
                return true
            }
        
            ancestor = currentAncestor.parent
        }
        
        return false
    }
    
    /// Checks if the specified node requires a closing paragraph separator.
    ///
    func needsClosingParagraphSeparator() -> Bool {
        guard !hasRightBlockLevelSibling() else {
            return true
        }
        
        return !isLastInTree() && isLastInAncestorEndingInBlockLevelSeparation()
    }

    func isLastIn(blockLevelElement element: ElementNode) -> Bool {
        return element.isBlockLevel() && element.children.last === self
    }

    /// Checks if the receiver is the last node in its parent.
    /// Empty text nodes are filtered to avoid false positives.
    ///
    func isLastInParent() -> Bool {

        guard let parent = parent else {
            return true
        }

        // We are filtering empty text nodes from being considered the last node in our
        // parent node.
        //
        let lastMatchingChildInParent = parent.lastChild(matching: { node -> Bool in
            guard let textNode = node as? TextNode,
                textNode.length() == 0 else {
                    return true
            }

            return false
        })

        return self === lastMatchingChildInParent
    }

    /// Checks if the receiver is the last node in the tree.
    ///
    /// - Note: The verification excludes all child nodes, since this method only cares about
    ///     siblings and parents in the tree.
    ///
    func isLastInTree() -> Bool {

        guard let parent = parent else {
            return true
        }

        return isLastInParent() && parent.isLastInTree()
    }

    /// Checks if the receiver is the last node in a block-level ancestor.
    ///
    /// - Note: The verification excludes all child nodes, since this method only cares about
    ///     siblings and parents in the tree.
    ///
    func isLastInBlockLevelAncestor() -> Bool {

        guard let parent = parent else {
            return false
        }

        return isLastInParent() &&
            (parent.isBlockLevel() || parent.isLastInBlockLevelAncestor())
    }

    func hasRightBlockLevelSibling() -> Bool {
        if let rightSibling = rightSibling() as? ElementNode, rightSibling.isBlockLevel() {
            return true
        } else {
            return false
        }
    }

    func isLastInAncestorEndingInBlockLevelSeparation() -> Bool {
        guard let parent = parent else {
            return false
        }

        let lastIndexResult = parent.children.lastIndex { (node) -> Bool in
            if node is ElementNode {
                return true
            } else if let textNode = node as? TextNode {
                let text = textNode.sanitizedText()
                
                return text.count > 0
            } else if node is CommentNode {
                return true
            }

            return false
        }

        guard let lastChildIndex = lastIndexResult else {
            return false
        }

        return parent.children[lastChildIndex] === self
            && (parent.isBlockLevel()
                || parent.hasRightBlockLevelSibling()
                || parent.isLastInAncestorEndingInBlockLevelSeparation())
    }

    /// Retrieves the right sibling for a node.
    ///
    /// - Returns: the right sibling, or `nil` if none exists.
    ///
    public func rightSibling() -> Node? {

        guard let parent = parent else {
            return nil
        }

        let index = parent.children.firstIndex { node -> Bool in
            return node === self
        }!

        return parent.sibling(rightOf: index)
    }

    // MARK: - Node Equatable

    func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? Node else {
            return false
        }

        return name == rhs.name
    }

    public static func ==(lhs: Node, rhs: Node) -> Bool {
        guard type(of: lhs) == type(of: rhs) else {
            return false
        }

        guard ObjectIdentifier(lhs) != ObjectIdentifier(rhs) else {
            return true
        }

        return lhs.isEqual(rhs)
    }
    
    // MARK: - Raw text representation of nodes
    
    public func rawText() -> String {
        return ""
    }
}
