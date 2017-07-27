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
            case let .element(element) = representation.kind {

            if let elementURL = element.attribute(named: HTMLLinkAttribute.Href.rawValue)?.value.toString() {
               if let url = NSURL(string: elementURL) {
                   attributeValue = url
               } else {
                   attributeValue = elementURL
               }
            } else {
                attributeValue = NSURL(string: "")!
            }            
        } else {

            // There's no support fora link representation that's not an HTML element, so this
            // scenario should only be possible if `representation == nil`.
            //
            assert(representation == nil)
        }
        
        return super.apply(to: attributes, andStore: representation)
    }
}
