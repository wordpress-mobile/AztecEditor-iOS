import Foundation
import UIKit

/// Contains the logic and the style-settings to format a range of text to apply or remove the figcaption style.
/// This class creates instances of `Figcaption` objects to store information about each particular formatting
/// instance.
///
open class FigcaptionFormatter: ParagraphAttributeFormatter {
    var placeholderAttributes: [NSAttributedStringKey : Any]?

    /// Designated Initializer
    ///
    init(placeholderAttributes: [NSAttributedStringKey: Any]? = nil) {
        self.placeholderAttributes = placeholderAttributes
    }

    // MARK: - Overwriten Methods

    func apply(to attributes: [NSAttributedStringKey: Any], andStore representation: HTMLRepresentation?) -> [NSAttributedStringKey: Any] {
        
        let defaultFont = self.defaultFont(from: attributes)
        
        let figcaption = Figcaption(defaultFont: defaultFont,
                                    storing: representation)
        
        let paragraphStyle = attributes.paragraphStyle()
        paragraphStyle.appendProperty(figcaption)
        
        var finalAttributes = attributes
        
        finalAttributes[.font] = defaultFont.withSize(defaultFont.pointSize - 2)
        finalAttributes[.foregroundColor] = UIColor.gray
        finalAttributes[.paragraphStyle] = paragraphStyle
        
        return finalAttributes
    }

    func remove(from attributes: [NSAttributedStringKey: Any]) -> [NSAttributedStringKey: Any] {
        
        let paragraphStyle = attributes.paragraphStyle()
        
        guard let figcaption = paragraphStyle.property(where: { $0 is Figcaption }) as? Figcaption else {
            return attributes
        }
        
        paragraphStyle.removeProperty(ofType: Figcaption.self)
        
        var finalAttributes = attributes
        
        finalAttributes[.font] = figcaption.defaultFont
        finalAttributes.removeValue(forKey: .foregroundColor)
        finalAttributes[.paragraphStyle] = paragraphStyle

        return finalAttributes
    }

    func present(in attributes: [NSAttributedStringKey: Any]) -> Bool {
        guard let paragraphStyle = attributes[.paragraphStyle] as? ParagraphStyle else {
            return false
        }

        return paragraphStyle.hasProperty(where: { $0 is Figcaption })
    }
    
    // MARK: - Default Font
    
    private func defaultFont(from attributes: [NSAttributedStringKey:Any]) -> UIFont {
        guard let font = attributes[.font] as? UIFont else {
            return UIFont.systemFont(ofSize: 14)
        }
        
        return font
    }
}
