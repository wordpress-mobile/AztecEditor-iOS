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

        return apply(to: attributes, andStore: elementRepresentation)
    }

    func apply(to attributes: [String : Any], andStore representation: HTMLElementRepresentation?) -> [String: Any] {

        if let representation = representation {

            let srcURL: URL?

            if let urlString = representation.valueForAttribute(named: "src") {
                srcURL = URL(string: urlString)
            } else {
                srcURL = nil
            }

            let posterURL: URL?

            if let urlString = representation.valueForAttribute(named: "poster") {
                posterURL = URL(string: urlString)
            } else {
                posterURL = nil
            }

            let attachment = VideoAttachment(identifier: UUID().uuidString, srcURL: srcURL, posterURL: posterURL)
            
            attributeValue = attachment
        }

        return super.apply(to: attributes, andStore: representation)
    }
}
