import Foundation
import UIKit


// MARK: - Pre Formatter
//
open class LiFormatter: ParagraphAttributeFormatter {

    /// Attributes to be added by default
    ///
    let placeholderAttributes: [NSAttributedString.Key: Any]?


    /// Designated Initializer
    ///
    init(placeholderAttributes: [NSAttributedString.Key : Any]? = nil) {
        self.placeholderAttributes = placeholderAttributes
    }


    // MARK: - Overwriten Methods

    func apply(to attributes: [NSAttributedString.Key: Any], andStore representation: HTMLRepresentation?) -> [NSAttributedString.Key: Any] {
        var resultingAttributes = attributes
        let newParagraphStyle = ParagraphStyle()
        if let paragraphStyle = attributes[.paragraphStyle] as? NSParagraphStyle {
            newParagraphStyle.setParagraphStyle(paragraphStyle)
        }
        
        newParagraphStyle.insertProperty(HTMLLi(with: representation), afterLastOfType: TextList.self)

        resultingAttributes[.paragraphStyle] = newParagraphStyle        

        return resultingAttributes
    }

    func remove(from attributes: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
        guard let paragraphStyle = attributes[.paragraphStyle] as? ParagraphStyle
            else {
                return attributes
        }

        let newParagraphStyle = ParagraphStyle()
        newParagraphStyle.setParagraphStyle(paragraphStyle)
        newParagraphStyle.removeProperty(ofType: HTMLLi.self)

        var resultingAttributes = attributes
        resultingAttributes[.paragraphStyle] = newParagraphStyle

        return resultingAttributes
    }

    func present(in attributes: [NSAttributedString.Key : Any]) -> Bool {
        guard let paragraphStyle = attributes[.paragraphStyle] as? ParagraphStyle
            else {
                return false
        }
        return paragraphStyle.hasProperty { (property) -> Bool in
            return property is HTMLLi
        }
    }
}
