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
    let placeholderAttributes: [NSAttributedString.Key: Any]?

    /// Tells if the formatter is increasing the depth of a list or simple changing the current one if any
    let increaseDepth: Bool

    /// Designated Initializer
    ///
    init(style: TextList.Style, placeholderAttributes: [NSAttributedString.Key: Any]? = nil, increaseDepth: Bool = false) {
        self.listStyle = style
        self.placeholderAttributes = placeholderAttributes
        self.increaseDepth = increaseDepth
    }


    // MARK: - Overwriten Methods

    func apply(to attributes: [NSAttributedString.Key: Any], andStore representation: HTMLRepresentation?) -> [NSAttributedString.Key: Any] {
        let newParagraphStyle = ParagraphStyle()
        if let paragraphStyle = attributes[.paragraphStyle] as? NSParagraphStyle {
            newParagraphStyle.setParagraphStyle(paragraphStyle)
        }

        let newList = TextList(style: self.listStyle, with: representation)
        if newParagraphStyle.lists.isEmpty || increaseDepth {
            newParagraphStyle.insertProperty(newList, afterLastOfType: HTMLLi.self)
        } else {
            newParagraphStyle.replaceProperty(ofType: TextList.self, with: newList)
        }

        var resultingAttributes = attributes
        resultingAttributes[.paragraphStyle] = newParagraphStyle

        return resultingAttributes
    }

    func remove(from attributes: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
        guard let paragraphStyle = attributes[.paragraphStyle] as? ParagraphStyle,
              let currentList = paragraphStyle.lists.last,
              currentList.style == self.listStyle
        else {
            return attributes
        }

        let newParagraphStyle = ParagraphStyle()
        newParagraphStyle.setParagraphStyle(paragraphStyle)
        newParagraphStyle.removeProperty(ofType: HTMLLi.self)
        newParagraphStyle.removeProperty(ofType: TextList.self)

        var resultingAttributes = attributes
        resultingAttributes[.paragraphStyle] = newParagraphStyle

        return resultingAttributes
    }

    func present(in attributes: [NSAttributedString.Key: Any]) -> Bool {
        return TextListFormatter.lists(in: attributes).last?.style == listStyle
    }


    // MARK: - Static Helpers

    static func listsOfAnyKindPresent(in attributes: [NSAttributedString.Key: Any]) -> Bool {
        return lists(in: attributes).isEmpty == false
    }

    static func lists(in attributes: [NSAttributedString.Key: Any]) -> [TextList] {
        let style = attributes[.paragraphStyle] as? ParagraphStyle
        return style?.lists ?? []
    }
}

