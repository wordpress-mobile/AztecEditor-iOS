import UIKit

class UnderlineFormatter: StandardAttributeFormatter {

    init() {
        let htmlRepresentationKey = "Underline.htmlRepresentation"

        super.init(
            attributeKey: NSUnderlineStyleAttributeName,
            attributeValue: NSUnderlineStyle.styleSingle.rawValue,
            htmlRepresentationKey: htmlRepresentationKey)
    }
}
