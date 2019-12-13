import Foundation
import UIKit


// MARK: - Blockquote Formatter
//
class BlockquoteFormatter: ParagraphAttributeFormatter {

    /// Attributes to be added by default
    ///
    let placeholderAttributes: [NSAttributedString.Key: Any]?

    /// Tells if the formatter is increasing the depth of a list or simple changing the current one if any
    let increaseDepth: Bool
    

    /// Designated Initializer
    ///
    init(placeholderAttributes: [NSAttributedString.Key: Any]? = nil, increaseDepth: Bool = false) {
        self.placeholderAttributes = placeholderAttributes
        self.increaseDepth = increaseDepth
    }


    // MARK: - Overwriten Methods

    func apply(to attributes: [NSAttributedString.Key: Any], andStore representation: HTMLRepresentation?) -> [NSAttributedString.Key: Any] {
        let newParagraphStyle = ParagraphStyle()
        
        if let paragraphStyle = attributes[.paragraphStyle] as? NSParagraphStyle {
            newParagraphStyle.setParagraphStyle(paragraphStyle)
        }
        
        let newQuote = Blockquote(with: representation)
        
        if newParagraphStyle.blockquotes.isEmpty || increaseDepth {
            newParagraphStyle.insertProperty(newQuote, afterLastOfType: Blockquote.self)
        } else {
            newParagraphStyle.replaceProperty(ofType: Blockquote.self, with: newQuote)
        }

        var resultingAttributes = attributes
        resultingAttributes[.paragraphStyle] = newParagraphStyle
        
        return resultingAttributes
    }

    func remove(from attributes:[NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
        guard let paragraphStyle = attributes[.paragraphStyle] as? ParagraphStyle,
            !paragraphStyle.blockquotes.isEmpty
        else {
            return attributes
        }

        let newParagraphStyle = ParagraphStyle()
        newParagraphStyle.setParagraphStyle(paragraphStyle)        
        newParagraphStyle.removeProperty(ofType: Blockquote.self)

        var resultingAttributes = attributes
        resultingAttributes[.paragraphStyle] = newParagraphStyle
                
        return resultingAttributes
    }

    func present(in attributes: [NSAttributedString.Key: Any]) -> Bool {
        guard let style = attributes[.paragraphStyle] as? ParagraphStyle else {
            return false
        }
        return !style.blockquotes.isEmpty
    }
    
    static func blockquotes(in attributes: [NSAttributedString.Key: Any]) -> [Blockquote] {
        let style = attributes[.paragraphStyle] as? ParagraphStyle
        return style?.blockquotes ?? []
    }
}
