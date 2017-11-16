import UIKit

class StrikethroughFormatter: StandardAttributeFormatter {

    init() {
        super.init(attributeKey: .strikethroughStyle,
                   attributeValue: NSUnderlineStyle.styleSingle.rawValue,
                   htmlRepresentationKey: .strikethroughHtmlRepresentation)
    }
}
