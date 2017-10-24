import UIKit

class VideoFormatter: StandardAttributeFormatter {
    static let htmlRepresentationKey = "Video.htmlRepresentation"

    init() {
        super.init(attributeKey: NSAttachmentAttributeName,
                   attributeValue: VideoAttachment(identifier: NSUUID().uuidString),
                   htmlRepresentationKey: VideoFormatter.htmlRepresentationKey)
    }

    override func apply(to attributes: [String : Any], andStore representation: HTMLRepresentation?) -> [String: Any] {

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
                extraAttributes.removeValue(forKey: "src")
            } else {
                srcURL = nil
            }

            let posterURL: URL?

            if let urlString = element.attribute(named: "poster")?.value.toString() {
                posterURL = URL(string: urlString)
                extraAttributes.removeValue(forKey: "poster")
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

        return super.apply(to: attributes, andStore: nil)
    }
}
