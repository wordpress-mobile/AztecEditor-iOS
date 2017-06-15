import UIKit

class ItalicFormatter: FontFormatter {

    init() {
        let htmlRepresentationKey = "Italic.htmlRepresentation"
        
        super.init(traits: .traitItalic, htmlRepresentationKey: htmlRepresentationKey)
    }
}
