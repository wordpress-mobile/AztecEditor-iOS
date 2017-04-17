import Foundation
import UIKit


// MARK: - Lists Formatter
//
class TextListFormatter: ParagraphAttributeFormatter {

    /// Style of the list
    ///
    let listStyle: TextList.Style

    /// Attributes to be added by default
    ///
    let placeholderAttributes: [String : Any]?


    /// Designated Initializer
    ///
    init(style: TextList.Style, placeholderAttributes: [String : Any]? = nil) {
        self.listStyle = style
        self.placeholderAttributes = placeholderAttributes
    }


    // MARK: - Overwriten Methods

    func apply(to attributes: [String : Any]) -> [String: Any] {
        let newParagraphStyle = ParagraphStyle()
        if let paragraphStyle = attributes[NSParagraphStyleAttributeName] as? NSParagraphStyle {
            newParagraphStyle.setParagraphStyle(paragraphStyle)
        }

        if newParagraphStyle.textList == nil {
            newParagraphStyle.headIndent += Metrics.listTextIndentation
            newParagraphStyle.firstLineHeadIndent += Metrics.listTextIndentation
        }

        newParagraphStyle.textList = TextList(style: self.listStyle)

        var resultingAttributes = attributes
        resultingAttributes[NSParagraphStyleAttributeName] = newParagraphStyle

        return resultingAttributes
    }

    func remove(from attributes: [String: Any]) -> [String: Any] {
        guard present(in: attributes) else {
            return attributes
        }

        let newParagraphStyle = ParagraphStyle()
        if let paragraphStyle = attributes[NSParagraphStyleAttributeName] as? NSParagraphStyle {
            newParagraphStyle.setParagraphStyle(paragraphStyle)
        }
        newParagraphStyle.headIndent -= Metrics.listTextIndentation
        newParagraphStyle.firstLineHeadIndent -= Metrics.listTextIndentation
        newParagraphStyle.textList = nil

        var resultingAttributes = attributes
        resultingAttributes[NSParagraphStyleAttributeName] = newParagraphStyle

        return resultingAttributes
    }

    func present(in attributes: [String : Any]) -> Bool {
        guard let style = attributes[NSParagraphStyleAttributeName] as? ParagraphStyle, let list = style.textList else {
            return false
        }

        return list.style == listStyle
    }

    func needsEmptyLinePlaceholder() -> Bool {
        return false
    }
}

