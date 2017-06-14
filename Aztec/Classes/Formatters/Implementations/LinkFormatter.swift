import UIKit

class LinkFormatter: StandardAttributeFormatter {
    init() {
        super.init(attributeKey: NSLinkAttributeName, attributeValue: NSURL(string:"")!)
    }
}
