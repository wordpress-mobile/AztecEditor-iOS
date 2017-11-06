import UIKit

class UnderlineFormatter: StandardAttributeFormatter {
    static let htmlRepresentationKey = NSAttributedStringKey("Underline.htmlRepresentation")

    init() {
        super.init(attributeKey: .underlineStyle,
                   attributeValue: NSUnderlineStyle.styleSingle.rawValue,
                   htmlRepresentationKey: UnderlineFormatter.htmlRepresentationKey)
    }
}
