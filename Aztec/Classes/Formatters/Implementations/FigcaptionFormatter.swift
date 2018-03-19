import Foundation
import UIKit


// MARK: - Figcaption Formatter
//
open class FigcaptionFormatter: ParagraphAttributeFormatter {
    var placeholderAttributes: [NSAttributedStringKey : Any]?

    /// Designated Initializer
    ///
    init(placeholderAttributes: [NSAttributedStringKey: Any]? = nil) {
        self.placeholderAttributes = placeholderAttributes
    }


    // MARK: - Overwriten Methods

    func apply(to attributes: [NSAttributedStringKey: Any], andStore representation: HTMLRepresentation?) -> [NSAttributedStringKey: Any] {
        let figcaption = Figcaption(with: representation)
        let paragraphStyle = attributes.paragraphStyle()
        
        paragraphStyle.appendProperty(figcaption)
        
        var finalAttributes = attributes
        
        finalAttributes[.paragraphStyle] = paragraphStyle
        finalAttributes[.font] = UIFont.systemFont(ofSize: 10)
        finalAttributes[.foregroundColor] = UIColor.gray
        
        return finalAttributes
    }

    func remove(from attributes: [NSAttributedStringKey: Any]) -> [NSAttributedStringKey: Any] {
        
        let paragraphStyle = attributes.paragraphStyle()
        
        guard paragraphStyle.hasProperty(where: { $0 is Figcaption }) else {
            return attributes
        }
        
        paragraphStyle.removeProperty(ofType: Figcaption.self)
        
        var finalAttributes = attributes
        
        finalAttributes[.paragraphStyle] = paragraphStyle
        finalAttributes[.font] = UIFont.systemFont(ofSize: 16)

        return finalAttributes
    }

    func present(in attributes: [NSAttributedStringKey: Any]) -> Bool {
        guard let paragraphStyle = attributes[.paragraphStyle] as? ParagraphStyle else {
            return false
        }

        return paragraphStyle.hasProperty(where: { $0 is Figcaption })
    }
}
