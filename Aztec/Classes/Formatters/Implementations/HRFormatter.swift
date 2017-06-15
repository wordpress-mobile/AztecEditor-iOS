import UIKit

class HRFormatter: StandardAttributeFormatter {
    init() {
        let htmlRepresentationKey = "HR.htmlRepresentation"

        super.init(attributeKey: NSAttachmentAttributeName, attributeValue: LineAttachment(), htmlRepresentationKey: htmlRepresentationKey)
    }
}
