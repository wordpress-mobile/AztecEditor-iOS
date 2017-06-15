import UIKit

class LinkFormatter: StandardAttributeFormatter {
    static let htmlRepresentationKey = "Link.htmlRepresentation"

    init() {
        super.init(attributeKey: NSLinkAttributeName,
                   attributeValue: NSURL(string:"")!,
                   htmlRepresentationKey: LinkFormatter.htmlRepresentationKey)
    }
}
