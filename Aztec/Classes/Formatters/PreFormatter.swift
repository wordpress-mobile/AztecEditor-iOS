import Foundation
import UIKit

open class PreFormatter: ParagraphAttributeFormatter {

    let monospaceFont: UIFont
    let placeholderAttributes: [String : Any]?

    init(monospaceFont: UIFont = UIFont(descriptor:UIFontDescriptor(name: "Courier", size: 12), size:12) ,placeholderAttributes: [String : Any]? = nil) {
        self.monospaceFont = monospaceFont
        self.placeholderAttributes = placeholderAttributes
    }

    func apply(to attributes: [String : Any]) -> [String: Any] {
        var resultingAttributes = attributes
        let newParagraphStyle = ParagraphStyle()

        resultingAttributes[NSParagraphStyleAttributeName] = newParagraphStyle
        resultingAttributes[NSFontAttributeName] = monospaceFont

        return resultingAttributes
    }

    func remove(from attributes:[String: Any]) -> [String: Any] {
        var resultingAttributes = attributes
        let newParagraphStyle = ParagraphStyle()

        resultingAttributes[NSParagraphStyleAttributeName] = newParagraphStyle
        resultingAttributes[NSFontAttributeName] = monospaceFont

        return resultingAttributes
    }

    func present(in attributes: [String : Any]) -> Bool {
        if let font = attributes[NSFontAttributeName] as? UIFont {
            return font == monospaceFont
        }
        return false
    }
}

