import Foundation

extension Libxml2 {

    /// This class describes a node for the purpose of either:
    ///
    /// - Searching for a matching element node, or
    /// - Creating it.
    ///
    class NodeDescriptor: CustomReflectable {
        let name: String

        // MARK: - CustomReflectable

        public var customMirror: Mirror {
            get {
                return Mirror(self, children: ["name": name])
            }
        }

        init(name: String) {
            self.name = name
        }
    }
}
