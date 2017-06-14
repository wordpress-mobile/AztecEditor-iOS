import UIKit

class HRFormatter: StandardAttributeFormatter {
    init() {
        super.init(attributeKey: NSAttachmentAttributeName, attributeValue: LineAttachment())
    }
}
