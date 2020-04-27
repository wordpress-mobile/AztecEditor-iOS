import UIKit

class SuperscriptFormatter: StandardAttributeFormatter {

    init() {
        super.init(attributeKey: .baselineOffset,
                   attributeValue: NSNumber(4),
                   htmlRepresentationKey: .supHtmlRepresentation)
    }
}
