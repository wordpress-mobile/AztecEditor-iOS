import UIKit

class VideoFormatter: StandardAttributeFormatter {
    init() {
        super.init(attributeKey: NSAttachmentAttributeName, attributeValue: VideoAttachment(identifier: NSUUID().uuidString, namedAttributes: [String:String](), unnamedAttributes: []))
    }
}
