import Aztec
import Foundation

/// Editing customizer for the WordPress plugin.
///
class WordPressEditingCustomizer: EditingCustomizer {
    
    func typingAttributesForNewParagraph(previous previousAttributes: [NSAttributedStringKey : Any]) -> [NSAttributedStringKey : Any] {
        guard let paragraphStyle = previousAttributes[.paragraphStyle] as? ParagraphStyle else {
            return previousAttributes
        }
        
        var attributes = previousAttributes
        let newParagraphStyle = ParagraphStyle(with: paragraphStyle)
        
        newParagraphStyle.removeProperties(ofType: Gutenblock.self)
        attributes[.paragraphStyle] = newParagraphStyle
        
        return attributes
    }
}
