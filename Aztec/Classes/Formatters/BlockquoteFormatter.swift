import Foundation
import UIKit

class BlockquoteFormatter: ParagraphAttributeFormatter {

    let elementType: Libxml2.StandardElementType = .blockquote 

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
        newParagraphStyle.headIndent += Metrics.defaultIndentation
        newParagraphStyle.firstLineHeadIndent = newParagraphStyle.headIndent
        newParagraphStyle.tailIndent -= Metrics.defaultIndentation
        newParagraphStyle.paragraphSpacing += Metrics.defaultIndentation
        newParagraphStyle.paragraphSpacingBefore += Metrics.defaultIndentation
        newParagraphStyle.blockquote = Blockquote()
        resultingAttributes[NSParagraphStyleAttributeName] = newParagraphStyle
        return resultingAttributes
    }

    func remove(from attributes:[String: Any]) -> [String: Any] {
        var resultingAttributes = attributes
        let newParagraphStyle = ParagraphStyle()
        guard let paragraphStyle = attributes[NSParagraphStyleAttributeName] as? ParagraphStyle,
            paragraphStyle.blockquote != nil else {
            return resultingAttributes
        }
        newParagraphStyle.setParagraphStyle(paragraphStyle)
        newParagraphStyle.headIndent -= Metrics.defaultIndentation
        newParagraphStyle.firstLineHeadIndent = newParagraphStyle.headIndent
        newParagraphStyle.tailIndent += Metrics.defaultIndentation
        newParagraphStyle.paragraphSpacing -= Metrics.defaultIndentation
        newParagraphStyle.paragraphSpacingBefore -= Metrics.defaultIndentation
        newParagraphStyle.blockquote = nil
        resultingAttributes[NSParagraphStyleAttributeName] = newParagraphStyle
        return resultingAttributes
    }

    func present(in attributes: [String : Any]) -> Bool {
        if let paragraphStyle = attributes[NSParagraphStyleAttributeName] as? ParagraphStyle {
            return paragraphStyle.blockquote != nil
        }
        return false
    }
}

