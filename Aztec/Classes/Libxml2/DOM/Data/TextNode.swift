import Foundation


/// Text nodes.  Cannot have child nodes (for now, not sure if we will need them).
///
public class TextNode: Node {

    let contents: String

    // MARK: - CustomReflectable
    
    override public var customMirror: Mirror {
        get {
            return Mirror(self, children: ["type": "text", "name": name, "text": contents, "parent": parent.debugDescription], ancestorRepresentation: .suppressed)
        }
    }
    
    // MARK: - Initializers
    
    public init(text: String) {
        contents = text

        super.init(name: "text")
    }

    /// Node length.
    ///
    func length() -> Int {
        return contents.count
    }

    // MARK: - Node

    /// Checks if the specified node requires a closing paragraph separator.
    ///
    func needsClosingParagraphSeparator() -> Bool {
        guard length() > 0 else {
            return false
        }

        guard !hasRightBlockLevelSibling() else {
            return true
        }

        return !isLastInTree() && isLastInAncestorEndingInBlockLevelSeparation()
    }

    // MARK: - LeafNode
    
    public func text() -> String {
        return contents
    }

    // MARK - Hashable

    override public var hashValue: Int {
        return name.hashValue ^ contents.hashValue
    }

    // MARK: - Equatable

    override public func isEqual(_ object: Any?) -> Bool {
        guard let textNode = object as? TextNode else {
            return false
        }
        return self.name == textNode.name && self.contents == textNode.contents
    }    
}
