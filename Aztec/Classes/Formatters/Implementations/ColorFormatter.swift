import UIKit

class ColorFormatter: StandardAttributeFormatter {
    static let htmlRepresentationKey = NSAttributedStringKey("Color.htmlRepresentation")

    init(color: UIColor = .black) {
        super.init(attributeKey: .foregroundColor,
                   attributeValue: color,
                   htmlRepresentationKey: ColorFormatter.htmlRepresentationKey)
    }
}
