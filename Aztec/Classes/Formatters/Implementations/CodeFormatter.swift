import Foundation
import UIKit

/// Formatter to apply simple value (NSNumber, UIColor) attributes to an attributed string.
class CodeFormatter: AttributeFormatter {

    var placeholderAttributes: [AttributedStringKey: Any]? { return nil }

    let monospaceFont: UIFont
    let backgroundColor: UIColor
    let htmlRepresentationKey: AttributedStringKey

    // MARK: - Init

    init(monospaceFont: UIFont = UIFont(descriptor:UIFontDescriptor(name: "Courier", size: 12), size:12), backgroundColor: UIColor = UIColor.lightGray) {
        let font: UIFont

        if #available(iOS 11.0, *) {
            font = UIFontMetrics.default.scaledFont(for: monospaceFont)
        } else {
            font = monospaceFont
        }
        self.monospaceFont = font
        self.backgroundColor = backgroundColor
        self.htmlRepresentationKey = .codeHtmlRepresentation
    }

    func applicationRange(for range: NSRange, in text: NSAttributedString) -> NSRange {
        return range
    }

    func worksInEmptyRange() -> Bool {
        return false
    }

    func apply(to attributes: [AttributedStringKey: Any], andStore representation: HTMLRepresentation?) -> [AttributedStringKey: Any] {
        var resultingAttributes = attributes

        resultingAttributes[AttributedStringKey.font] = monospaceFont
        resultingAttributes[AttributedStringKey.backgroundColor] = self.backgroundColor
        resultingAttributes[htmlRepresentationKey] = representation

        return resultingAttributes
    }

    func remove(from attributes: [AttributedStringKey: Any]) -> [AttributedStringKey: Any] {
        var resultingAttributes = attributes

        resultingAttributes.removeValue(forKey: AttributedStringKey.font)
        resultingAttributes.removeValue(forKey: AttributedStringKey.backgroundColor)
        resultingAttributes.removeValue(forKey: htmlRepresentationKey)

        if let placeholderAttributes = self.placeholderAttributes {
            resultingAttributes[AttributedStringKey.font] = placeholderAttributes[AttributedStringKey.font]
            resultingAttributes[AttributedStringKey.backgroundColor] = placeholderAttributes[AttributedStringKey.backgroundColor]
        }

        return resultingAttributes
    }

    func present(in attributes: [AttributedStringKey: Any]) -> Bool {
        if let font = attributes[AttributedStringKey.font] as? UIFont {
            return font == monospaceFont
        } else {
            return false
        }
    }
}


