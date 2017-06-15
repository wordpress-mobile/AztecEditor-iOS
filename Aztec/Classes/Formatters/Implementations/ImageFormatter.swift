import UIKit

class ImageFormatter: StandardAttributeFormatter {
    static let htmlRepresentationKey = "Image.htmlRepresentation"

    init() {
        super.init(attributeKey: NSAttachmentAttributeName,
                   attributeValue: ImageAttachment(identifier: NSUUID().uuidString),
                   htmlRepresentationKey: ImageFormatter.htmlRepresentationKey)
    }
}
