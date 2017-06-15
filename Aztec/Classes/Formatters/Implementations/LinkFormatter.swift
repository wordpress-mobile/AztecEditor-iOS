import UIKit

class LinkFormatter: StandardAttributeFormatter {
    init() {
        let htmlRepresentationKey = "Link.htmlRepresentation"

        super.init(
            attributeKey: NSLinkAttributeName,
            attributeValue: NSURL(string:"")!,
            htmlRepresentationKey: htmlRepresentationKey)
    }
}
