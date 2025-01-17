import Foundation
import UIKit

class MarkFormatter: AttributeFormatter {

    var placeholderAttributes: [NSAttributedString.Key: Any]?
    var textColor: String?
    var defaultTextColor: UIColor?

    func applicationRange(for range: NSRange, in text: NSAttributedString) -> NSRange {
        return range
    }

    func apply(to attributes: [NSAttributedString.Key: Any], andStore representation: HTMLRepresentation?) -> [NSAttributedString.Key: Any] {
        var resultingAttributes = attributes
        let colorStyle = CSSAttribute(name: "color", value: textColor)
        let backgroundColorStyle = CSSAttribute(name: "background-color", value: "rgba(0, 0, 0, 0)")

        let styleAttribute = Attribute(type: .style, value: .inlineCss([backgroundColorStyle, colorStyle]))
        let classAttribute = Attribute(type: .class, value: .string("has-inline-color"))

        // Setting the HTML representation
        var representationToUse = HTMLRepresentation(for: .element(HTMLElementRepresentation.init(name: "mark", attributes: [styleAttribute, classAttribute])))
        if let requestedRepresentation = representation {
            representationToUse = requestedRepresentation
        }
        resultingAttributes[.markHtmlRepresentation] = representationToUse

        if let textColor = textColor {
            resultingAttributes[.foregroundColor] = UIColor(hexString: textColor)
        }

        return resultingAttributes
    }

    func remove(from attributes: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
        var resultingAttributes = attributes

        if defaultTextColor != nil {
            resultingAttributes[.foregroundColor] = defaultTextColor
        }

        resultingAttributes.removeValue(forKey: .markHtmlRepresentation)
        return resultingAttributes
    }

    func present(in attributes: [NSAttributedString.Key: Any]) -> Bool {
        return attributes[NSAttributedString.Key.markHtmlRepresentation] != nil
    }
}
