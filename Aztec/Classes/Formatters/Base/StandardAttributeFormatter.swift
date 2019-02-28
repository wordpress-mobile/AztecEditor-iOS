import Foundation
import UIKit

/// Formatter to apply simple value (NSNumber, UIColor) attributes to an attributed string. 
class StandardAttributeFormatter: AttributeFormatter {

    var placeholderAttributes: [NSAttributedString.Key: Any]? { return nil }

    let attributeKey: NSAttributedString.Key
    var attributeValue: Any

    let htmlRepresentationKey: NSAttributedString.Key

    // MARK: - Init

    init(attributeKey: NSAttributedString.Key, attributeValue: Any, htmlRepresentationKey: NSAttributedString.Key) {
        self.attributeKey = attributeKey
        self.attributeValue = attributeValue
        self.htmlRepresentationKey = htmlRepresentationKey
    }

    func applicationRange(for range: NSRange, in text: NSAttributedString) -> NSRange {
        return range
    }

    func apply(to attributes: [NSAttributedString.Key: Any], andStore representation: HTMLRepresentation?) -> [NSAttributedString.Key: Any] {
        var resultingAttributes = attributes
        
        resultingAttributes[attributeKey] = attributeValue
        resultingAttributes[htmlRepresentationKey] = representation

        return resultingAttributes
    }

    func remove(from attributes: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
        var resultingAttributes = attributes

        resultingAttributes.removeValue(forKey: attributeKey)
        resultingAttributes.removeValue(forKey: htmlRepresentationKey)

        return resultingAttributes
    }

    func present(in attributes: [NSAttributedString.Key: Any]) -> Bool {
        let enabled = attributes[attributeKey] != nil
        return enabled
    }
}

