import UIKit

class HRFormatter: StandardAttributeFormatter {
    static let htmlRepresentationKey = "HR.htmlRepresentation"

    init() {
        super.init(attributeKey: NSAttachmentAttributeName,
                   attributeValue: LineAttachment(),
                   htmlRepresentationKey: HRFormatter.htmlRepresentationKey)
    }
}
