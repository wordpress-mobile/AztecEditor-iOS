import UIKit

class UnderlineFormatter: StandardAttributeFormatter {

    init() {
        super.init(attributeKey: .underlineStyle,
                   attributeValue: NSUnderlineStyle.styleSingle.rawValue,
                   htmlRepresentationKey: .underlineHtmlRepresentation)
    }
}
