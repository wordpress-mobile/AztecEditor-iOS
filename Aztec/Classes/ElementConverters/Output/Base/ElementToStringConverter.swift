import Foundation

/// Converts an `ElementNode` into its `String` representation.
///
public protocol ElementToTagConverter {
    
    /// Pair containing a mandatory opening tag, and an optional closing
    /// one.
    ///
    typealias Tag = (opening: String, closing: String?)
    
    /// Converts an instance of `ElementNode` into its `Tag` representation.
    ///
    /// - Parameters:
    ///     - elementNode: ElementNode that's about to be converted.
    ///     - childrenSerializer: Callback to serialize child elements.
    ///
    /// - Returns: the tag that represents this element.
    ///
    func convert(_ elementNode: ElementNode) -> Tag
}
