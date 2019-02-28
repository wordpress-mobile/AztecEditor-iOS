import UIKit


/// `ElementConverter` subclass for converters that just apply a formatter to the inherited attributes.
///
protocol FormatterElementConverter: ElementConverter {
    func attributes(for element: ElementNode, inheriting inheritedAttributes: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any]
    func formatter() -> AttributeFormatter
}

extension FormatterElementConverter {
    /// Calculates the attributes for the specified node.  Returns a dictionary including inherited
    /// attributes.
    ///
    /// - Parameters:
    ///     - element: the node to get the information from.
    ///     - inheritedAttributes: the inherited attributes from parent nodes.
    ///
    /// - Returns: an attributes dictionary, for use in an NSAttributedString.
    ///
    func attributes(for element: ElementNode, inheriting inheritedAttributes: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
        
        guard !(element is RootNode) else {
            return inheritedAttributes
        }
        
        let elementRepresentation = HTMLElementRepresentation(element)
        let representation = HTMLRepresentation(for: .element(elementRepresentation))
        let finalAttributes = formatter().apply(to: inheritedAttributes, andStore: representation)
        
        return finalAttributes
    }
}
