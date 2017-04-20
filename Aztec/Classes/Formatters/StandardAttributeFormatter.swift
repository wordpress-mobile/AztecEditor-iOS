import Foundation
import UIKit

/// Formatter to apply simple value (NSNumber, UIColor) attributes to an attributed string. 
class StandardAttributeFormatter: CharacterAttributeFormatter {

    let attributeKey: String

    var attributeValue: Any

    init(attributeKey: String, attributeValue: Any) {
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
        super.init(attributeKey: NSUnderlineStyleAttributeName, attributeValue: NSUnderlineStyle.styleSingle.rawValue)
    }
}

class StrikethroughFormatter: StandardAttributeFormatter {

    init() {
        super.init(attributeKey: NSStrikethroughStyleAttributeName, attributeValue: NSUnderlineStyle.styleSingle.rawValue)
    }
}

class LinkFormatter: StandardAttributeFormatter {
    init() {
        super.init(attributeKey: NSLinkAttributeName, attributeValue: NSURL(string:"")!)
    }
}

class ImageFormatter: StandardAttributeFormatter {
    init() {
        super.init(attributeKey: NSAttachmentAttributeName, attributeValue: ImageAttachment(identifier: NSUUID().uuidString))
    }
}

class VideoFormatter: StandardAttributeFormatter {
    init() {
        super.init(attributeKey: NSAttachmentAttributeName, attributeValue: VideoAttachment(identifier: NSUUID().uuidString))
    }
}


class HRFormatter: StandardAttributeFormatter {
    init() {
        super.init(attributeKey: NSAttachmentAttributeName, attributeValue: LineAttachment())
    }
}

class ColorFormatter: StandardAttributeFormatter {
    init(color: UIColor = .black) {
        super.init(attributeKey: NSForegroundColorAttributeName, attributeValue: color)
    }
}

