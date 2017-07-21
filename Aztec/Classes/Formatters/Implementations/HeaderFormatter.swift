import Foundation
import UIKit


// MARK: - Header Formatter
//
open class HeaderFormatter: ParagraphAttributeFormatter {

    /// Heading Level of this formatter
    ///
    let headerLevel: Header.HeaderType

    /// Attributes to be added by default
    ///
    let placeholderAttributes: [String : Any]?


    /// Designated Initializer
    ///
    init(headerLevel: Header.HeaderType = .h1, placeholderAttributes: [String : Any]? = nil) {
        self.headerLevel = headerLevel
        self.placeholderAttributes = placeholderAttributes
    }


    // MARK: - Overwriten Methods

    func apply(to attributes: [String : Any], andStore representation: HTMLElementRepresentation?) -> [String: Any] {
        var resultingAttributes = attributes
        let newParagraphStyle = ParagraphStyle()

        if let paragraphStyle = attributes[NSParagraphStyleAttributeName] as? NSParagraphStyle {
            newParagraphStyle.setParagraphStyle(paragraphStyle)
        }

        if (newParagraphStyle.headerLevel == 0) {
            newParagraphStyle.add(property: Header(level: headerLevel, with: representation))
        } else {
            newParagraphStyle.replaceProperty(ofType: Header.self, with: Header(level: headerLevel))
        }

        resultingAttributes[NSParagraphStyleAttributeName] = newParagraphStyle

        if let font = attributes[NSFontAttributeName] as? UIFont {
            let newFont = font.withSize(headerLevel.fontSize)
            resultingAttributes[NSFontAttributeName] = newFont
        }

        return resultingAttributes
    }

    func remove(from attributes:[String: Any]) -> [String: Any] {
        var resultingAttributes = attributes
        let newParagraphStyle = ParagraphStyle()
        guard let paragraphStyle = attributes[NSParagraphStyleAttributeName] as? ParagraphStyle,
            paragraphStyle.headerLevel != 0 else {
            return resultingAttributes
        }
        newParagraphStyle.setParagraphStyle(paragraphStyle)
        newParagraphStyle.removeProperty(ofType: Header.self)
        resultingAttributes[NSParagraphStyleAttributeName] = newParagraphStyle

        if let font = attributes[NSFontAttributeName] as? UIFont {
            let newFont = font.withSize(Header.HeaderType.none.fontSize)
            resultingAttributes[NSFontAttributeName] = newFont
        }

        return resultingAttributes
    }

    func present(in attributes: [String : Any]) -> Bool {
        if let paragraphStyle = attributes[NSParagraphStyleAttributeName] as? ParagraphStyle {
            return paragraphStyle.headerLevel != 0 && paragraphStyle.headerLevel == headerLevel.rawValue
        }
        return false
    }
}

