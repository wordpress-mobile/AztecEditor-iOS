import UIKit

class ImageFormatter: StandardAttributeFormatter {
    static let htmlRepresentationKey = "Image.htmlRepresentation"

    init() {
        super.init(
            attributeKey: NSAttachmentAttributeName,
            attributeValue: ImageAttachment(identifier: NSUUID().uuidString),
            htmlRepresentationKey: ImageFormatter.htmlRepresentationKey)
    }

    override func apply(to attributes: [String : Any], andStore representation: HTMLRepresentation?) -> [String: Any] {

        if let representation = representation {
            switch(representation) {
            case .element(let element):
                let url: URL?

                if let urlString = element.stringValueForAttribute(named: "src") {
                    url = URL(string: urlString)
                } else {
                    url = nil
                }

                let attachment = ImageAttachment(identifier: UUID().uuidString, url: url)

                if let elementClass = element.stringValueForAttribute(named: "class") {
                    let classAttributes = elementClass.components(separatedBy: " ")
                    for classAttribute in classAttributes {
                        if let alignment = ImageAttachment.Alignment.fromHTML(string: classAttribute) {
                            attachment.alignment = alignment
                        }
                        if let size = ImageAttachment.Size.fromHTML(string: classAttribute) {
                            attachment.size = size
                        }
                    }
                }

                attributeValue = attachment
            default:
                attributeValue = ImageAttachment(identifier: UUID().uuidString)
            }
        }

        return super.apply(to: attributes, andStore: representation)
    }
}
