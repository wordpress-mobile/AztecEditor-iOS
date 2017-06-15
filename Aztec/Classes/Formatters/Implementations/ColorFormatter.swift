import UIKit

class ColorFormatter: StandardAttributeFormatter {
    static let htmlRepresentationKey = "Color.htmlRepresentation"

    init(color: UIColor = .black) {
        super.init(attributeKey: NSForegroundColorAttributeName,
                   attributeValue: color,
                   htmlRepresentationKey: ColorFormatter.htmlRepresentationKey)
    }
}
