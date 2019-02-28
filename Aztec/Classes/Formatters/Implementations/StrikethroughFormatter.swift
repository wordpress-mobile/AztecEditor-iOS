import UIKit

class StrikethroughFormatter: StandardAttributeFormatter {

    init() {
        super.init(attributeKey: .strikethroughStyle,
                   attributeValue: NSUnderlineStyle.single.rawValue,
                   htmlRepresentationKey: .strikethroughHtmlRepresentation)
    }
}
