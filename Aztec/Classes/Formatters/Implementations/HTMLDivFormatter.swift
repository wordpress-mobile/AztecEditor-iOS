import Foundation
import UIKit


// MARK: - HTMLDivFormatter Formatter
//
class HTMLDivFormatter: ParagraphAttributeFormatter {

    /// Attributes to be added by default
    ///
    let placeholderAttributes: [String: Any]?


    /// Designated Initializer
    ///
    init(placeholderAttributes: [String: Any]? = nil) {
        self.placeholderAttributes = placeholderAttributes
    }


    // MARK: - Overwriten Methods

    func apply(to attributes: [String: Any], andStore representation: HTMLRepresentation?) -> [String: Any] {
        let newParagraphStyle = ParagraphStyle()

        if let paragraphStyle = attributes[NSParagraphStyleAttributeName] as? NSParagraphStyle {
            newParagraphStyle.setParagraphStyle(paragraphStyle)
        }

        let newProperty = HTMLDiv(with: representation)
        newParagraphStyle.appendProperty(newProperty)

        var resultingAttributes = attributes
        resultingAttributes[NSParagraphStyleAttributeName] = newParagraphStyle
        return resultingAttributes
    }

    func remove(from attributes:[String: Any]) -> [String: Any] {
        guard let paragraphStyle = attributes[NSParagraphStyleAttributeName] as? ParagraphStyle,
            !paragraphStyle.htmlDiv.isEmpty
        else {
            return attributes
        }

        let newParagraphStyle = ParagraphStyle()
        newParagraphStyle.setParagraphStyle(paragraphStyle)
        newParagraphStyle.removeProperty(ofType: HTMLDiv.self)

        var resultingAttributes = attributes
        resultingAttributes[NSParagraphStyleAttributeName] = newParagraphStyle
        return resultingAttributes
    }

    func present(in attributes: [String: Any]) -> Bool {
        let style = attributes[NSParagraphStyleAttributeName] as? ParagraphStyle
        return style?.htmlDiv.isEmpty == false
    }
}
