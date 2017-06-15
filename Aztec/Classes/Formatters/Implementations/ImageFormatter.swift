import UIKit

class ImageFormatter: StandardAttributeFormatter {

    init() {
        let htmlRepresentationKey = "Image.htmlRepresentation"

        super.init(attributeKey: NSAttachmentAttributeName, attributeValue: ImageAttachment(identifier: NSUUID().uuidString), htmlRepresentationKey: htmlRepresentationKey)
    }
}
