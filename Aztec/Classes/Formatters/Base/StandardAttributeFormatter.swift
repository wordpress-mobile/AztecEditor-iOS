import Foundation
import UIKit

/// Formatter to apply simple value (NSNumber, UIColor) attributes to an attributed string. 
class StandardAttributeFormatter: AttributeFormatter {

    var placeholderAttributes: [String : Any]? { return nil }

    let attributeKey: String
    var attributeValue: Any

    let htmlRepresentationKey: String

    // MARK: - Init

    init(attributeKey: String, attributeValue: Any, htmlRepresentationKey: String) {
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

    func apply(to attributes: [String : Any], andStore representation: HTMLRepresentation?) -> [String: Any] {
        var resultingAttributes = attributes
        
        resultingAttributes[attributeKey] = attributeValue
        resultingAttributes[htmlRepresentationKey] = representation

        return resultingAttributes
    }

    func remove(from attributes: [String : Any]) -> [String: Any] {
        var resultingAttributes = attributes

        resultingAttributes.removeValue(forKey: attributeKey)
        resultingAttributes.removeValue(forKey: htmlRepresentationKey)

        return resultingAttributes
    }

    func present(in attributes: [String : Any]) -> Bool {
        let enabled = attributes[attributeKey] != nil
        return enabled
    }
}

