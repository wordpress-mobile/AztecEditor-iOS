import UIKit

class UnderlineFormatter: StandardAttributeFormatter {
    static let htmlRepresentationKey = "Underline.htmlRepresentation"

    init() {
        super.init(attributeKey: NSUnderlineStyleAttributeName,
                   attributeValue: NSUnderlineStyle.styleSingle.rawValue,
                   htmlRepresentationKey: UnderlineFormatter.htmlRepresentationKey)
    }
}
