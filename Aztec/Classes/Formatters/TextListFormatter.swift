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

        if  (increaseDepth || newParagraphStyle.textLists.isEmpty) {
            newParagraphStyle.add(property: TextList(style: self.listStyle))
        } else {
            newParagraphStyle.replaceProperty(ofType: TextList.self, with: TextList(style: self.listStyle))
        }

        var resultingAttributes = attributes
        resultingAttributes[NSParagraphStyleAttributeName] = newParagraphStyle

        return resultingAttributes
    }

    func remove(from attributes: [String: Any]) -> [String: Any] {
        guard let paragraphStyle = attributes[NSParagraphStyleAttributeName] as? ParagraphStyle,
              let currentList = paragraphStyle.textLists.last,
              currentList.style == self.listStyle
        else {
            return attributes
        }

        let newParagraphStyle = ParagraphStyle()
        newParagraphStyle.setParagraphStyle(paragraphStyle)       
        newParagraphStyle.removeProperty(ofType: TextList.self)

        var resultingAttributes = attributes
        resultingAttributes[NSParagraphStyleAttributeName] = newParagraphStyle

        return resultingAttributes
    }

    func present(in attributes: [String : Any]) -> Bool {
        guard let style = attributes[NSParagraphStyleAttributeName] as? ParagraphStyle, let list = style.textLists.last else {
            return false
        }

        return list.style == listStyle
    }

    static func listsOfAnyKindPresent(in attributes: [String: Any]) -> Bool {
        guard let style = attributes[NSParagraphStyleAttributeName] as? ParagraphStyle else {
            return false
        }
        return !(style.textLists.isEmpty)
    }
}

