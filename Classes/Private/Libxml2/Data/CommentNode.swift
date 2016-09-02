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

        override func deleteCharacters(inRange range: NSRange) {
            // No-op, will be removed.
        }

        override func replaceCharacters(inRange range: NSRange, withString string: String) {
            // No-op, will be removed.
        }

        override func split(forRange range: NSRange) {
            // No-op, will be removed.
        }

        override func wrap(range targetRange: NSRange, inNodeNamed nodeName: String, withAttributes attributes: [Attribute]) {
            // No-op, will be removed.
        }
    }
}
