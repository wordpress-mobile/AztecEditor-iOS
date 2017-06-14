import UIKit

class ColorFormatter: StandardAttributeFormatter {
    init(color: UIColor = .black) {
        super.init(attributeKey: NSForegroundColorAttributeName, attributeValue: color)
    }
}
