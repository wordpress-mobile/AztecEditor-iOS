import UIKit


class HRFormatter: StandardAttributeFormatter {

    init() {
        super.init(attributeKey: .attachment,
                   attributeValue: LineAttachment(),
                   htmlRepresentationKey: .hrHtmlRepresentation)
    }
}
