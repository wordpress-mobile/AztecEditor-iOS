import UIKit

class StrikethroughFormatter: StandardAttributeFormatter {
    static let htmlRepresentationKey = NSAttributedStringKey("Strike.htmlRepresentation")

    init() {
        super.init(attributeKey: .strikethroughStyle,
                   attributeValue: NSUnderlineStyle.styleSingle.rawValue,
                   htmlRepresentationKey: StrikethroughFormatter.htmlRepresentationKey)
    }
}
