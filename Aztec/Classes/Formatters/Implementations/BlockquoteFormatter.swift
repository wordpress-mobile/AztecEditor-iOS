import Foundation
import UIKit


// MARK: - Blockquote Formatter
//
class BlockquoteFormatter: ParagraphAttributeFormatter {

    /// Attributes to be added by default
    ///
    let placeholderAttributes: [String : Any]?


    /// Designated Initializer
    ///
    init(placeholderAttributes: [String : Any]? = nil) {
        self.placeholderAttributes = placeholderAttributes
    }


    // MARK: - Overwriten Methods

    func apply(to attributes: [String : Any], andStore representation: HTMLRepresentation?) -> [String: Any] {
        let newParagraphStyle = ParagraphStyle()
        if let paragraphStyle = attributes[NSParagraphStyleAttributeName] as? NSParagraphStyle {
            newParagraphStyle.setParagraphStyle(paragraphStyle)
        }

        newParagraphStyle.add(property: Blockquote(with: representation))

        var resultingAttributes = attributes
        resultingAttributes[NSParagraphStyleAttributeName] = newParagraphStyle
        return resultingAttributes
    }

    func remove(from attributes:[String: Any]) -> [String: Any] {
        guard let paragraphStyle = attributes[NSParagraphStyleAttributeName] as? ParagraphStyle,
            !paragraphStyle.blockquotes.isEmpty
        else {
            return attributes
        }

        let newParagraphStyle = ParagraphStyle()
        newParagraphStyle.setParagraphStyle(paragraphStyle)        
        newParagraphStyle.removeProperty(ofType: Blockquote.self)

        var resultingAttributes = attributes
        resultingAttributes[NSParagraphStyleAttributeName] = newParagraphStyle
        return resultingAttributes
    }

    func present(in attributes: [String : Any]) -> Bool {
        guard let style = attributes[NSParagraphStyleAttributeName] as? ParagraphStyle else {
            return false
        }
        return !style.blockquotes.isEmpty
    }
}

