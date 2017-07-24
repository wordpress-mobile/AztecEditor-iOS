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
    let placeholderAttributes: [String : Any]?


    /// Designated Initializer
    ///
    init(monospaceFont: UIFont = UIFont(descriptor:UIFontDescriptor(name: "Courier", size: 12), size:12), placeholderAttributes: [String : Any]? = nil) {
        self.monospaceFont = monospaceFont
        self.placeholderAttributes = placeholderAttributes
    }


    // MARK: - Overwriten Methods

    func apply(to attributes: [String : Any], andStore representation: HTMLRepresentation?) -> [String: Any] {
        var resultingAttributes = attributes
        let newParagraphStyle = ParagraphStyle()

        newParagraphStyle.append(property: HTMLPre(with: representation))

        resultingAttributes[NSParagraphStyleAttributeName] = newParagraphStyle
        resultingAttributes[NSFontAttributeName] = monospaceFont

        return resultingAttributes
    }

    func remove(from attributes: [String: Any]) -> [String: Any] {
        guard let placeholderAttributes = placeholderAttributes else {
            return attributes
        }

        var resultingAttributes = attributes
        for (key, value) in placeholderAttributes {
            resultingAttributes[key] = value
        }

        return resultingAttributes
    }

    func present(in attributes: [String : Any]) -> Bool {
        let font = attributes[NSFontAttributeName] as? UIFont
        return font == monospaceFont
    }
}
