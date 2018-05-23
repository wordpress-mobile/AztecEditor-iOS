import Foundation
import UIKit


// MARK: - HTMLDivFormatter Formatter
//
class HTMLDivFormatter: ParagraphAttributeFormatter {

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

        let newProperty = HTMLDiv(with: representation)
        newParagraphStyle.appendProperty(newProperty)

        var resultingAttributes = attributes
        resultingAttributes[.paragraphStyle] = newParagraphStyle
        return resultingAttributes
    }

    func remove(from attributes: [NSAttributedStringKey: Any]) -> [NSAttributedStringKey: Any] {
        guard let paragraphStyle = attributes[.paragraphStyle] as? ParagraphStyle,
            !paragraphStyle.htmlDiv.isEmpty
        else {
            return attributes
        }

        let newParagraphStyle = ParagraphStyle()
        newParagraphStyle.setParagraphStyle(paragraphStyle)
        newParagraphStyle.removeProperty(ofType: HTMLDiv.self)

        var resultingAttributes = attributes
        resultingAttributes[.paragraphStyle] = newParagraphStyle
        return resultingAttributes
    }

    func present(in attributes: [NSAttributedStringKey: Any]) -> Bool {
        let style = attributes[.paragraphStyle] as? ParagraphStyle
        return style?.htmlDiv.isEmpty == false
    }
}
