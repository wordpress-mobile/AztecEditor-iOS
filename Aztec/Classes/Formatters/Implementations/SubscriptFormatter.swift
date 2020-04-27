import UIKit

class SubscriptFormatter: StandardAttributeFormatter {

    init() {
        super.init(attributeKey: .baselineOffset,
                   attributeValue: NSNumber(-4),
                   htmlRepresentationKey: .subHtmlRepresentation)
    }

    override func apply(to attributes: [NSAttributedString.Key: Any], andStore representation: HTMLRepresentation?) -> [NSAttributedString.Key: Any] {
        var resultingAttributes = super.apply(to: attributes, andStore: representation)
        guard let currentFont = attributes[.font] as? UIFont else {
            return resultingAttributes
        }
        let font = UIFont(descriptor: currentFont.fontDescriptor, size: currentFont.pointSize - 2)
        resultingAttributes[.font] = font
        return resultingAttributes
    }

    override func remove(from attributes: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
        var resultingAttributes = super.remove(from: attributes)

        guard let currentFont = attributes[.font] as? UIFont else {
            return resultingAttributes
        }
        let font = UIFont(descriptor: currentFont.fontDescriptor, size: currentFont.pointSize + 2)
        resultingAttributes[.font] = font

        return resultingAttributes
    }
}
