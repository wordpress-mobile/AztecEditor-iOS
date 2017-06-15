import UIKit

class ColorFormatter: StandardAttributeFormatter {

    init(color: UIColor = .black) {
        let htmlRepresentationKey = "Color.htmlRepresentation"

        super.init(attributeKey: NSForegroundColorAttributeName, attributeValue: color, htmlRepresentationKey: htmlRepresentationKey)
    }
}
