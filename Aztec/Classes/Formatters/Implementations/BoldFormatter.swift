import UIKit

class BoldFormatter: FontFormatter {
    static let htmlRepresentationKey = "Bold.htmlRepresentation"

    init() {
        super.init(traits: .traitBold, htmlRepresentationKey: BoldFormatter.htmlRepresentationKey)
    }
}
