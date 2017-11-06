import UIKit

class BoldFormatter: FontFormatter {
    static let htmlRepresentationKey = NSAttributedStringKey("Bold.htmlRepresentation")

    init() {
        super.init(traits: .traitBold, htmlRepresentationKey: BoldFormatter.htmlRepresentationKey)
    }
}
