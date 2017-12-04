import UIKit

class ImageFormatter: StandardAttributeFormatter {

    init() {
        super.init(
            attributeKey: .attachment,
            attributeValue: ImageAttachment(identifier: NSUUID().uuidString),
            htmlRepresentationKey: .imageHtmlRepresentation)
    }

    override func apply(to attributes: [AttributedStringKey: Any], andStore representation: HTMLRepresentation?) -> [AttributedStringKey: Any] {

        if let representation = representation {
            switch representation.kind {
            case .element(let element):
                var extraAttributes = [String:String]()
                for attribute in element.attributes {
                    if let value = attribute.value.toString() {
                        extraAttributes[attribute.name] = value
                    }
                }

                let url: URL?

                if let srcString = element.attribute(named: "src")?.value.toString() {
                    url = URL(string: srcString)
                } else {
                    url = nil
                }

                let attachment = ImageAttachment(identifier: UUID().uuidString, src: url)
                attachment.extraAttributes = extraAttributes
                attributeValue = attachment
            default:
                attributeValue = ImageAttachment(identifier: UUID().uuidString)
            }
        }
        // Comment: Sergio Estevao (2017-10-30) - We are not passing the representation because it's all save inside the extraAttributes property of the attachment.
        return super.apply(to: attributes, andStore: nil)
    }
}
