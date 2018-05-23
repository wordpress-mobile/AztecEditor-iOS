import UIKit


/// ElementConverters take an HTML Element that don't have a textual representation and return a special value to
/// represent it (e.g. `<img>` or `<video>`). To apply a style to a piece of text, use `AttributeFormatter`.
///
protocol ElementConverter {
    
    typealias ChildrenSerializer = (_: [Node], _ inheriting: [NSAttributedStringKey:Any]) -> NSAttributedString
    
    var serializeChildren: ChildrenSerializer { get }
    
    /// Default initializer.  Requires a block that handles children serialization.
    ///
    init(childrenSerializer: @escaping ChildrenSerializer)
    
    /// Indicates whether the received element can be converted by the current instance, or not.
    ///
    func canConvert(element: ElementNode) -> Bool
    
    /// Converts an instance of ElementNode into a NSAttributedString.
    ///
    /// - Parameters:
    ///     - element: ElementNode that's about to be converted.
    ///     - inheritedAttributes: Attributes to be applied over the resulting string.
    ///
    /// - Returns: NSAttributedString instance, representing the received element.
    ///
    func convert(_ element: ElementNode, inheriting attributes: [NSAttributedStringKey: Any]) -> NSAttributedString
}
