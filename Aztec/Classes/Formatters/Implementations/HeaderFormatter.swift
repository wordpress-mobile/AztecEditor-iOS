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
    init(headerLevel: Header.HeaderType = .h1, placeholderAttributes: [String: Any]? = nil) {
        self.headerLevel = headerLevel
        self.placeholderAttributes = placeholderAttributes
    }


    // MARK: - Overwriten Methods

    func apply(to attributes: [String: Any], andStore representation: HTMLRepresentation?) -> [String: Any] {
        guard let font = attributes[NSFontAttributeName] as? UIFont else {
            return attributes
        }

        let newParagraphStyle = ParagraphStyle()
        if let paragraphStyle = attributes[NSParagraphStyleAttributeName] as? NSParagraphStyle {
            newParagraphStyle.setParagraphStyle(paragraphStyle)
        }

        let defaultSize = defaultFontSize(from: attributes)
        let header = Header(level: headerLevel, with: representation, defaultFontSize: defaultSize)
        if newParagraphStyle.headers.isEmpty {
            newParagraphStyle.appendProperty(header)
        } else {
            newParagraphStyle.replaceProperty(ofType: Header.self, with: header)
        }

        var resultingAttributes = attributes
        resultingAttributes[NSParagraphStyleAttributeName] = newParagraphStyle
        resultingAttributes[NSFontAttributeName] = font.withSize(headerLevel.fontSize)

        return resultingAttributes
    }

    func remove(from attributes: [String: Any]) -> [String: Any] {
        guard let paragraphStyle = attributes[NSParagraphStyleAttributeName] as? ParagraphStyle,
            let header = paragraphStyle.headers.last,
            header.level != .none
        else {
            return attributes
        }

        let newParagraphStyle = ParagraphStyle()
        newParagraphStyle.setParagraphStyle(paragraphStyle)
        newParagraphStyle.removeProperty(ofType: Header.self)

        var resultingAttributes = attributes
        resultingAttributes[NSParagraphStyleAttributeName] = newParagraphStyle

        if let font = attributes[NSFontAttributeName] as? UIFont {
            resultingAttributes[NSFontAttributeName] = font.withSize(header.defaultFontSize)
        }

        return resultingAttributes
    }

    func present(in attributes: [String: Any]) -> Bool {
        guard let paragraphStyle = attributes[NSParagraphStyleAttributeName] as? ParagraphStyle else {
            return false
        }

        return paragraphStyle.headerLevel != 0 && paragraphStyle.headerLevel == headerLevel.rawValue
    }
}


// MARK: - Private Helpers
//
private extension HeaderFormatter {

    func defaultFontSize(from attributes: [String: Any]) -> CGFloat? {
        if let paragraphStyle = attributes[NSParagraphStyleAttributeName] as? ParagraphStyle,
            let lastHeader = paragraphStyle.headers.last
        {
            return lastHeader.defaultFontSize
        }

        if let font = attributes[NSFontAttributeName] as? UIFont {
            return font.pointSize
        }

        return nil
    }
}
