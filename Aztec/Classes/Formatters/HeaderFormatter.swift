import Foundation
import UIKit

class HeaderFormatter: ParagraphAttributeFormatter {

    enum HeaderType: Int {
        case none = 0
        case h1 = 1
        case h2 = 2
        case h3 = 3
        case h4 = 4
        case h5 = 5
        case h6 = 6

        var fontSize: CGFloat {
            switch self {
            case .none: return 14
            case .h1: return 36
            case .h2: return 24
            case .h3: return 21
            case .h4: return 16
            case .h5: return 14
            case .h6: return 11
            }
        }
    }

    let elementType: Libxml2.StandardElementType = .h1

    var headerLevel: HeaderType = .h1

    let placeholderAttributes: [String : Any]?

    init(headerLevel: HeaderType = .h1, placeholderAttributes: [String : Any]? = nil) {
        self.headerLevel = headerLevel
        self.placeholderAttributes = placeholderAttributes
    }

    func apply(to attributes: [String : Any]) -> [String: Any] {
        var resultingAttributes = attributes
        let newParagraphStyle = ParagraphStyle()
        if let paragraphStyle = attributes[NSParagraphStyleAttributeName] as? NSParagraphStyle {
            newParagraphStyle.setParagraphStyle(paragraphStyle)
        }
        newParagraphStyle.headerLevel = headerLevel.rawValue
        newParagraphStyle.paragraphSpacing += Metrics.defaultIndentation
        newParagraphStyle.paragraphSpacingBefore += Metrics.defaultIndentation
        resultingAttributes[NSParagraphStyleAttributeName] = newParagraphStyle

        if let font = attributes[NSFontAttributeName] as? UIFont {
            let newFont = font.withSize(headerLevel.fontSize)
            resultingAttributes[NSFontAttributeName] = newFont
        }

        return resultingAttributes
    }

    func remove(from attributes:[String: Any]) -> [String: Any] {
        var resultingAttributes = attributes
        let newParagraphStyle = ParagraphStyle()
        guard let paragraphStyle = attributes[NSParagraphStyleAttributeName] as? ParagraphStyle,
            paragraphStyle.headerLevel != 0 else {
            return resultingAttributes
        }
        newParagraphStyle.setParagraphStyle(paragraphStyle)
        
        newParagraphStyle.headerLevel = HeaderType.none.rawValue
        newParagraphStyle.paragraphSpacing -= Metrics.defaultIndentation
        newParagraphStyle.paragraphSpacingBefore -= Metrics.defaultIndentation
        resultingAttributes[NSParagraphStyleAttributeName] = newParagraphStyle

        if let font = attributes[NSFontAttributeName] as? UIFont {
            let newFont = font.withSize(HeaderType.none.fontSize)
            resultingAttributes[NSFontAttributeName] = newFont
        }

        return resultingAttributes
    }

    func present(in attributes: [String : Any]) -> Bool {
        if let paragraphStyle = attributes[NSParagraphStyleAttributeName] as? ParagraphStyle {
            return paragraphStyle.headerLevel == headerLevel.rawValue
        }
        return false
    }
}

