import UIKit

class LinkFormatter: StandardAttributeFormatter {
    static let htmlRepresentationKey = "Link.htmlRepresentation"

    init() {
        super.init(attributeKey: NSLinkAttributeName,
                   attributeValue: NSURL(string:"")!,
                   htmlRepresentationKey: LinkFormatter.htmlRepresentationKey)
    }

    override func apply(to attributes: [String : Any], andStore representation: HTMLRepresentation?) -> [String: Any] {

        if let representation = representation,
            case let .element(element) = representation {

            let linkURL: NSURL

            if let elementUrl = element.attribute(named: HTMLLinkAttribute.Href.rawValue)?.toString() {
                linkURL = NSURL(string: elementUrl)!
            } else {
                linkURL = NSURL(string: "")!
            }

            attributeValue = linkURL
        } else {

            // There's no support fora link representation that's not an HTML element, so this
            // scenario should only be possible if `representation == nil`.
            //
            assert(representation == nil)
        }
        
        return super.apply(to: attributes, andStore: representation)
    }
}
