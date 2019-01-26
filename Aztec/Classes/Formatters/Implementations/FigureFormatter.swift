import Foundation
import UIKit


// MARK: - Figure Formatter
//
open class FigureFormatter: ParagraphAttributeFormatter {

    // MARK: - Overwriten Methods

    public func apply(to attributes: [NSAttributedStringKey: Any], andStore representation: HTMLRepresentation?) -> [NSAttributedStringKey: Any] {
        let figure = Figure(with: representation)
        let paragraphStyle = attributes.paragraphStyle()
        
        paragraphStyle.appendProperty(figure)
        
        var finalAttributes = attributes
        
        finalAttributes[.paragraphStyle] = paragraphStyle
        
        return finalAttributes
    }

    public func remove(from attributes: [NSAttributedStringKey: Any]) -> [NSAttributedStringKey: Any] {
        
        guard let paragraphStyle = attributes[.paragraphStyle] as? ParagraphStyle,
            paragraphStyle.hasProperty(where: { $0 is Figure }) else {
                return attributes
        }
        
        paragraphStyle.removeProperty(ofType: Figure.self)
        
        var finalAttributes = attributes
        
        finalAttributes[.paragraphStyle] = paragraphStyle
        finalAttributes[.font] = UIFont.systemFont(ofSize: 16)

        return finalAttributes
    }

    public func present(in attributes: [NSAttributedStringKey: Any]) -> Bool {
        guard let paragraphStyle = attributes[.paragraphStyle] as? ParagraphStyle else {
            return false
        }

        return paragraphStyle.hasProperty(where: { $0 is Figure })
    }
}
