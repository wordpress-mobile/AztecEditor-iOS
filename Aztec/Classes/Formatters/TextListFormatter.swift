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

    /// Tells if the formatter is increasing the depth of a list or simple changing the current one if any
    let increaseDepth: Bool

    /// Designated Initializer
    ///
    init(style: TextList.Style, placeholderAttributes: [String : Any]? = nil, increaseDepth: Bool = false) {
        self.listStyle = style
        self.placeholderAttributes = placeholderAttributes
        self.increaseDepth = increaseDepth
    }


    // MARK: - Overwriten Methods

    func apply(to attributes: [String : Any]) -> [String: Any] {
        let newParagraphStyle = ParagraphStyle()
        if let paragraphStyle = attributes[NSParagraphStyleAttributeName] as? NSParagraphStyle {
            newParagraphStyle.setParagraphStyle(paragraphStyle)
        }

        if  increaseDepth || !(newParagraphStyle.has(paragraphHint: ParagraphHint.orderedList) || newParagraphStyle.has(paragraphHint: .unorderedList)) {
            //newParagraphStyle.headIndent += Metrics.listTextIndentation
            //newParagraphStyle.firstLineHeadIndent += Metrics.listTextIndentation
            //newParagraphStyle.textLists.append(TextList(style: self.listStyle))
            newParagraphStyle.add(paragraphHint: self.listStyle == .ordered ? ParagraphHint.orderedList : ParagraphHint.unorderedList)
        } else {
            //newParagraphStyle.textLists.removeLast()
            //newParagraphStyle.textLists.append(TextList(style: self.listStyle))
            newParagraphStyle.replace(paragraphHint: self.listStyle == .ordered ? ParagraphHint.orderedList : ParagraphHint.unorderedList)
        }

        var resultingAttributes = attributes
        resultingAttributes[NSParagraphStyleAttributeName] = newParagraphStyle

        return resultingAttributes
    }

    func remove(from attributes: [String: Any]) -> [String: Any] {
        guard let paragraphStyle = attributes[NSParagraphStyleAttributeName] as? ParagraphStyle,
              paragraphStyle.has(paragraphHint: self.listStyle == .ordered ? ParagraphHint.orderedList : ParagraphHint.unorderedList)
        else {
            return attributes
        }

        let newParagraphStyle = ParagraphStyle()
        newParagraphStyle.setParagraphStyle(paragraphStyle)
        //newParagraphStyle.headIndent -= Metrics.listTextIndentation
        //newParagraphStyle.firstLineHeadIndent -= Metrics.listTextIndentation
        //newParagraphStyle.textLists.removeLast()
        newParagraphStyle.remove(paragraphHint: self.listStyle == .ordered ? ParagraphHint.orderedList : ParagraphHint.unorderedList)

        var resultingAttributes = attributes
        resultingAttributes[NSParagraphStyleAttributeName] = newParagraphStyle

        return resultingAttributes
    }

    func present(in attributes: [String : Any]) -> Bool {
        guard let style = attributes[NSParagraphStyleAttributeName] as? ParagraphStyle
        //,let list = style.textLists.last 
        else {
            return false
        }

        return style.has(paragraphHint: self.listStyle == .ordered ? ParagraphHint.orderedList : ParagraphHint.unorderedList)
    }

    static func listsOfAnyKindPresent(in attributes: [String: Any]) -> Bool {
        guard let style = attributes[NSParagraphStyleAttributeName] as? ParagraphStyle else {
            return false
        }
        //return !(style.textLists.isEmpty)
        return style.has(paragraphHint: ParagraphHint.orderedList) || style.has(paragraphHint: .unorderedList)
    }
}

