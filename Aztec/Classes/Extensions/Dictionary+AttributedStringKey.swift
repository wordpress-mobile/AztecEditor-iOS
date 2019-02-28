import UIKit

extension Dictionary where Key == NSAttributedString.Key, Value == Any {
    
    // MARK: - ParagraphStyle interactions
    
    /// Creates a copy of the paragraph style object contained within the specified string attributes.
    ///
    /// - Parameters:
    ///     - attributes: the attributes to obtain the paragraph style from.
    ///
    /// - Returns: the requested `ParagraphStyle` object.
    ///
    public func paragraphStyle() -> ParagraphStyle {
        guard let existingParagraphStyle = self[.paragraphStyle] as? NSParagraphStyle else {
            return ParagraphStyle()
        }
        
        return ParagraphStyle(with: existingParagraphStyle)
    }
    
    /// Returns a copy of the provided attributes appending the specified `ParagraphProperty` to the paragraph style.
    ///
    /// - Parameters:
    ///     - property: the property to append to the paragraph styles.
    ///     - attributes: the base attributes.
    ///
    /// - Returns: the final string attributes.
    ///
    func appending(_ property: ParagraphProperty) -> [NSAttributedString.Key:Any] {
        let finalParagraphStyle = paragraphStyle()
        finalParagraphStyle.appendProperty(property)
        
        var finalAttributes = self
        finalAttributes[.paragraphStyle] = finalParagraphStyle
        
        return finalAttributes
    }
    
    /// Use this method to retrieve an `ElementNode` obtained from the specified key.
    ///
    /// - Parameters:
    ///     - key: the key to retrieve the element representation from the attributed string.
    ///
    /// - Returns: the requested element, or `nil` if there's no stored representation for it.
    ///
    func storedElement(for key: NSAttributedString.Key) -> ElementNode? {
        if let representation = self[key] as? HTMLRepresentation,
            case let .element(representationElement) = representation.kind {
            
            return representationElement.toElementNode()
        }
        
        return nil
    }
}
