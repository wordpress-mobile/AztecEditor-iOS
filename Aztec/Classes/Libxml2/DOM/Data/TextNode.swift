import Foundation

extension Libxml2 {
    /// Text nodes.  Cannot have child nodes (for now, not sure if we will need them).
    ///
    class TextNode: Node {

        var contents: String

        // MARK: - CustomReflectable
        
        override public var customMirror: Mirror {
            get {
                return Mirror(self, children: ["type": "text", "name": name, "text": contents, "parent": parent.debugDescription], ancestorRepresentation: .suppressed)
            }
        }
        
        // MARK: - Initializers
        
        init(text: String) {
            contents = text

            super.init(name: "text")
        }

        /// Node length.
        ///
        func length() -> Int {
            return contents.characters.count
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

        // MARK - Hashable

        override public var hashValue: Int {
            return name.hashValue ^ contents.hashValue
        }

        // MARK: - LeafNode
        
        func text() -> String {
            return contents
        }

        // MARK: - Node Equatable

        static func ==(lhs: Libxml2.TextNode, rhs: Libxml2.TextNode) -> Bool {
            return lhs.name == rhs.name && lhs.contents == rhs.contents
        }
    }
}
