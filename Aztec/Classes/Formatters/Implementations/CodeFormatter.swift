import Foundation
import UIKit

/// Formatter to apply simple value (NSNumber, UIColor) attributes to an attributed string.
class CodeFormatter: AttributeFormatter {

    var placeholderAttributes: [NSAttributedStringKey: Any]? { return nil }

    let monospaceFont: UIFont
    let backgroundColor: UIColor
    let htmlRepresentationKey: NSAttributedStringKey

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

    func apply(to attributes: [NSAttributedStringKey: Any], andStore representation: HTMLRepresentation?) -> [NSAttributedStringKey: Any] {
        var resultingAttributes = attributes

        resultingAttributes[.font] = monospaceFont
        resultingAttributes[.backgroundColor] = self.backgroundColor
        resultingAttributes[htmlRepresentationKey] = representation

        return resultingAttributes
    }

    func remove(from attributes: [NSAttributedStringKey: Any]) -> [NSAttributedStringKey: Any] {
        var resultingAttributes = attributes

        resultingAttributes.removeValue(forKey: .font)
        resultingAttributes.removeValue(forKey: .backgroundColor)
        resultingAttributes.removeValue(forKey: htmlRepresentationKey)

        if let placeholderAttributes = self.placeholderAttributes {
            resultingAttributes[.font] = placeholderAttributes[.font]
            resultingAttributes[.backgroundColor] = placeholderAttributes[.backgroundColor]
        }

        return resultingAttributes
    }

    func present(in attributes: [NSAttributedStringKey: Any]) -> Bool {
        if let font = attributes[NSAttributedStringKey.font] as? UIFont {
            return font == monospaceFont
        } else {
            return false
        }
    }
}


