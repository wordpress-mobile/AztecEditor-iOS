import UIKit

class UnderlineFormatter: StandardAttributeFormatter {

    init() {
        super.init(attributeKey: NSUnderlineStyleAttributeName, attributeValue: NSUnderlineStyle.styleSingle.rawValue)
    }
}
