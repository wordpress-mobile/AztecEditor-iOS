import Foundation

extension Libxml2 {
    /// Comment nodes use to hold HTML comments like this: <!-- This is a comment -->
    ///
    class CommentNode: Node {

        var text: String

        init(text: String) {
            self.text = text

            super.init(name: "text")
        }

        override func customMirror() -> Mirror {
            return Mirror(self, children: ["type": "text", "name": name, "text": text, "parent": parent.debugDescription], ancestorRepresentation: .Suppressed)
        }

        /// Node length.
        ///
        override func length() -> Int {
            return 1
        }
    }
}
