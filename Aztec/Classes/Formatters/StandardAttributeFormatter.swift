import Foundation
import UIKit

class StandardAttributeFormatter: CharacterAttributeFormatter {

    let elementType: Libxml2.StandardElementType

    let attributeKey: String

    let attributeValue: Any

    init(elementType: Libxml2.StandardElementType, attributeKey: String, attributeValue: Any) {
        self.elementType = elementType
        self.attributeKey = attributeKey
        self.attributeValue = attributeValue
    }

    func apply(to attributes: [String : Any]) -> [String: Any] {
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

class UnderlineFormatter: StandardAttributeFormatter {

    init() {
        super.init(elementType: .u, attributeKey: NSUnderlineStyleAttributeName, attributeValue: NSUnderlineStyle.styleSingle.rawValue)
    }
}

class StrikethroughFormatter: StandardAttributeFormatter {

    init() {
        super.init(elementType: .s, attributeKey: NSStrikethroughStyleAttributeName, attributeValue: NSUnderlineStyle.styleSingle.rawValue)
    }
}

