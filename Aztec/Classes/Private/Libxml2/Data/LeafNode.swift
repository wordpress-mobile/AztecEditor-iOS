import Foundation

/// Represents any node that can be a leaf in the DOM tree.
///
protocol LeafNode {
    
    /// Returns the text representation of the node.
    ///
    func text() -> String
}
