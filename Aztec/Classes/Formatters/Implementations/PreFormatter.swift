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
    let placeholderAttributes: [NSAttributedStringKey: Any]?


    /// Designated Initializer
    ///
    init(monospaceFont: UIFont = UIFont(descriptor:UIFontDescriptor(name: "Courier", size: 12), size:12), placeholderAttributes: [NSAttributedStringKey : Any]? = nil) {
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

    public func apply(to attributes: [NSAttributedStringKey: Any], andStore representation: HTMLRepresentation?) -> [NSAttributedStringKey: Any] {
        var resultingAttributes = attributes
        let newParagraphStyle = attributes.paragraphStyle()

        newParagraphStyle.appendProperty(HTMLPre(with: representation))

        resultingAttributes[.paragraphStyle] = newParagraphStyle
        resultingAttributes[.font] = monospaceFont

        return resultingAttributes
    }

    public func remove(from attributes: [NSAttributedStringKey: Any]) -> [NSAttributedStringKey: Any] {
        guard let placeholderAttributes = placeholderAttributes else {
            return attributes
        }

        var resultingAttributes = attributes
        for (key, value) in placeholderAttributes {
            resultingAttributes[key] = value
        }

        return resultingAttributes
    }

    public func present(in attributes: [NSAttributedStringKey : Any]) -> Bool {
        guard let paragraphStyle = attributes[.paragraphStyle] as? ParagraphStyle else {
            return false
        }

        return paragraphStyle.hasProperty(where: { (property) -> Bool in
            return property.isMember(of: HTMLPre.self)
        })
    }
}
