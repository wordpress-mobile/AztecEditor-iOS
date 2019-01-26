import UIKit

open class BoldFormatter: FontFormatter {
    init() {
        super.init(traits: .traitBold, htmlRepresentationKey: .boldHtmlRepresentation)
    }
}
