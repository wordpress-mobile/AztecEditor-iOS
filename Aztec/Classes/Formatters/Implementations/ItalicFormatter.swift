import UIKit

class ItalicFormatter: FontFormatter {

    init() {
        super.init(traits: .traitItalic, htmlRepresentationKey: .italicHtmlRepresentation)
    }
}
