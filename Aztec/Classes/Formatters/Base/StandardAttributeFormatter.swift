import Foundation
import UIKit

/// Formatter to apply simple value (NSNumber, UIColor) attributes to an attributed string. 
class StandardAttributeFormatter: AttributeFormatter {

    var placeholderAttributes: [NSAttributedStringKey: Any]? { return nil }

    let attributeKey: NSAttributedStringKey
    var attributeValue: Any

    let htmlRepresentationKey: NSAttributedStringKey

    // MARK: - Init

    init(attributeKey: NSAttributedStringKey, attributeValue: Any, htmlRepresentationKey: NSAttributedStringKey) {
        self.attributeKey = attributeKey
        self.attributeValue = attributeValue
        self.htmlRepresentationKey = htmlRepresentationKey
    }

    func applicationRange(for range: NSRange, in text: NSAttributedString) -> NSRange {
        return range
    }

    func worksInEmptyRange() -> Bool {
        return false
    }

    func apply(to attributes: [NSAttributedStringKey: Any], andStore representation: HTMLRepresentation?) -> [NSAttributedStringKey: Any] {
        var resultingAttributes = attributes
        
        resultingAttributes[attributeKey] = attributeValue
        resultingAttributes[htmlRepresentationKey] = representation

        return resultingAttributes
    }

    func remove(from attributes: [NSAttributedStringKey: Any]) -> [NSAttributedStringKey: Any] {
        var resultingAttributes = attributes

        resultingAttributes.removeValue(forKey: attributeKey)
        resultingAttributes.removeValue(forKey: htmlRepresentationKey)

        return resultingAttributes
    }

    func present(in attributes: [NSAttributedStringKey: Any]) -> Bool {
        let enabled = attributes[attributeKey] != nil
        return enabled
    }
}

