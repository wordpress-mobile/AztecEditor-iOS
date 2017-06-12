import Foundation
import UIKit


// MARK: - Blockquote Formatter
//
class HTMLParagraphFormatter: ParagraphAttributeFormatter {

    /// Attributes to be added by default
    ///
    let placeholderAttributes: [String : Any]?


    /// Designated Initializer
    ///
    init(placeholderAttributes: [String : Any]? = nil) {
        self.placeholderAttributes = placeholderAttributes
    }


    // MARK: - Overwriten Methods

    func apply(to attributes: [String : Any]) -> [String: Any] {
        let newParagraphStyle = ParagraphStyle()

        if let paragraphStyle = attributes[NSParagraphStyleAttributeName] as? NSParagraphStyle {
            newParagraphStyle.setParagraphStyle(paragraphStyle)
        }

        newParagraphStyle.htmlParagraph = HTMLParagraph()

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

        var resultingAttributes = attributes
        resultingAttributes[NSParagraphStyleAttributeName] = newParagraphStyle
        return resultingAttributes
    }

    func present(in attributes: [String : Any]) -> Bool {
        let style = attributes[NSParagraphStyleAttributeName] as? ParagraphStyle
        return style?.htmlParagraph != nil
    }
}

