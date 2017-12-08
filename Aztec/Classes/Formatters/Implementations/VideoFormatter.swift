import UIKit

class VideoFormatter: StandardAttributeFormatter {

    init() {
        super.init(attributeKey: .attachment,
                   attributeValue: VideoAttachment(identifier: NSUUID().uuidString),
                   htmlRepresentationKey: .videoHtmlRepresentation)
    }

    override func apply(to attributes: [AttributedStringKey: Any], andStore representation: HTMLRepresentation?) -> [AttributedStringKey: Any] {

        if let representation = representation,
            case let .element(element) = representation.kind {

            var extraAttributes = [String:String]()

            for attribute in element.attributes {
                if let value = attribute.value.toString() {
                    extraAttributes[attribute.name] = value
                }
            }

            let srcURL: URL?

            if let urlString = element.attribute(named: "src")?.value.toString() {
                srcURL = URL(string: urlString)
            } else {
                srcURL = nil
            }

            let posterURL: URL?

            if let urlString = element.attribute(named: "poster")?.value.toString() {
                posterURL = URL(string: urlString)
            } else {
                posterURL = nil
            }

            let attachment = VideoAttachment(identifier: UUID().uuidString, srcURL: srcURL, posterURL: posterURL)

            attachment.extraAttributes = extraAttributes
            
            attributeValue = attachment
        } else {

            // There's no support fora link representation that's not an HTML element, so this
            // scenario should only be possible if `representation == nil`.
            //
            assert(representation == nil)
        }
        // Comment: Sergio Estevao (2017-10-30) - We are not passing the representation because it's all save inside the extraAttributes property of the attachment.
        return super.apply(to: attributes, andStore: nil)
    }
}
