import Foundation

extension Libxml2 {
    /// Comment nodes use to hold HTML comments like this: <!-- This is a comment -->
    ///
    class CommentNode: Node, LeafNode {

        var comment: String

        // MARK: - CustomReflectable
        
        override public var customMirror: Mirror {
            get {
                return Mirror(self, children: ["type": "comment", "name": name, "comment": comment, "parent": parent.debugDescription], ancestorRepresentation: .suppressed)
            }
        }
        
        // MARK: - Initializers
        
        init(text: String, editContext: EditContext? = nil) {
            comment = text

            super.init(name: "comment", editContext: editContext)
        }

        /// Node length.
        ///
        override func length() -> Int {
            let nsString = text() as NSString
            return nsString.length
        }
        
        // MARK: - LeafNode
        
        override func text() -> String {
            return String(.newline)
        }
    }
}
