import UIKit

class StrikethroughFormatter: StandardAttributeFormatter {

    init() {
        let htmlRepresentationKey = "Strike.htmlRepresentation"

        super.init(
            attributeKey: NSStrikethroughStyleAttributeName,
            attributeValue: NSUnderlineStyle.styleSingle.rawValue,
            htmlRepresentationKey: htmlRepresentationKey)
    }
}
