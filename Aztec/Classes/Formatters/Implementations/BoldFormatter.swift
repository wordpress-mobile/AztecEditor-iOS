import UIKit

class BoldFormatter: FontFormatter {
    init() {
        super.init(traits: .traitBold, htmlRepresentationKey: .boldHtmlRepresentation)
    }
}
