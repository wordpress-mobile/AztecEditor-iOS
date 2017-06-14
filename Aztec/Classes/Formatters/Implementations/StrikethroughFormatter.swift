import UIKit

class StrikethroughFormatter: StandardAttributeFormatter {

    init() {
        super.init(attributeKey: NSStrikethroughStyleAttributeName, attributeValue: NSUnderlineStyle.styleSingle.rawValue)
    }
}
