import Foundation
import UIKit

struct TextListFormatter: ParagraphAttributeFormatter {

    let listStyle: TextList.Style
    let placeholderAttributes: [String : Any]?

    init(style: TextList.Style, placeholderAttributes: [String : Any]? = nil) {
        self.listStyle = style
        self.placeholderAttributes = placeholderAttributes
    }

    func apply(to attributes: [String : Any]) -> [String: Any] {
        var resultingAttributes = attributes
        let newParagraphStyle = ParagraphStyle()
        if let paragraphStyle = attributes[NSParagraphStyleAttributeName] as? NSParagraphStyle {
            newParagraphStyle.setParagraphStyle(paragraphStyle)
        }
        if newParagraphStyle.textList == nil {
            newParagraphStyle.headIndent += Metrics.defaultIndentation
            newParagraphStyle.firstLineHeadIndent += Metrics.defaultIndentation
        }
        newParagraphStyle.textList = TextList(style: self.listStyle)
        resultingAttributes[NSParagraphStyleAttributeName] = newParagraphStyle
        return resultingAttributes
    }

    func remove(from attributes:[String: Any]) -> [String: Any] {
        var resultingAttributes = attributes
        let newParagraphStyle = ParagraphStyle()
        guard let paragraphStyle = attributes[NSParagraphStyleAttributeName] as? ParagraphStyle,
            paragraphStyle.textList?.style == self.listStyle
        else {
            return resultingAttributes
        }
        newParagraphStyle.setParagraphStyle(paragraphStyle)
        newParagraphStyle.headIndent -= Metrics.defaultIndentation
        newParagraphStyle.firstLineHeadIndent -= Metrics.defaultIndentation
        newParagraphStyle.textList = nil
        resultingAttributes[NSParagraphStyleAttributeName] = newParagraphStyle
        return resultingAttributes
    }

    func present(in attributes: [String : AnyObject]) -> Bool {
        guard let paragraphStyle = attributes[NSParagraphStyleAttributeName] as? ParagraphStyle,
              let textList = paragraphStyle.textList else {
            return false
        }
        return textList.style == listStyle
    }
}

