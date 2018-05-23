import UIKit

extension Dictionary where Key == NSAttributedStringKey, Value == Any {
    
    // MARK: - ParagraphStyle interactions
    
    /// Creates a copy of the paragraph style object contained within the specified string attributes.
    ///
    /// - Parameters:
    ///     - attributes: the attributes to obtain the paragraph style from.
    ///
    /// - Returns: the requested `ParagraphStyle` object.
    ///
    func paragraphStyle() -> ParagraphStyle {
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
    func appending(_ property: ParagraphProperty) -> [NSAttributedStringKey:Any] {
        let finalParagraphStyle = paragraphStyle()
        finalParagraphStyle.appendProperty(property)
        
        var finalAttributes = self
        finalAttributes[.paragraphStyle] = finalParagraphStyle
        
        return finalAttributes
    }
}
