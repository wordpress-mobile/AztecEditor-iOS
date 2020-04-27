import UIKit

class SubscriptFormatter: StandardAttributeFormatter {

    init() {
        super.init(attributeKey: .baselineOffset,
                   attributeValue: NSNumber(-4),
                   htmlRepresentationKey: .subHtmlRepresentation)
    }
}
