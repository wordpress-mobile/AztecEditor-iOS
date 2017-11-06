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
        self.monospaceFont = monospaceFont
        self.placeholderAttributes = placeholderAttributes
    }


    // MARK: - Overwriten Methods

    func apply(to attributes: [NSAttributedStringKey: Any], andStore representation: HTMLRepresentation?) -> [NSAttributedStringKey: Any] {
        var resultingAttributes = attributes
        let newParagraphStyle = ParagraphStyle()

        newParagraphStyle.appendProperty(HTMLPre(with: representation))

        resultingAttributes[.paragraphStyle] = newParagraphStyle
        resultingAttributes[.font] = monospaceFont

        return resultingAttributes
    }

    func remove(from attributes: [NSAttributedStringKey: Any]) -> [NSAttributedStringKey: Any] {
        guard let placeholderAttributes = placeholderAttributes else {
            return attributes
        }

        var resultingAttributes = attributes
        for (key, value) in placeholderAttributes {
            resultingAttributes[key] = value
        }

        return resultingAttributes
    }

    func present(in attributes: [NSAttributedStringKey : Any]) -> Bool {
        let font = attributes[.font] as? UIFont
        return font == monospaceFont
    }
}
