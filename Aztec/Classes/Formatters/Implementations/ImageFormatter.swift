import UIKit

class ImageFormatter: StandardAttributeFormatter {
    init() {
        super.init(attributeKey: NSAttachmentAttributeName, attributeValue: ImageAttachment(identifier: NSUUID().uuidString))
    }
}
