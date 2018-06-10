import Foundation

/// Converts an `ElementNode` into its `String` representation.
///
public protocol ElementToStringConverter {
    
    typealias ChildrenSerializer = (_: [Node]) -> String
    
    /// Converts an instance of `ElementNode` into its `String` representation.
    ///
    /// - Parameters:
    ///     - element: ElementNode that's about to be converted.
    ///     - childrenSerializer: Callback to serialize child elements.
    ///
    /// - Returns: `String` instance, representing the received element.
    ///
    func convert(
        _ element: ElementNode,
        childrenSerializer serializeChildren: ChildrenSerializer) -> String
}
