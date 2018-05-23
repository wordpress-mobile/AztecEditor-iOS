import Foundation
import UIKit


// MARK: - HTMLParagraph Formatter
//
class HTMLParagraphFormatter: ParagraphAttributeFormatter {

    /// Attributes to be added by default
    ///
    let placeholderAttributes: [NSAttributedStringKey: Any]?


    /// Designated Initializer
    ///
    init(placeholderAttributes: [NSAttributedStringKey: Any]? = nil) {
        self.placeholderAttributes = placeholderAttributes
    }


    // MARK: - Overwriten Methods

    func apply(to attributes: [NSAttributedStringKey: Any], andStore representation: HTMLRepresentation?) -> [NSAttributedStringKey: Any] {
        let newParagraphStyle = ParagraphStyle()

        if let paragraphStyle = attributes[.paragraphStyle] as? NSParagraphStyle {
            newParagraphStyle.setParagraphStyle(paragraphStyle)
        }

        newParagraphStyle.appendProperty(HTMLParagraph(with: representation))

        var resultingAttributes = attributes
        resultingAttributes[.paragraphStyle] = newParagraphStyle
        return resultingAttributes
    }

    func remove(from attributes:[NSAttributedStringKey: Any]) -> [NSAttributedStringKey: Any] {
        guard let paragraphStyle = attributes[.paragraphStyle] as? ParagraphStyle,
            !paragraphStyle.htmlParagraph.isEmpty
            else {
                return attributes
        }

        let newParagraphStyle = ParagraphStyle()
        newParagraphStyle.setParagraphStyle(paragraphStyle)
        newParagraphStyle.removeProperty(ofType: HTMLParagraph.self)

        var resultingAttributes = attributes
        resultingAttributes[.paragraphStyle] = newParagraphStyle
        return resultingAttributes
    }

    func present(in attributes: [NSAttributedStringKey: Any]) -> Bool {
        guard let style = attributes[.paragraphStyle] as? ParagraphStyle else {
            return false
        }
        return !style.htmlParagraph.isEmpty
    }
}

