import UIKit

class HRFormatter: StandardAttributeFormatter {
    static let htmlRepresentationKey = NSAttributedStringKey("HR.htmlRepresentation")

    init() {
        super.init(attributeKey: .attachment,
                   attributeValue: LineAttachment(),
                   htmlRepresentationKey: HRFormatter.htmlRepresentationKey)
    }
}
