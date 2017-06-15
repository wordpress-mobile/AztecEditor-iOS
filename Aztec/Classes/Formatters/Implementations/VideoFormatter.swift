import UIKit

class VideoFormatter: StandardAttributeFormatter {
    init() {
        let htmlRepresentationKey = "Video.htmlRepresentation"

        super.init(attributeKey: NSAttachmentAttributeName, attributeValue: VideoAttachment(identifier: NSUUID().uuidString, namedAttributes: [String:String](), unnamedAttributes: []), htmlRepresentationKey: htmlRepresentationKey)
    }
}
