import UIKit

class UnderlineFormatter: StandardAttributeFormatter {

    init() {
        super.init(attributeKey: .underlineStyle,
                   attributeValue: NSUnderlineStyle.single.rawValue,
                   htmlRepresentationKey: .underlineHtmlRepresentation)
    }
}
