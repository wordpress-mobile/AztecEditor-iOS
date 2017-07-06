import UIKit

class VideoFormatter: StandardAttributeFormatter {
    static let htmlRepresentationKey = "Video.htmlRepresentation"

    init() {
        super.init(attributeKey: NSAttachmentAttributeName,
                   attributeValue: VideoAttachment(identifier: NSUUID().uuidString),
                   htmlRepresentationKey: VideoFormatter.htmlRepresentationKey)
    }

    override func apply(to attributes: [String : Any], andStore representation: HTMLRepresentation?) -> [String: Any] {
        let elementRepresentation = representation as? HTMLElementRepresentation

        guard representation == nil || elementRepresentation != nil else {
            fatalError("This should not be possible.  Review the logic")
        }

        if let representation = representation {

            var namedAttributes = [String:String]()
            for attributeRepresentation in representation.attributes {
                if let value = attributeRepresentation.value {
                    namedAttributes[attributeRepresentation.name] = value
                }
            }

            let srcURL: URL?

            if let urlString = representation.valueForAttribute(named: "src") {
                srcURL = URL(string: urlString)
                namedAttributes.removeValue(forKey: "src")
            } else {
                srcURL = nil
            }

            let posterURL: URL?

            if let urlString = representation.valueForAttribute(named: "poster") {
                posterURL = URL(string: urlString)
                namedAttributes.removeValue(forKey: "poster")
            } else {
                posterURL = nil
            }

            let attachment = VideoAttachment(identifier: UUID().uuidString, srcURL: srcURL, posterURL: posterURL)

            attachment.namedAttributes = namedAttributes

            attributeValue = attachment
        }

        return super.apply(to: attributes, andStore: representation)
    }
}
