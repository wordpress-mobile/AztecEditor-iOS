import Foundation

extension Libxml2 {

    /// This class describes a comment node for the purpose of either:
    ///
    /// - Searching for a matching element node, or
    /// - Creating it.
    ///
    class CommentNodeDescriptor: NodeDescriptor {
        let comment: String

        // MARK: - CustomReflectable

        public override var customMirror: Mirror {
            get {
                return Mirror(self, children: ["name": name, "comment": comment])
            }
        }

        init(name: String, comment: String) {
            self.comment = comment
            super.init(name: name)
        }
    }
}
