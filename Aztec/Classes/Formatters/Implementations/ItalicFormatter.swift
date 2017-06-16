import UIKit

class ItalicFormatter: FontFormatter {
    static let htmlRepresentationKey = "Italic.htmlRepresentation"

    init() {
        super.init(traits: .traitItalic, htmlRepresentationKey: ItalicFormatter.htmlRepresentationKey)
    }
}
