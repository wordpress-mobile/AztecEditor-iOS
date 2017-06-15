import UIKit

class BoldFormatter: FontFormatter {
    init() {
        let htmlRepresentationKey = "Bold.htmlRepresentation"
        
        super.init(traits: .traitBold, htmlRepresentationKey: htmlRepresentationKey)
    }
}
