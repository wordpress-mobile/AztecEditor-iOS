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
            case let .element(element) = representation {

            var namedAttributes = [String:String]()

            for attribute in element.attributes {
                if let value = attribute.value.toString() {
                    namedAttributes[attribute.name] = value
                }
            }

            let srcURL: URL?

            if let urlString = element.stringValueForAttribute(named: "src") {
                srcURL = URL(string: urlString)
                namedAttributes.removeValue(forKey: "src")
            } else {
                srcURL = nil
            }

            let posterURL: URL?

            if let urlString = element.stringValueForAttribute(named: "poster") {
                posterURL = URL(string: urlString)
                namedAttributes.removeValue(forKey: "poster")
            } else {
                posterURL = nil
            }

            let attachment = VideoAttachment(identifier: UUID().uuidString, srcURL: srcURL, posterURL: posterURL)

            attachment.namedAttributes = namedAttributes
            
            attributeValue = attachment
        } else {

            // There's no support fora link representation that's not an HTML element, so this
            // scenario should only be possible if `representation == nil`.
            //
            assert(representation == nil)
        }

        return super.apply(to: attributes, andStore: representation)
    }
}
