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

                if let urlString = element.attribute(named: "src")?.value.toString() {
                    extraAttributes.removeValue(forKey: "src")
                    url = URL(string: urlString)
                } else {
                    url = nil
                }

                let attachment = ImageAttachment(identifier: UUID().uuidString, url: url)
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
