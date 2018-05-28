import UIKit


/// Converts a generic element to `NSAttributedString`.  Should only be used if a specific converter is not found.
///
class GenericElementConverter: ElementConverter {
    
    /// This is a list of elements that don't produce an HTML attachment when they go through this converter
    /// At some point we should modify how the conversion works, so that any supported element never goes through this
    /// converter at all, and this converter is turned into an `UnsupportedElementConverter()` exclusively.
    ///
    private static let supportedElements: [Element] = [.a, .aztecRootNode, .b, .br, .blockquote, .del, .div, .em, .figure, .figcaption, .h1, .h2, .h3, .h4, .h5, .h6, .hr, .i, .img, .li, .ol, .p, .pre, .s, .span, .strike, .strong, .u, .ul, .video, .code]
    
    // MARK: - ElementConverter
    
    func convert(
        _ element: ElementNode,
        inheriting attributes: [NSAttributedStringKey: Any],
        childrenSerializer serializeChildren: ChildrenSerializer) -> NSAttributedString {
        
        guard isSupportedByEditor(element) else {
            return convert(unsupported: element, inheriting: attributes)
        }
        
        return serializeChildren(element.children, attributes)
    }
    
    private func isSupportedByEditor(_ element: ElementNode) -> Bool {
        return GenericElementConverter.supportedElements.contains(element.type)
    }
    
    /// Converts an unsupported `ElementNode` into it's `NSAttributedString` representation.
    /// This method basically packs the `ElementNode` into an attachment.
    ///
    /// - Parameters:
    ///     - element: the node to convert to `NSAttributedString`.
    ///     - attributes: the inherited attributes from parent nodes.
    ///
    /// - Returns: the converted node as an `NSAttributedString`.
    ///
    private func convert(unsupported element: ElementNode, inheriting attributes: [NSAttributedStringKey: Any]) -> NSAttributedString {
        let serializer = DefaultHTMLSerializer()
        let attachment = HTMLAttachment()
        
        attachment.rootTagName = element.name
        attachment.rawHTML = serializer.serialize(element)
        
        return NSAttributedString(attachment: attachment, attributes: attributes)
    }
}

