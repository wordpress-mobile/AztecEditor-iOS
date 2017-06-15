import UIKit

class StrikethroughFormatter: StandardAttributeFormatter {
    static let htmlRepresentationKey = "Strike.htmlRepresentation"

    init() {
        super.init(attributeKey: NSStrikethroughStyleAttributeName,
                   attributeValue: NSUnderlineStyle.styleSingle.rawValue,
                   htmlRepresentationKey: StrikethroughFormatter.htmlRepresentationKey)
    }
}
