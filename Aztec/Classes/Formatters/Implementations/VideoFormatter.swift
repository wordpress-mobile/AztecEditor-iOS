import UIKit

class VideoFormatter: StandardAttributeFormatter {
    static let htmlRepresentationKey = "Video.htmlRepresentation"

    init() {
        super.init(attributeKey: NSAttachmentAttributeName,
                   attributeValue: VideoAttachment(identifier: NSUUID().uuidString, namedAttributes: [String:String](), unnamedAttributes: []),
                   htmlRepresentationKey: VideoFormatter.htmlRepresentationKey)
    }
}
