import Foundation
import UIKit


// MARK: - HTMLParagraph Formatter
//
public class HTMLParagraphFormatter: ParagraphAttributeFormatter {

    /// Attributes to be added by default
    ///
    let placeholderAttributes: [NSAttributedString.Key: Any]?


    /// Designated Initializer
    ///
    public init(placeholderAttributes: [NSAttributedString.Key: Any]? = nil) {
        self.placeholderAttributes = placeholderAttributes
    }


    // MARK: - Overwriten Methods

    func apply(to attributes: [NSAttributedString.Key: Any], andStore representation: HTMLRepresentation?) -> [NSAttributedString.Key: Any] {
        let newParagraphStyle = ParagraphStyle()

        if let paragraphStyle = attributes[.paragraphStyle] as? NSParagraphStyle {
            newParagraphStyle.setParagraphStyle(paragraphStyle)
        }

        newParagraphStyle.appendProperty(HTMLParagraph(with: representation))

        var resultingAttributes = attributes
        resultingAttributes[.paragraphStyle] = newParagraphStyle
        return resultingAttributes
    }

    public func remove(from attributes:[NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
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

    func present(in attributes: [NSAttributedString.Key: Any]) -> Bool {
        guard let style = attributes[.paragraphStyle] as? ParagraphStyle else {
            return false
        }
        return !style.htmlParagraph.isEmpty
    }
}

