import Foundation

extension Libxml2 {
    /// Text nodes.  Cannot have child nodes (for now, not sure if we will need them).
    ///
    class TextNode: Node, LeafNode {

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
        override func length() -> Int {
            return contents.characters.count
        }

        // MARK: - Node

        /// Checks if the specified node requires a closing paragraph separator.
        ///
        override func needsClosingParagraphSeparator() -> Bool {
            guard length() > 0 else {
                return false
            }

            return super.needsClosingParagraphSeparator()
        }

        // MARK: - LeafNode
        
        override func text() -> String {
            return contents
        }
    }
}
