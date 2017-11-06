import UIKit

class ColorFormatter: StandardAttributeFormatter {

    init(color: UIColor = .black) {
        super.init(attributeKey: .foregroundColor,
                   attributeValue: color,
                   htmlRepresentationKey: .colorHtmlRepresentation)
    }
}
