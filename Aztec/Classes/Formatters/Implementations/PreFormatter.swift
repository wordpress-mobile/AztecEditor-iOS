import Foundation
import UIKit


// MARK: - Pre Formatter
//
open class PreFormatter: ParagraphAttributeFormatter {

    /// Font to be used
    ///
    let monospaceFont: UIFont

    /// Attributes to be added by default
    ///
    let placeholderAttributes: [NSAttributedString.Key: Any]?


    /// Designated Initializer
    ///
    init(monospaceFont: UIFont = UIFont(descriptor:UIFontDescriptor(name: "Courier", size: 12), size:12), placeholderAttributes: [NSAttributedString.Key : Any]? = nil) {
        let font: UIFont

        if #available(iOS 11.0, *) {
            font = UIFontMetrics.default.scaledFont(for: monospaceFont)
        } else {
            font = monospaceFont
        }

        self.monospaceFont = font
        self.placeholderAttributes = placeholderAttributes
    }


    // MARK: - Overwriten Methods

    func apply(to attributes: [NSAttributedString.Key: Any], andStore representation: HTMLRepresentation?) -> [NSAttributedString.Key: Any] {
        var resultingAttributes = attributes
        let newParagraphStyle = attributes.paragraphStyle()

        newParagraphStyle.appendProperty(HTMLPre(with: representation))

        resultingAttributes[.paragraphStyle] = newParagraphStyle
        resultingAttributes[.font] = monospaceFont

        return resultingAttributes
    }

    func remove(from attributes: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
        guard let placeholderAttributes = placeholderAttributes else {
            return attributes
        }

        var resultingAttributes = attributes
        for (key, value) in placeholderAttributes {
            resultingAttributes[key] = value
        }

        return resultingAttributes
    }

    func present(in attributes: [NSAttributedString.Key : Any]) -> Bool {
        guard let paragraphStyle = attributes[.paragraphStyle] as? ParagraphStyle else {
            return false
        }

        return paragraphStyle.hasProperty(where: { (property) -> Bool in
            return property.isMember(of: HTMLPre.self)
        })
    }
}
