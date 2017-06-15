import UIKit

class LinkFormatter: StandardAttributeFormatter {
    static let htmlRepresentationKey = "Link.htmlRepresentation"

    init() {
        super.init(attributeKey: NSLinkAttributeName,
                   attributeValue: NSURL(string:"")!,
                   htmlRepresentationKey: LinkFormatter.htmlRepresentationKey)
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
            let linkURL: URL

            if let attributeIndex = representation.attributes.index(where: { $0.name == HTMLLinkAttribute.Href.rawValue }),
                let attributeValue = representation.attributes[attributeIndex].value {

                linkURL = URL(string: attributeValue)!
            } else {
                // We got a link tag without an HREF attribute
                //
                linkURL = URL(string: "")!
            }

            attributeValue = linkURL
        }
        
        return super.apply(to: attributes, andStore: representation)
    }
}
