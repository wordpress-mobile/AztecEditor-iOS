import UIKit

/// ElementConverters take an HTML Element that don't have a textual representation and return a special value to
/// represent it (e.g. `<img>` or `<video>`). To apply a style to a piece of text, use `AttributeFormatter`.
///
public protocol ElementConverter {
    
    typealias ContentSerializer = (_ elementNode: ElementNode, _ intrinsicRepresentation: NSAttributedString?, _ inheriting: [NSAttributedString.Key:Any], _ implicitRepresentationBeforeChildren: Bool) -> NSAttributedString
    
    /// Converts an instance of ElementNode into a NSAttributedString.
    ///
    /// - Parameters:
    ///     - element: ElementNode that's about to be converted.
    ///     - inheritedAttributes: Attributes to be applied over the resulting string.
    ///     - childrenSerializer: Callback to serialize child elements.
    ///
    /// - Returns: NSAttributedString instance, representing the received element.
    ///
    func convert(
        _ element: ElementNode,
        inheriting inheritedAttributes: [NSAttributedString.Key: Any],
        contentSerializer serialize: ContentSerializer) -> NSAttributedString
}
