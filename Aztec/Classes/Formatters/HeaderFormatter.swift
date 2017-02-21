import Foundation
import UIKit

class HeaderFormatter: ParagraphAttributeFormatter {

    let elementType: Libxml2.StandardElementType = .h1

    let placeholderAttributes: [String : Any]?

    init(placeholderAttributes: [String : Any]? = nil) {
        self.placeholderAttributes = placeholderAttributes
    }

    func apply(to attributes: [String : Any]) -> [String: Any] {
        var resultingAttributes = attributes
        let newParagraphStyle = ParagraphStyle()
        if let paragraphStyle = attributes[NSParagraphStyleAttributeName] as? NSParagraphStyle {
            newParagraphStyle.setParagraphStyle(paragraphStyle)
        }
        newParagraphStyle.paragraphSpacing += Metrics.defaultIndentation
        newParagraphStyle.paragraphSpacingBefore += Metrics.defaultIndentation
        resultingAttributes[NSParagraphStyleAttributeName] = newParagraphStyle

        if let font = attributes[NSFontAttributeName] as? UIFont {
            let newFont = font.withSize(36)
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
        newParagraphStyle.paragraphSpacing -= Metrics.defaultIndentation
        newParagraphStyle.paragraphSpacingBefore -= Metrics.defaultIndentation
        resultingAttributes[NSParagraphStyleAttributeName] = newParagraphStyle

        if let font = attributes[NSFontAttributeName] as? UIFont {
            let newFont = font.withSize(16)
            resultingAttributes[NSFontAttributeName] = newFont
        }

        return resultingAttributes
    }

    func present(in attributes: [String : Any]) -> Bool {
        if let paragraphStyle = attributes[NSParagraphStyleAttributeName] as? ParagraphStyle {
            return paragraphStyle.headerLevel != 0
        }
        return false
    }
}

