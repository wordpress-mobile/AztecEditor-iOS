import Foundation
import UIKit

/// Formatter to apply simple value (NSNumber, UIColor) attributes to an attributed string. 
class StandardAttributeFormatter: CharacterAttributeFormatter {

    let attributedStringStorageKey: String = "FontFormatter"
    let attributeKey: String

    var attributeValue: Any

    init(attributeKey: String, attributeValue: Any) {
        self.attributeKey = attributeKey
        self.attributeValue = attributeValue
    }

    func apply(to attributes: [String : Any], andStore representation: HTMLRepresentation?) -> [String: Any] {
        var resultingAttributes = attributes
        
        resultingAttributes[attributeKey] = attributeValue

        return resultingAttributes
    }

    func remove(from attributes: [String : Any]) -> [String: Any] {
        var resultingAttributes = attributes

        resultingAttributes.removeValue(forKey: attributeKey)

        return resultingAttributes
    }

    func present(in attributes: [String : Any]) -> Bool {
        let enabled = attributes[attributeKey] != nil
        return enabled
    }
}

